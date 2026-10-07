package com.husseinabozina.taskmanagement

import android.os.Bundle
import android.content.Intent
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import com.husseinabozina.taskmanagement.ui.TaskApp
import com.husseinabozina.taskmanagement.ui.TaskAppViewModel
import com.husseinabozina.taskmanagement.ui.theme.TaskManagementTheme
import com.husseinabozina.taskmanagement.reminders.ReminderScheduler
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private lateinit var model: TaskAppViewModel
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        model = ViewModelProvider(this)[TaskAppViewModel::class.java]
        importDemoIfRequested(intent)
        openReminderIfRequested(intent)
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                while (true) {
                    model.refreshDay()
                    delay(60_000)
                }
            }
        }
        setContent { TaskManagementTheme { TaskApp(model) } }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        importDemoIfRequested(intent)
        openReminderIfRequested(intent)
    }

    override fun onResume() {
        super.onResume()
        if (::model.isInitialized) model.refreshReminders()
    }

    private fun openReminderIfRequested(intent: Intent) {
        intent.getStringExtra(ReminderScheduler.TASK_ID)?.let {
            intent.removeExtra(ReminderScheduler.TASK_ID)
            model.openNotificationTask(it)
        }
    }

    private fun importDemoIfRequested(intent: Intent) {
        if (intent.getBooleanExtra("tmPopulateDemo", false)) {
            intent.removeExtra("tmPopulateDemo")
            model.importPresentationData()
        }
    }
}
