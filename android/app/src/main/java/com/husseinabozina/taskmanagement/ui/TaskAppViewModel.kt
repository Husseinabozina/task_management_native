package com.husseinabozina.taskmanagement.ui

import android.app.Application
import android.content.pm.ApplicationInfo
import android.util.Log
import androidx.core.content.edit
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.husseinabozina.taskmanagement.data.AppDatabase
import com.husseinabozina.taskmanagement.data.PresentationDemoData
import com.husseinabozina.taskmanagement.data.LocalTaskRepository
import com.husseinabozina.taskmanagement.reminders.ReminderScheduler
import com.husseinabozina.taskmanagement.cloud.CloudController
import com.husseinabozina.taskmanagement.domain.*
import java.time.LocalDate
import java.time.Instant
import java.util.UUID
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

/** Room is the only source of task/project updates; drafts live in their editors. */
data class AppSnapshot(
    val tasks: List<TaskItem> = emptyList(),
    val projects: List<ProjectItem> = emptyList(),
    val today: LocalDate = LocalDate.now(),
    val loading: Boolean = true,
    val error: String? = null
) {
    fun project(id: UUID?) = projects.firstOrNull { it.id == id }
    fun projectTasks(id: UUID) = tasks.filter { it.projectId == id }
    fun progress(id: UUID): Float {
        val items = projectTasks(id)
        return if (items.isEmpty()) 0f else items.count { it.status == TaskStatus.COMPLETED }.toFloat() / items.size
    }
}

@OptIn(ExperimentalCoroutinesApi::class)
class TaskAppViewModel(application: Application) : AndroidViewModel(application) {
    val cloud = CloudController(application, viewModelScope)
    private val repository = LocalTaskRepository(AppDatabase.get(application))
    private val preferences = application.getSharedPreferences("presentation", 0)
    private val reload = MutableStateFlow(0)
    private val today = MutableStateFlow(LocalDate.now())
    val onboarding = MutableStateFlow(!preferences.getBoolean("onboardingCompleted", false))
    val actionError = MutableStateFlow<String?>(null)
    val notificationTask = MutableStateFlow<UUID?>(null)
    private val pending = mutableSetOf<UUID>()
    private var lastSnapshot = AppSnapshot()
    private var importingDemo = false

    val snapshot: StateFlow<AppSnapshot> = reload.flatMapLatest {
        combine(repository.observeTasks(TaskQuery()), repository.observeProjects(), today) { tasks, projects, day ->
            AppSnapshot(
                tasks = tasks.sortedWith(compareBy<TaskItem> { !it.isPinned }
                    .thenBy { it.dayBucket(CalendarDay(day)) }.thenBy { it.priority.sortRank }
                    .thenBy { it.dueDay?.date ?: LocalDate.MAX }.thenBy { it.id }),
                projects = projects, today = day, loading = false
            ).also { lastSnapshot = it }
        }.onStart {
            emit(lastSnapshot.copy(loading = true, error = null))
        }.catch { failure ->
            if (failure is CancellationException) throw failure
            emit(lastSnapshot.copy(today = today.value, loading = false,
                error = "تعذّر تحميل البيانات. أعد المحاولة؛ بياناتك محفوظة."))
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), AppSnapshot())

    fun importPresentationData() {
        if (getApplication<Application>().applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0 || importingDemo) return
        importingDemo = true
        viewModelScope.launch {
            try {
                val result = PresentationDemoData.insertMissing(AppDatabase.get(getApplication()))
                Log.i("MahamiDemo", "Imported projects=${result.projectsAdded} tasks=${result.tasksAdded}")
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                actionError.value = "تعذّر إضافة بيانات العرض. أعد المحاولة؛ بياناتك الحالية لم تتغير."
                Log.e("MahamiDemo", "Presentation import failed; transaction rolled back")
            } finally { importingDemo = false }
        }
    }

    fun retry() { reload.value += 1 }
    fun refreshDay() { today.value = LocalDate.now() }
    fun completeOnboarding() {
        preferences.edit { putBoolean("onboardingCompleted", true) }
        onboarding.value = false
    }
    fun replayOnboarding() { onboarding.value = true }
    fun clearActionError() { actionError.value = null }
    fun openNotificationTask(raw: String) {
        notificationTask.value = runCatching { UUID.fromString(raw) }.getOrNull()
    }
    fun consumeNotificationTask() { notificationTask.value = null }
    fun refreshReminders() {
        viewModelScope.launch {
            try { ReminderScheduler.reconcile(getApplication()) }
            catch (cancelled: CancellationException) { throw cancelled }
            catch (_: Exception) { actionError.value = "تعذّر تحديث التذكيرات. بياناتك محفوظة؛ أعد فتح التطبيق للمحاولة." }
        }
    }

    fun toggle(task: TaskItem) {
        if (!pending.add(task.id)) return
        viewModelScope.launch {
            try {
                actionError.value = perform {
                    repository.setCompleted(task.id, task.status != TaskStatus.COMPLETED)
                }
            } finally { pending.remove(task.id) }
        }
    }

    suspend fun saveTask(id: UUID?, input: NewTask): String? = perform {
        if (input.reminderDate != null && input.status != TaskStatus.COMPLETED) {
            if (!ReminderScheduler.notificationsAllowed(getApplication())) {
                throw RepositoryError.ValidationFailed("اسمح بإشعارات المهام أو ألغِ التذكير قبل الحفظ.")
            }
            val previous = lastSnapshot.tasks.firstOrNull { it.id == id }?.reminderDate
            if (input.reminderDate != previous && !input.reminderDate.isAfter(Instant.now())) {
                throw RepositoryError.ValidationFailed("اختر موعدًا قادمًا للتذكير.")
            }
        }
        if (id == null) repository.create(input)
        else repository.update(id, input.title, input.details, input.priority, input.status,
            input.isPinned, input.dueDay, input.projectId, input.reminderDate)
        // Persistence succeeded: report scheduling separately, so retry cannot create a duplicate task.
        try { ReminderScheduler.reconcile(getApplication()) }
        catch (cancelled: CancellationException) { throw cancelled }
        catch (_: Exception) { actionError.value = "حُفظت المهمة، لكن تعذّر تحديث التذكيرات. أعد فتح التطبيق للمحاولة." }
    }
    suspend fun quickAdd(title: String, date: LocalDate?, projectId: UUID?): String? =
        saveTask(null, NewTask(title = title, dueDay = date?.let(::CalendarDay), projectId = projectId))
    suspend fun deleteTask(id: UUID): String? = perform { repository.deleteTask(id) }
    suspend fun saveProject(input: NewProject, onCreated: (ProjectItem) -> Unit = {}): String? = perform {
        onCreated(repository.createProject(input))
    }
    suspend fun deleteProject(id: UUID): String? = perform { repository.deleteProject(id) }

    private suspend fun perform(action: suspend () -> Any?): String? = try {
        action()
        null
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (failure: RepositoryError) {
        failure.message ?: "تعذّر حفظ التغيير. أعد المحاولة."
    } catch (_: Exception) {
        "تعذّر حفظ التغيير. أعد المحاولة؛ لم تُفقد بياناتك."
    }
}
