package com.husseinabozina.taskmanagement

import android.app.Application
import android.util.Log
import com.husseinabozina.taskmanagement.data.AppDatabase
import com.husseinabozina.taskmanagement.reminders.ReminderScheduler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.retryWhen
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class TaskManagementApplication : Application() {
    private val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onCreate() {
        super.onCreate()
        ReminderScheduler.createChannel(this)
        applicationScope.launch {
            AppDatabase.get(this@TaskManagementApplication).taskDao().observeAll()
                .retryWhen { _, attempt -> delay((attempt.coerceAtMost(4) + 1) * 1_000); true }
                .collect {
                    try { ReminderScheduler.reconcile(this@TaskManagementApplication) }
                    catch (cancelled: CancellationException) { throw cancelled }
                    catch (_: Exception) { Log.e("MahamiReminders", "Scheduling failed; will reconcile on next change or launch") }
                }
        }
    }
}
