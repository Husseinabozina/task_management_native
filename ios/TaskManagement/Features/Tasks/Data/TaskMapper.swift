import Foundation

/// تحويل بين نماذج التخزين وكيانات الدومين — mapping واحد، لا يسرّب صفوف للواجهة.
enum TaskMapper {
  static func toDomain(_ row: PersistedTask) -> TaskItem {
    TaskItem(
      id: row.id,
      title: row.title,
      details: row.details,
      status: TaskStatus(rawValue: row.statusRaw) ?? .active,
      priority: TaskPriority(rawValue: row.priorityRaw) ?? .normal,
      isPinned: row.isPinned,
      dueDay: row.dueDayDate.flatMap { CalendarDay(date: $0) },
      projectId: row.projectId,
      reminderDate: row.reminderDate,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      completedAt: row.completedAt
    )
  }

  static func apply(_ input: NewTask, to row: PersistedTask, updatedAt: Date) {
    row.title = input.title
    row.details = input.details
    row.statusRaw = input.status.rawValue
    row.priorityRaw = input.priority.rawValue
    row.isPinned = input.isPinned
    row.reminderDate = input.reminderDate
    row.dueDayDate = input.dueDay?.date
    row.projectId = input.projectId
    row.updatedAt = updatedAt
  }

  static func toDomain(_ row: PersistedProject) -> ProjectItem {
    ProjectItem(
      id: row.id,
      name: row.name,
      emoji: row.emoji,
      colorKey: row.colorKey,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt
    )
  }
}
