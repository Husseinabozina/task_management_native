import Foundation
import Observation

/// حالة الرئيسية — مهام اليوم للتقدم + كل المهام للمتأخرات وإحصاءات المشاريع.
@Observable
@MainActor
final class HomeViewModel {
  private(set) var todayTasks: [TaskItem] = []
  private(set) var allTasks: [TaskItem] = []
  private(set) var projects: [ProjectItem] = []

  private let repository: LocalDataRepository
  private var observationTasks: [Task<Void, Never>] = []

  init(repository: LocalDataRepository) {
    self.repository = repository
    observe()
  }

  var completedToday: Int {
    todayTasks.filter { $0.status == .completed }.count
  }

  var totalToday: Int {
    todayTasks.count
  }

  var progress: Double {
    guard totalToday > 0 else { return 0 }
    return Double(completedToday) / Double(totalToday)
  }

  /// عدد المتأخرات (مفتوحة وموعد فات) — للنقطة على جرس الإشعارات.
  var overdueCount: Int {
    let today = CalendarDay.today()
    return allTasks.filter { $0.dayBucket(today: today) == .overdue }.count
  }

  /// المهام المفتوحة لليوم (مفتوحة أو شغالة عليها) — لقسم «مهام النهارده».
  var activeTodayTasks: [TaskItem] {
    todayTasks.filter { $0.status != .completed }
  }

  /// أهم مشروعين نشاطًا (عدد المفتوحة ثم نسبة الإنجاز) — للكارتين البارزين.
  var featuredProjects: [ProjectItem] {
    projects
      .sorted { a, b in
        let aActive = activeCount(projectId: a.id)
        let bActive = activeCount(projectId: b.id)
        if aActive != bActive { return aActive > bActive }
        return progress(projectId: a.id) > progress(projectId: b.id)
      }
      .prefix(2)
      .map { $0 }
  }

  func activeCount(projectId: UUID) -> Int {
    allTasks.filter { $0.projectId == projectId && $0.status != .completed }.count
  }

  func progress(projectId: UUID) -> Double {
    let projectTasks = allTasks.filter { $0.projectId == projectId }
    guard !projectTasks.isEmpty else { return 0 }
    let done = projectTasks.filter { $0.status == .completed }.count
    return Double(done) / Double(projectTasks.count)
  }

  func project(for id: UUID?) -> ProjectItem? {
    guard let id else { return nil }
    return projects.first { $0.id == id }
  }

  /// الإتمام/الإعادة من الرئيسية — غير المكتملة تتمم والمكتملة تُعاد (العقد D20).
  func toggleCompletion(of item: TaskItem) async -> String? {
    do {
      _ = try repository.setCompleted(id: item.id, item.status != .completed)
      return nil
    } catch let error as RepositoryError {
      return error.readableDescription
    } catch {
      return "حصلت مشكلة غير متوقعة أثناء الحفظ."
    }
  }

  private func observe() {
    observationTasks.append(
      Task { [weak self] in
        guard let stream = self?.repository.observeTasks(TaskQuery(day: .day(CalendarDay.today())))
        else { return }
        for await items in stream {
          guard let self, !Task.isCancelled else { break }
          self.todayTasks = items
        }
      })
    observationTasks.append(
      Task { [weak self] in
        guard let stream = self?.repository.observeTasks(TaskQuery()) else { return }
        for await items in stream {
          guard let self, !Task.isCancelled else { break }
          self.allTasks = items
        }
      })
    observationTasks.append(
      Task { [weak self] in
        guard let stream = self?.repository.observeProjects() else { return }
        for await items in stream {
          guard let self, !Task.isCancelled else { break }
          self.projects = items
        }
      })
  }
}
