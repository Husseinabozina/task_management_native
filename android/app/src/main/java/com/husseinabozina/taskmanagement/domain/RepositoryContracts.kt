package com.husseinabozina.taskmanagement.domain

import kotlinx.coroutines.flow.Flow

/**
 * عقود المخزن — نفس عقود iOS (docs/architecture/DATA_CONTRACTS.md).
 * تحديث القوائم بالمراقبة (قرار D6): Flow يعيد snapshot ثم تحديثًا بعد كل mutation.
 * تنفيذ واحد حقيقي محلي الآن (Room)؛ السحابة لاحقًا تنفيذ جديد لنفس العقود (D2).
 */
interface TaskRepository {
    fun observeTasks(query: TaskQuery): Flow<List<TaskItem>>
    suspend fun create(input: NewTask): TaskItem
    suspend fun update(
        id: UUID,
        title: String,
        details: String?,
        priority: TaskPriority,
        status: TaskStatus,
        isPinned: Boolean,
        dueDay: CalendarDay?,
        projectId: UUID?,
        reminderDate: Instant?
    ): TaskItem
    /** الإتمام وcompletedAt يتغيران معًا في عملية حفظ واحدة (العقد). */
    suspend fun setCompleted(id: UUID, completed: Boolean): TaskItem
    /** التثبيت/إلغاؤه — يغيّر الترتيب دون مساس بالحالة (قرار D21). */
    suspend fun setPinned(id: UUID, pinned: Boolean): TaskItem
    suspend fun deleteTask(id: UUID)
}

interface ProjectRepository {
    fun observeProjects(): Flow<List<ProjectItem>>
    suspend fun createProject(input: NewProject): ProjectItem
    suspend fun updateProject(id: UUID, name: String, emoji: String?, colorKey: String?): ProjectItem
    /** حذف المشروع ينقل مهامه إلى «بدون مشروع» ولا يحذفها (العقد). */
    suspend fun deleteProject(id: UUID)
}

/** أخطاء المخزن — رسائل عربية مفهومة (نفس iOS). */
sealed class RepositoryError(message: String) : Exception(message) {
    class ValidationFailed(val reason: String) : RepositoryError(reason)
    data object NotFound : RepositoryError("العنصر ده مش موجود.")
    class StoreFailure(cause: String) : RepositoryError("حصلت مشكلة في الحفظ: $cause")
}
