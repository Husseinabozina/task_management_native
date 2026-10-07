import Foundation
import Observation

/// حالة شاشة مهامي — تملك الفلتر وتراقب المخزن (قرار D6).
@Observable
@MainActor
final class TasksViewModel {
  private(set) var tasks: [TaskItem] = []
  private(set) var isLoading = true
  /// البحث الفوري بالعنوان — فلتر عرض فوق نتيجة الاستعلام (FEATURE_SCOPE: بحث case-insensitive).
  var searchText = "" {
    didSet { applySearch() }
  }
  var query = TaskQuery() {
    didSet {
      guard query != oldValue else { return }
      startObservation()
    }
  }

  private let repository: TaskRepository
  private var observationTask: Task<Void, Never>?

  init(repository: TaskRepository, query: TaskQuery = TaskQuery()) {
    self.repository = repository
    self.query = query
    startObservation()
  }

  func selectDay(_ day: TaskQuery.DayFilter) {
    var next = query
    next.day = day
    query = next
  }

  func selectStatus(_ status: TaskQuery.StatusFilter) {
    var next = query
    next.status = status
    query = next
  }

  func selectPriority(_ priority: TaskQuery.PriorityFilter) {
    var next = query
    next.priority = priority
    query = next
  }

  /// نتائج العرض بعد البحث — matching case-insensitive على العنوان.
  var visibleTasks: [TaskItem] {
    let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !term.isEmpty else { return tasks }
    return tasks.filter { $0.title.localizedCaseInsensitiveContains(term) }
  }

  private func applySearch() {}

  /// الإضافة السريعة: تعيد رسالة خطأ إن فشلت، ولا تفقد النص عند الفشل (العقد).
  func addQuickTask(rawTitle: String) async -> String? {
    let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty else { return "العنوان مطلوب." }
    guard title.count <= 200 else { return "العنوان أطول من الحد المسموح (200 حرف)." }
    let dueDay: CalendarDay?
    if case .day(let day) = query.day { dueDay = day } else { dueDay = nil }
    do {
      _ = try repository.create(
        NewTask(title: title, details: nil, priority: .normal, dueDay: dueDay, projectId: nil))
      return nil
    } catch let error as RepositoryError {
      return error.readableDescription
    } catch {
      return "حدثت مشكلة غير متوقعة أثناء الحفظ."
    }
  }

  /// الضغط على الـ pill: غير المكتملة تتمم (أيا كانت حالتها)، والمكتملة تُعاد مفتوحة (العقد D20).
  func toggleCompletion(of item: TaskItem) async -> String? {
    do {
      _ = try repository.setCompleted(id: item.id, item.status != .completed)
      return nil
    } catch let error as RepositoryError {
      return error.readableDescription
    } catch {
      return "حدثت مشكلة غير متوقعة أثناء الحفظ."
    }
  }

  private func startObservation() {
    isLoading = tasks.isEmpty
    let activeQuery = query
    observationTask?.cancel()
    observationTask = Task { [weak self] in
      guard let stream = self?.repository.observeTasks(activeQuery) else { return }
      for await items in stream {
        guard let self, !Task.isCancelled else { break }
        self.tasks = items
        self.isLoading = false
      }
    }
  }
}
