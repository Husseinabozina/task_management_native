import Foundation
import Observation
import Supabase

/// Optional manual sync. The server and local apply each commit a complete snapshot atomically.
@Observable
@MainActor
final class CloudSyncService {
  private(set) var isSyncing = false
  private(set) var lastSyncAt: Date?
  private(set) var lastError: String?
  private let client: SupabaseClient
  private let repository: LocalDataRepository

  init(client: SupabaseClient, repository: LocalDataRepository) {
    self.client = client
    self.repository = repository
  }

  func syncNow() async {
    guard !isSyncing else { return }
    isSyncing = true
    defer { isSyncing = false }
    do {
      let userId = try await client.auth.session.user.id
      let binding = UserDefaults.standard.string(forKey: "cloudBoundUserId")
      guard binding == nil || binding == userId.uuidString else {
        lastError = "بيانات هذا الجهاز مرتبطة بحساب آخر. سجّل الدخول بالحساب السابق؛ مهامك محفوظة."
        return
      }
      let local = try repository.exportForSync()
      let payload = CloudSyncPayload(
        p_projects: local.projects.map { CloudProjectRow(from: $0, ownerId: userId) },
        p_tasks: local.tasks.map { CloudTaskRow(from: $0, ownerId: userId) },
        p_deleted_projects: local.projectTombstones, p_deleted_tasks: local.taskTombstones)
      try backupOnce(payload, userId: userId)
      UserDefaults.standard.set(userId.uuidString, forKey: "cloudBoundUserId")
      let snapshot: CloudSnapshot = try await client.rpc("sync_personal", params: payload).execute().value
      try repository.applyCloudSnapshot(snapshot, ownerId: userId)
      lastSyncAt = Date()
      lastError = nil
    } catch {
      lastError = "تعذّر إتمام المزامنة. مهامك المحلية محفوظة؛ تحقّق من الاتصال والحساب ثم أعد المحاولة."
    }
  }

  /// Back up a consistent data export, never an incomplete copy of a live SQLite/WAL store.
  private func backupOnce(_ payload: CloudSyncPayload, userId: UUID) throws {
    let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Backups", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let destination = directory.appendingPathComponent("pre-sync-\(userId.uuidString).json")
    if FileManager.default.fileExists(atPath: destination.path),
      let size = try FileManager.default.attributesOfItem(atPath: destination.path)[.size] as? NSNumber,
      size.intValue > 0 { return }
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    try encoder.encode(payload).write(to: destination, options: [.atomic, .completeFileProtectionUnlessOpen])
  }
}

struct CloudSyncPayload: Encodable {
  let p_projects: [CloudProjectRow]
  let p_tasks: [CloudTaskRow]
  let p_deleted_projects: [LocalDataRepository.SyncDeletion]
  let p_deleted_tasks: [LocalDataRepository.SyncDeletion]
}

struct CloudSnapshot: Decodable {
  let projects: [CloudProjectRow]
  let tasks: [CloudTaskRow]
}

struct CloudProjectRow: Codable {
  let id: UUID
  let owner_id: UUID
  let name: String
  let emoji: String?
  let color_key: String?
  let created_at: Date
  let updated_at: Date
  var deleted_at: Date?

  init(from item: ProjectItem, ownerId: UUID) {
    id = item.id
    owner_id = ownerId
    name = item.name
    emoji = item.emoji
    color_key = item.colorKey
    created_at = item.createdAt
    updated_at = item.updatedAt
    deleted_at = nil
  }
}

struct CloudTaskRow: Codable {
  let id: UUID
  let owner_id: UUID
  let title: String
  let details: String?
  let status: String
  let priority: String
  let is_pinned: Bool
  let due_day: String?
  let project_id: UUID?
  let reminder_date: Date?
  let completed_at: Date?
  let created_at: Date
  let updated_at: Date
  var deleted_at: Date?

  init(from item: TaskItem, ownerId: UUID) {
    id = item.id
    owner_id = ownerId
    title = item.title
    details = item.details
    status = item.status.rawValue
    priority = item.priority.rawValue
    is_pinned = item.isPinned
    due_day = item.dueDay.map { Self.dayFormatter().string(from: $0.date) }
    project_id = item.projectId
    reminder_date = item.reminderDate
    completed_at = item.completedAt
    created_at = item.createdAt
    updated_at = item.updatedAt
    deleted_at = nil
  }

  func taskItem() throws -> TaskItem {
    guard let taskStatus = TaskStatus(rawValue: status), let taskPriority = TaskPriority(rawValue: priority) else {
      throw RepositoryError.storeFailure("Invalid cloud task values")
    }
    var day: CalendarDay?
    if let due_day {
      let formatter = Self.dayFormatter()
      guard let date = formatter.date(from: due_day), formatter.string(from: date) == due_day,
        let parsed = CalendarDay(date: date) else { throw RepositoryError.storeFailure("Invalid cloud calendar day") }
      day = parsed
    }
    return TaskItem(id: id, title: title, details: details, status: taskStatus, priority: taskPriority,
      isPinned: is_pinned, dueDay: day, projectId: project_id, reminderDate: reminder_date,
      createdAt: created_at, updatedAt: updated_at, completedAt: completed_at)
  }

  private static func dayFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.isLenient = false
    return formatter
  }
}
