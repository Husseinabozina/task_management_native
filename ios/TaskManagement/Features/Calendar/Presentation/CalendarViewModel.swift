import Foundation
import Observation

/// حالة شاشة التقويم — عرض شهري للمهام (روح Notion: database calendar view).
@Observable
@MainActor
final class CalendarViewModel {
  private(set) var tasks: [TaskItem] = []

  private let repository: TaskRepository
  private var observationTask: Task<Void, Never>?

  init(repository: TaskRepository) {
    self.repository = repository
    observationTask = Task { [weak self] in
      guard let stream = self?.repository.observeTasks(TaskQuery()) else { return }
      for await items in stream {
        guard let self, !Task.isCancelled else { break }
        self.tasks = items
      }
    }
  }

  /// عدد المهام غير المكتملة في يوم معين داخل الشهر المعروض (مفتوحة + شغالة عليها).
  func activeCount(on day: CalendarDay) -> Int {
    tasks.filter { $0.dueDay == day && $0.status != .completed }.count
  }

  /// كل مهام يوم معين (مفتوحة ومكتملة) — للعرض التفصيلي.
  func tasks(on day: CalendarDay) -> [TaskItem] {
    tasks.filter { $0.dueDay == day }
  }
}
