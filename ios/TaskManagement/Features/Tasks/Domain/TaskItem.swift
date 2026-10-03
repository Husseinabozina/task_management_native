import Foundation

/// حالة المهمة — عقد V1 حالتان فقط (قرار D11).
enum TaskStatus: String, Codable, Hashable {
  case active
  case completed
}

/// الأولوية — تُخزن كقيمة لا كنص واجهة مترجم.
enum TaskPriority: String, Codable, Hashable, CaseIterable, Comparable {
  case low
  case normal
  case high

  private var rank: Int {
    switch self {
    case .high: return 0
    case .normal: return 1
    case .low: return 2
    }
  }

  static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
    lhs.rank < rhs.rank
  }
}

/// مهمة المنتج — كيان دومين مستقل عن التخزين والواجهة.
struct TaskItem: Identifiable, Hashable {
  let id: UUID
  var title: String
  /// وصف المهمة (حقل description في العقد — تجنب تعارض التسمية في Swift).
  var details: String?
  var status: TaskStatus
  var priority: TaskPriority
  var dueDay: CalendarDay?
  var projectId: UUID?
  let createdAt: Date
  var updatedAt: Date
  var completedAt: Date?
}

/// مدخل إنشاء مهمة — العنوان مطلوب بعد trim ويُتحقق منه في المخزن.
struct NewTask: Hashable {
  var title: String
  var details: String?
  var priority: TaskPriority = .normal
  var dueDay: CalendarDay?
  var projectId: UUID?
}

/// فلتر القائمة — مطابق لعقد observeTasks (يوم + حالة + مشروع اختياري).
struct TaskQuery: Hashable {
  enum DayFilter: Hashable {
    /// «الكل» — يجمع المتأخرة/اليوم/القادمة/بلا موعد.
    case all
    case day(CalendarDay)
  }

  enum StatusFilter: Hashable {
    case any
    case active
    case completed
  }

  var day: DayFilter = .all
  var status: StatusFilter = .any
  var projectId: UUID?
}

/// تصنيف اليوم وفق العقد — قاعدة واحدة في مكان واحد.
enum TaskDayBucket: Hashable, Comparable {
  case overdue
  case today
  case upcoming
  case noDueDate
  /// المكتملة تظهر آخر القائمة في «الكل» (تغطية إضافة موثقة في العقد).
  case completed

  private var order: Int {
    switch self {
    case .overdue: return 0
    case .today: return 1
    case .upcoming: return 2
    case .noDueDate: return 3
    case .completed: return 4
    }
  }

  static func < (lhs: TaskDayBucket, rhs: TaskDayBucket) -> Bool {
    lhs.order < rhs.order
  }
}

extension TaskItem {
  /// التصنيف يعتمد على الحالة: المكتملة لا تصير متأخرة أبدًا (العقد).
  func dayBucket(today: CalendarDay) -> TaskDayBucket {
    guard let dueDay else { return status == .completed ? .completed : .noDueDate }
    guard status == .active else { return .completed }
    switch dueDay.relation(to: today) {
    case .past: return .overdue
    case .sameDay: return .today
    case .future: return .upcoming
    }
  }
}
