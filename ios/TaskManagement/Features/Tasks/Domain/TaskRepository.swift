import Foundation

/// عقود المخزن — تنفيذ واحد حقيقي محلي الآن (SwiftData)، والسحابة لاحقًا تُضاف
/// كتنفيذ جديد لنفس العقود دون مساس بالواجهة (قرار D2).
///
/// تحديث القوائم بالمراقبة (قرار D6): كل stream يعيد snapshot فوري ثم تحديثًا بعد
/// كل mutation ناجح — لا refresh يدوي موازٍ.
@MainActor
protocol TaskRepository {
  func observeTasks(_ query: TaskQuery) -> AsyncStream<[TaskItem]>
  func create(_ input: NewTask) throws -> TaskItem
  /// تغيير الحالة وcompletedAt يحدثان معًا في عملية حفظ واحدة (العقد).
  func update(
    id: UUID,
    title: String,
    details: String?,
    priority: TaskPriority,
    status: TaskStatus,
    isPinned: Bool,
    dueDay: CalendarDay?,
    projectId: UUID?,
    reminderDate: Date?
  ) throws -> TaskItem
  /// الإتمام وcompletedAt يتغيران معًا في عملية حفظ واحدة (العقد).
  func setCompleted(id: UUID, _ completed: Bool) throws -> TaskItem
  /// التثبيت/إلغاؤه — يغيّر الترتيب في القوائم دون مساس بالحالة (قرار D21).
  func setPinned(id: UUID, _ pinned: Bool) throws -> TaskItem
  func deleteTask(id: UUID) throws
}

@MainActor
protocol ProjectRepository {
  func observeProjects() -> AsyncStream<[ProjectItem]>
  func createProject(_ input: NewProject) throws -> ProjectItem
  func updateProject(id: UUID, name: String, emoji: String?, colorKey: String?) throws
    -> ProjectItem
  /// حذف المشروع ينقل مهامه إلى «بدون مشروع» ولا يحذفها (العقد).
  func deleteProject(id: UUID) throws
}
