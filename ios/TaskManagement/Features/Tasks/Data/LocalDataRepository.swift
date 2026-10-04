import Foundation
import SwiftData

/// التنفيذ المحلي الحقيقي لعقود المهام والمشاريع (SwiftData).
/// كل mutation يُحفظ ثم يُبلّغ الـ streams — فشل الكتابة يرد failure ولا يظهر نجاحًا وهميًا.
@MainActor
final class LocalDataRepository: TaskRepository, ProjectRepository {
  private let container: ModelContainer
  private var taskStreams:
    [UUID: (query: TaskQuery, continuation: AsyncStream<[TaskItem]>.Continuation)] = [:]
  private var projectStreams: [UUID: AsyncStream<[ProjectItem]>.Continuation] = [:]

  init(container: ModelContainer) {
    self.container = container
  }

  // MARK: - TaskRepository

  func observeTasks(_ query: TaskQuery) -> AsyncStream<[TaskItem]> {
    let streamId = UUID()
    return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
      continuation.onTermination = { [weak self] _ in
        Task { @MainActor [weak self] in self?.taskStreams[streamId] = nil }
      }
      taskStreams[streamId] = (query, continuation)
      continuation.yield(fetchTasks(query))
    }
  }

  func create(_ input: NewTask) throws -> TaskItem {
    let row = try validatedRow(for: input)
    container.mainContext.insert(row)
    try save()
    let item = TaskMapper.toDomain(row)
    notifyChanged()
    return item
  }

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
  ) throws -> TaskItem {
    let row = try fetchTaskRow(id: id)
    try validate(title: title, details: details)
    row.title = title
    row.details = details
    row.priorityRaw = priority.rawValue
    // تغيير الحالة وcompletedAt في نفس العملية (العقد): الدخول للإتمام يسجل الوقت، والخروج منه يمحوه.
    row.statusRaw = status.rawValue
    if status == .completed {
      if row.completedAt == nil { row.completedAt = Date() }
    } else {
      row.completedAt = nil
    }
    row.isPinned = isPinned
    row.reminderDate = reminderDate
    row.dueDayDate = dueDay?.date
    row.projectId = projectId
    row.updatedAt = Date()
    try save()
    let item = TaskMapper.toDomain(row)
    notifyChanged()
    return item
  }

  func setCompleted(id: UUID, _ completed: Bool) throws -> TaskItem {
    let row = try fetchTaskRow(id: id)
    row.statusRaw = completed ? TaskStatus.completed.rawValue : TaskStatus.active.rawValue
    row.completedAt = completed ? Date() : nil
    row.updatedAt = Date()
    try save()
    let item = TaskMapper.toDomain(row)
    notifyChanged()
    return item
  }

  func setPinned(id: UUID, _ pinned: Bool) throws -> TaskItem {
    let row = try fetchTaskRow(id: id)
    row.isPinned = pinned
    row.updatedAt = Date()
    try save()
    let item = TaskMapper.toDomain(row)
    notifyChanged()
    return item
  }

  func deleteTask(id: UUID) throws {
    let row = try fetchTaskRow(id: id)
    container.mainContext.delete(row)
    try save()
    notifyChanged()
  }

  // MARK: - ProjectRepository

  func observeProjects() -> AsyncStream<[ProjectItem]> {
    let streamId = UUID()
    return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
      continuation.onTermination = { [weak self] _ in
        Task { @MainActor [weak self] in self?.projectStreams[streamId] = nil }
      }
      projectStreams[streamId] = continuation
      continuation.yield(fetchProjects())
    }
  }

  func createProject(_ input: NewProject) throws -> ProjectItem {
    let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty, name.count <= Limits.projectName else {
      throw RepositoryError.validationFailed("اسم المشروع مطلوب (حتى \(Limits.projectName) حرف).")
    }
    let row = PersistedProject(
      id: UUID(),
      name: name,
      emoji: input.emoji,
      colorKey: input.colorKey,
      createdAt: Date()
    )
    container.mainContext.insert(row)
    try save()
    let item = TaskMapper.toDomain(row)
    notifyChanged()
    return item
  }

  func updateProject(id: UUID, name: String, emoji: String?, colorKey: String?) throws
    -> ProjectItem
  {
    guard let row = try fetchProjectRow(id: id) else { throw RepositoryError.notFound }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed.count <= Limits.projectName else {
      throw RepositoryError.validationFailed("اسم المشروع مطلوب (حتى \(Limits.projectName) حرف).")
    }
    row.name = trimmed
    row.emoji = emoji
    row.colorKey = colorKey
    try save()
    let item = TaskMapper.toDomain(row)
    notifyChanged()
    return item
  }

  func deleteProject(id: UUID) throws {
    guard let row = try fetchProjectRow(id: id) else { throw RepositoryError.notFound }
    // مهام المشروع تنتقل إلى «بدون مشروع» في نفس عملية الحفظ (العقد).
    let descriptor = FetchDescriptor<PersistedTask>(predicate: #Predicate { $0.projectId == id })
    for task in try container.mainContext.fetch(descriptor) {
      task.projectId = nil
      task.updatedAt = Date()
    }
    container.mainContext.delete(row)
    try save()
    notifyChanged()
  }

  // MARK: - الجلب والترتيب

  /// V1: البيانات محلية وصغيرة — الفلترة والترتيب في الذاكرة بقاعدة واحدة (العقد).
  /// عند تضخم البيانات ينتقل الفلتر إلى الاستعلام دون تغيير شكل العقد.
  private func fetchTasks(_ query: TaskQuery) -> [TaskItem] {
    let descriptor = FetchDescriptor<PersistedTask>()
    let rows = (try? container.mainContext.fetch(descriptor)) ?? []
    let today = CalendarDay.today()
    return
      rows
      .map(TaskMapper.toDomain)
      .filter { item in
        if let projectId = query.projectId, item.projectId != projectId { return false }
        switch query.status {
        case .any: break
        case .active: if item.status != .active { return false }
        case .inProgress: if item.status != .inProgress { return false }
        case .completed: if item.status != .completed { return false }
        }
        if case .day(let day) = query.day {
          guard let dueDay = item.dueDay, dueDay == day else { return false }
        }
        return true
      }
      .sorted { lhs, rhs in
        // المثبتة أولًا داخل كل قائمة (قرار D21)، ثم التصنيف اليومي.
        if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
        let leftBucket = lhs.dayBucket(today: today)
        let rightBucket = rhs.dayBucket(today: today)
        if leftBucket != rightBucket { return leftBucket < rightBucket }
        if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
        let leftDay = lhs.dueDay?.date ?? .distantFuture
        let rightDay = rhs.dueDay?.date ?? .distantFuture
        if leftDay != rightDay { return leftDay < rightDay }
        return lhs.id.uuidString < rhs.id.uuidString
      }
  }

  private func fetchProjects() -> [ProjectItem] {
    let descriptor = FetchDescriptor<PersistedProject>(sortBy: [SortDescriptor(\.createdAt)])
    let rows = (try? container.mainContext.fetch(descriptor)) ?? []
    return rows.map(TaskMapper.toDomain)
  }

  // MARK: - أدوات داخلية

  private enum Limits {
    static let taskTitle = 200
    static let taskDetails = 5_000
    static let projectName = 80
  }

  private func validatedRow(for input: NewTask) throws -> PersistedTask {
    try validate(title: input.title, details: input.details)
    return PersistedTask(
      id: UUID(),
      title: input.title.trimmingCharacters(in: .whitespacesAndNewlines),
      details: input.details,
      statusRaw: input.status.rawValue,
      priorityRaw: input.priority.rawValue,
      isPinned: input.isPinned,
      dueDayDate: input.dueDay?.date,
      projectId: input.projectId,
      createdAt: Date(),
      updatedAt: Date(),
      completedAt: nil,
      reminderDate: input.reminderDate
    )
  }

  private func validate(title: String, details: String?) throws {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed.count <= Limits.taskTitle else {
      throw RepositoryError.validationFailed("العنوان مطلوب (حتى \(Limits.taskTitle) حرف).")
    }
    if let details, details.count > Limits.taskDetails {
      throw RepositoryError.validationFailed(
        "الوصف أطول من الحد المسموح (\(Limits.taskDetails) حرف).")
    }
  }

  private func fetchTaskRow(id: UUID) throws -> PersistedTask {
    let descriptor = FetchDescriptor<PersistedTask>(predicate: #Predicate { $0.id == id })
    guard let row = try container.mainContext.fetch(descriptor).first else {
      throw RepositoryError.notFound
    }
    return row
  }

  private func fetchProjectRow(id: UUID) throws -> PersistedProject? {
    let descriptor = FetchDescriptor<PersistedProject>(predicate: #Predicate { $0.id == id })
    return try container.mainContext.fetch(descriptor).first
  }

  private func save() throws {
    do {
      try container.mainContext.save()
    } catch {
      throw RepositoryError.storeFailure(error.localizedDescription)
    }
  }

  /// إعادة جلب وإرسال snapshot لكل stream حسب استعلامه بعد كل mutation.
  private func notifyChanged() {
    for (query, continuation) in taskStreams.values {
      continuation.yield(fetchTasks(query))
    }
    for continuation in projectStreams.values {
      continuation.yield(fetchProjects())
    }
  }
}
