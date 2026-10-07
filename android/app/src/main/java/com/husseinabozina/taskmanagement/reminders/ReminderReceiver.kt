package com.husseinabozina.taskmanagement.reminders

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.husseinabozina.taskmanagement.MainActivity
import com.husseinabozina.taskmanagement.R
import com.husseinabozina.taskmanagement.data.AppDatabase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.UUID

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                ReminderScheduler.createChannel(context)
                if (intent.action == "com.husseinabozina.taskmanagement.REMIND") {
                    deliver(context, intent)
                } else {
                    ReminderScheduler.reconcile(context)
                }
            } catch (_: Exception) {
                Log.e("MahamiReminders", "Reminder operation failed; durable task data is unchanged")
            } finally { pending.finish() }
        }
    }

    private suspend fun deliver(context: Context, intent: Intent) {
        val id = runCatching { UUID.fromString(intent.getStringExtra(ReminderScheduler.TASK_ID)) }.getOrNull() ?: return
        val row = AppDatabase.get(context).taskDao().byId(id) ?: return
        val time = intent.getLongExtra(ReminderScheduler.REMINDER_TIME, -1)
        if (row.statusRaw == "completed" || row.reminderDate?.toEpochMilli() != time ||
            !ReminderScheduler.notificationsAllowed(context)) return
        if (time > System.currentTimeMillis() + 1_000) return
        val open = Intent(context, MainActivity::class.java)
            .setAction("com.husseinabozina.taskmanagement.OPEN_TASK")
            .setData(android.net.Uri.parse("mahami://task/$id"))
            .putExtra(ReminderScheduler.TASK_ID, id.toString())
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val contentIntent = PendingIntent.getActivity(context, 0, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(context, ReminderScheduler.CHANNEL)
            .setSmallIcon(R.drawable.ic_notification_check)
            .setContentTitle("تذكير بمهمة")
            .setContentText(row.title)
            .setStyle(NotificationCompat.BigTextStyle().bigText(row.title))
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(contentIntent).setAutoCancel(true).build()
        try {
            NotificationManagerCompat.from(context).notify(id.toString(), 0, notification)
            Log.i("MahamiReminders", "Reminder delivered")
        } catch (_: SecurityException) {
            Log.w("MahamiReminders", "Notification permission changed before delivery")
        }
    }
}
