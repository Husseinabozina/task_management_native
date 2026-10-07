package com.husseinabozina.taskmanagement.reminders

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.husseinabozina.taskmanagement.data.AppDatabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.time.Instant
import java.util.UUID

/** Reconcile durable task data with OS alarms; screen lifetime never owns an alarm. */
object ReminderScheduler {
    const val CHANNEL = "task_reminders"
    const val TASK_ID = "reminderTaskId"
    const val REMINDER_TIME = "reminderTime"
    private val mutex = Mutex()

    fun createChannel(context: Context) {
        val channel = NotificationChannel(CHANNEL, "تذكيرات المهام", NotificationManager.IMPORTANCE_HIGH)
        channel.description = "إشعارات مواعيد المهام التي تختارها"
        channel.lockscreenVisibility = android.app.Notification.VISIBILITY_PRIVATE
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    fun notificationsAllowed(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return false
        return context.getSystemService(NotificationManager::class.java)
            .getNotificationChannel(CHANNEL)?.importance != NotificationManager.IMPORTANCE_NONE
    }

    fun exactAllowed(context: Context): Boolean = Build.VERSION.SDK_INT < 31 ||
        context.getSystemService(AlarmManager::class.java).canScheduleExactAlarms()

    suspend fun reconcile(context: Context) = withContext(Dispatchers.IO) { mutex.withLock {
        val rows = AppDatabase.get(context).taskDao().observeAll().first()
        val preferences = context.getSharedPreferences("scheduled_reminders", 0)
        val previous = preferences.getStringSet("ids", emptySet()).orEmpty().toSet()
        val now = Instant.now()
        val enabled = notificationsAllowed(context)
        val desired = rows.filter { enabled && it.statusRaw != "completed" &&
            it.reminderDate?.isAfter(now) == true }.associateBy { it.id.toString() }
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val notifications = NotificationManagerCompat.from(context)
        for (id in previous - desired.keys) {
            alarmManager.cancel(alarmIntent(context, UUID.fromString(id), 0))
            // Keep already delivered reminders until the task is completed/deleted/disabled.
            val row = rows.firstOrNull { it.id.toString() == id }
            if (row == null || row.statusRaw == "completed" || row.reminderDate == null || !enabled) {
                notifications.cancel(id, 0)
            }
        }
        // Also remove delivered notifications for tasks no longer eligible.
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.activeNotifications.filter { it.notification.channelId == CHANNEL }.forEach { notification ->
            val row = rows.firstOrNull { it.id.toString() == notification.tag }
            if (row == null || row.statusRaw == "completed" || row.reminderDate == null || !enabled) {
                manager.cancel(notification.tag, notification.id)
            }
        }
        for (row in desired.values) {
            val target = requireNotNull(row.reminderDate).toEpochMilli()
            val pending = alarmIntent(context, row.id, target)
            if (exactAllowed(context)) {
                try {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, target, pending)
                } catch (_: SecurityException) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, target, pending)
                }
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, target, pending)
            }
        }
        check(preferences.edit().putStringSet("ids", desired.keys.toSet()).commit()) {
            "Unable to persist reminder reconciliation metadata"
        }
    } }

    private fun alarmIntent(context: Context, id: UUID, time: Long): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java)
            .setAction("com.husseinabozina.taskmanagement.REMIND")
            .setData(Uri.parse("mahami://reminder/$id"))
            .putExtra(TASK_ID, id.toString()).putExtra(REMINDER_TIME, time)
        return PendingIntent.getBroadcast(context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }
}
