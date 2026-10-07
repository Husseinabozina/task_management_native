package com.husseinabozina.taskmanagement.data

import com.husseinabozina.taskmanagement.domain.CalendarDay
import com.husseinabozina.taskmanagement.domain.NewProject
import com.husseinabozina.taskmanagement.domain.NewTask
import com.husseinabozina.taskmanagement.domain.ProjectItem
import com.husseinabozina.taskmanagement.domain.ProjectRepository
import com.husseinabozina.taskmanagement.domain.RepositoryError
import com.husseinabozina.taskmanagement.domain.TaskItem
import com.husseinabozina.taskmanagement.domain.TaskPriority
import com.husseinabozina.taskmanagement.domain.TaskQuery
import com.husseinabozina.taskmanagement.domain.TaskRepository
import com.husseinabozina.taskmanagement.domain.TaskStatus
import androidx.room.withTransaction
import java.time.Instant
import java.util.UUID
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

/**
 * التنفيذ المحلي الحقيقي لعقود المهام والمشاريع (Room) — مرآة LocalDataRepository في iOS.
 * كل mutation يُحفظ ثم يُبلّغ الـ Flows — فشل الكتابة يرد failure ولا يظهر نجاحًا وهميًا.
 */
class LocalTaskRepository(
    private val database: AppDatabase
) : TaskRepository, ProjectRepository {
    private val taskDao = database.taskDao()
    private val projectDao = database.projectDao()
    private val tombstoneDao = database.tombstoneDao()

    override fun observeTasks(query: TaskQuery): Flow<List<TaskItem>> =
        taskDao.observeAll().map { rows ->
            val today = CalendarDay.today()
            rows.map(::toDomain)
                .filter { item ->
                    if (query.projectId != null && item.projectId != query.projectId) return@filter false
                    when (query.status) {
                        com.husseinabozina.taskmanagement.domain.StatusFilter.ANY -> {}
                        com.husseinabozina.taskmanagement.domain.StatusFilter.ACTIVE ->
                            if (item.status != TaskStatus.ACTIVE) return@filter false
                        com.husseinabozina.taskmanagement.domain.StatusFilter.IN_PROGRESS ->
                            if (item.status != TaskStatus.IN_PROGRESS) return@filter false
                        com.husseinabozina.taskmanagement.domain.StatusFilter.COMPLETED ->
                            if (item.status != TaskStatus.COMPLETED) return@filter false
                    }
                    when (query.priority) {
                        com.husseinabozina.taskmanagement.domain.PriorityFilter.ANY -> {}
                        com.husseinabozina.taskmanagement.domain.PriorityFilter.LOW ->
                            if (item.priority != TaskPriority.LOW) return@filter false
                        com.husseinabozina.taskmanagement.domain.PriorityFilter.NORMAL ->
                            if (item.priority != TaskPriority.NORMAL) return@filter false
                        com.husseinabozina.taskmanagement.domain.PriorityFilter.HIGH ->
                            if (item.priority != TaskPriority.HIGH) return@filter false
                    }
                    if (query.day == com.husseinabozina.taskmanagement.domain.DayFilter.DAY) {
                        val due = item.dueDay ?: return@filter false
                        if (due != query.queryDay) return@filter false
                    }
                    true
                }
                .sortedWith(
                    compareBy<TaskItem> { it.isPinned.not() }
                        .thenBy { it.dayBucket(today) }
                        .thenBy { it.priority.sortRank }
                        .thenBy { it.dueDay?.date ?: java.time.LocalDate.MAX }
                        .thenBy { it.id }
                )
        }

    override suspend fun create(input: NewTask): TaskItem = database.withTransaction {
        val title = input.title.trim()
        validate(title, input.details)
        requireProject(input.projectId)
        val now = Instant.now()
        val entity = TaskEntity(
            id = UUID.randomUUID(),
            title = title,
            details = input.details,
            statusRaw = input.status.raw,
            priorityRaw = input.priority.raw,
            isPinned = input.isPinned,
            dueDay = input.dueDay?.date,
            projectId = input.projectId,
            reminderDate = input.reminderDate,
            createdAt = now,
            updatedAt = now,
            completedAt = if (input.status == TaskStatus.COMPLETED) now else null
        )
        taskDao.upsert(entity)
        toDomain(entity)
    }

    override suspend fun update(
        id: UUID,
        title: String,
        details: String?,
        priority: TaskPriority,
        status: TaskStatus,
        isPinned: Boolean,
        dueDay: CalendarDay?,
        projectId: UUID?,
        reminderDate: Instant?
    ): TaskItem = database.withTransaction {
        val row = taskDao.byId(id) ?: throw RepositoryError.NotFound
        validate(title, details)
        requireProject(projectId)
        val now = Instant.now()
        val updated = row.copy(
            title = title.trim(), details = details?.trim()?.takeIf { it.isNotEmpty() },
            priorityRaw = priority.raw, statusRaw = status.raw, isPinned = isPinned,
            dueDay = dueDay?.date, projectId = projectId, reminderDate = reminderDate,
            updatedAt = now,
            completedAt = if (status == TaskStatus.COMPLETED) row.completedAt ?: now else null
        )
        taskDao.upsert(updated)
        toDomain(updated)
    }

    override suspend fun setCompleted(id: UUID, completed: Boolean): TaskItem = database.withTransaction {
        val row = taskDao.byId(id) ?: throw RepositoryError.NotFound
        val now = Instant.now()
        val updated = row.copy(
            statusRaw = if (completed) TaskStatus.COMPLETED.raw else TaskStatus.ACTIVE.raw,
            completedAt = if (completed) row.completedAt ?: now else null,
            updatedAt = now
        )
        taskDao.upsert(updated)
        toDomain(updated)
    }

    override suspend fun setPinned(id: UUID, pinned: Boolean): TaskItem = database.withTransaction {
        val row = taskDao.byId(id) ?: throw RepositoryError.NotFound
        val updated = row.copy(isPinned = pinned, updatedAt = Instant.now())
        taskDao.upsert(updated)
        toDomain(updated)
    }

    override suspend fun deleteTask(id: UUID): Unit = database.withTransaction {
        if (taskDao.byId(id) == null) throw RepositoryError.NotFound
        taskDao.deleteById(id)
        tombstoneDao.upsert(
            TombstoneEntity(kind = "task", rowId = id, deletedAt = Instant.now(), key = "task:$id")
        )
    }

    override fun observeProjects(): Flow<List<ProjectItem>> =
        projectDao.observeAll().map { rows -> rows.map(::toDomain) }

    override suspend fun createProject(input: NewProject): ProjectItem = database.withTransaction {
        val name = input.name.trim()
        if (name.isEmpty() || name.length > PROJECT_NAME_LIMIT) {
            throw RepositoryError.ValidationFailed("اسم المشروع مطلوب (حتى $PROJECT_NAME_LIMIT حرف).")
        }
        val now = Instant.now()
        val entity = ProjectEntity(
            id = UUID.randomUUID(), name = name, emoji = input.emoji,
            colorKey = input.colorKey, createdAt = now, updatedAt = now
        )
        projectDao.upsert(entity)
        toDomain(entity)
    }

    override suspend fun updateProject(
        id: UUID, name: String, emoji: String?, colorKey: String?
    ): ProjectItem = database.withTransaction {
        val row = projectDao.byId(id) ?: throw RepositoryError.NotFound
        val trimmed = name.trim()
        if (trimmed.isEmpty() || trimmed.length > PROJECT_NAME_LIMIT) {
            throw RepositoryError.ValidationFailed("اسم المشروع مطلوب (حتى $PROJECT_NAME_LIMIT حرف).")
        }
        val updated = row.copy(
            name = trimmed, emoji = emoji, colorKey = colorKey, updatedAt = Instant.now()
        )
        projectDao.upsert(updated)
        toDomain(updated)
    }

    override suspend fun deleteProject(id: UUID): Unit = database.withTransaction {
        if (projectDao.byId(id) == null) throw RepositoryError.NotFound
        val now = Instant.now()
        taskDao.detachProject(id, now)
        projectDao.deleteById(id)
        tombstoneDao.upsert(
            TombstoneEntity(kind = "project", rowId = id, deletedAt = now, key = "project:$id")
        )
    }

    // MARK: - أدوات داخلية

    private suspend fun requireProject(id: UUID?) {
        if (id != null && projectDao.byId(id) == null) {
            throw RepositoryError.ValidationFailed("المشروع المحدد غير موجود. اختر مشروعًا آخر.")
        }
    }

    private fun validate(title: String, details: String?) {
        val trimmed = title.trim()
        if (trimmed.isEmpty() || trimmed.length > TITLE_LIMIT) {
            throw RepositoryError.ValidationFailed("العنوان مطلوب (حتى $TITLE_LIMIT حرف).")
        }
        if (details != null && details.length > DETAILS_LIMIT) {
            throw RepositoryError.ValidationFailed("الوصف أطول من الحد المسموح ($DETAILS_LIMIT حرف).")
        }
    }

    private fun toDomain(row: TaskEntity): TaskItem = TaskItem(
        id = row.id,
        title = row.title,
        details = row.details,
        status = TaskStatus.from(row.statusRaw),
        priority = TaskPriority.from(row.priorityRaw),
        isPinned = row.isPinned,
        dueDay = row.dueDay?.let { CalendarDay(it) },
        projectId = row.projectId,
        reminderDate = row.reminderDate,
        createdAt = row.createdAt,
        updatedAt = row.updatedAt,
        completedAt = row.completedAt
    )

    private fun toDomain(row: ProjectEntity): ProjectItem = ProjectItem(
        id = row.id,
        name = row.name,
        emoji = row.emoji,
        colorKey = row.colorKey,
        createdAt = row.createdAt,
        updatedAt = row.updatedAt
    )

    private companion object {
        const val TITLE_LIMIT = 200
        const val DETAILS_LIMIT = 5_000
        const val PROJECT_NAME_LIMIT = 80
    }
}
