import Foundation
import Observation
import Supabase

/// مزامنة C1 — full snapshot باتجاهين بقاعدة LWW (الأحدث updated_at يفوز)
/// مع tombstones للحذف، ونسخة احتياطية إلزامية قبل أول مزامنة (بروتوكول الهجرة في CLOUD_PLAN §6).
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
      try await backupStoreOnce(for: userId)
      try await push(userId: userId)
      try await pull(userId: userId)
      lastSyncAt = Date()
      lastError = nil
    } catch {
      lastError = "فشلت المزامنة: \(error.localizedDescription)"
    }
  }

  /// نسخة احتياطية إلزامية مرة واحدة لكل مستخدم قبل أول مزامنة (لا مسح محلي أبدًا).
  private func backupStoreOnce(for userId: UUID) async throws {
    let key = "cloudBackupDone-\(userId.uuidString)"
    guard !UserDefaults.standard.bool(forKey: key) else { return }
    let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[
      0]
    let backups = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Backups", isDirectory: true)
    try FileManager.default.createDirectory(at: backups, withIntermediateDirectories: true)
    let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
    for suffix in ["", "-shm", "-wal"] {
      let source = support.appendingPathComponent("default.store\(suffix)")
      if FileManager.default.fileExists(atPath: source.path) {
        let dest = backups.appendingPathComponent("pre-sync-\(stamp)\(suffix)")
        try? FileManager.default.copyItem(at: source, to: dest)
      }
    }
    UserDefaults.standard.set(true, forKey: key)
  }

  // MARK: - Push

  private func push(userId: UUID) async throws {
    let local = repository.exportForSync()
    let ownerId = userId

    let projectRows = local.projects.map { CloudProjectRow(from: $0, ownerId: ownerId) }
    if !projectRows.isEmpty {
      try await client.database.from("projects").upsert(projectRows, onConflict: "id").execute()
    }
    if !local.projectTombstones.isEmpty {
      let now = ISO8601DateFormatter().string(from: Date())
      let tombstoneRows = local.projectTombstones.map {
        CloudTombstoneRow(id: $0, ownerId: ownerId, deletedAt: now)
      }
      try await client.database.from("projects").upsert(tombstoneRows, onConflict: "id").execute()
    }

    let taskRows = local.tasks.map { CloudTaskRow(from: $0, ownerId: ownerId) }
    if !taskRows.isEmpty {
      try await client.database.from("tasks").upsert(taskRows, onConflict: "id").execute()
    }
    if !local.taskTombstones.isEmpty {
      let now = ISO8601DateFormatter().string(from: Date())
      let tombstoneRows = local.taskTombstones.map {
        CloudTombstoneRow(id: $0, ownerId: ownerId, deletedAt: now)
      }
      try await client.database.from("tasks").upsert(tombstoneRows, onConflict: "id").execute()
    }

    // نجاح الدفع = آثار الحذف المحلية اتسلمت — ننضفها محليًا.
    repository.clearTombstones(taskIds: local.taskTombstones, projectIds: local.projectTombstones)
  }

  // MARK: - Pull

  private func pull(userId: UUID) async throws {
    let projectRows: [CloudProjectRow] = try await client.database
      .from("projects").select().eq("owner_id", value: userId.uuidString).execute().value
    let taskRows: [CloudTaskRow] = try await client.database
      .from("tasks").select().eq("owner_id", value: userId.uuidString).execute().value

    let liveProjects = projectRows.filter { $0.deleted_at == nil }.map(\.projectItem)
    let liveTasks = taskRows.filter { $0.deleted_at == nil }.map(\.taskItem)
    let deletedProjectIds = projectRows.filter { $0.deleted_at != nil }.map(\.id)
    let deletedTaskIds = taskRows.filter { $0.deleted_at != nil }.map(\.id)

    // التطبيق: المشروعات الأول (المهام مربوطة فيها) — LWW داخليًا، والحذف السحابي ينتشر.
    repository.applyCloudDeletes(taskIds: deletedTaskIds, projectIds: deletedProjectIds)
    repository.applyCloudUpserts(projects: liveProjects, tasks: liveTasks)
  }
}

// MARK: - صفوف السحابة (Codable بنفس أعمدة الجداول)

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

  var projectItem: ProjectItem {
    ProjectItem(
      id: id, name: name, emoji: emoji, colorKey: color_key, createdAt: created_at,
      updatedAt: updated_at)
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
  let due_day: Date?
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
    due_day = item.dueDay?.date
    project_id = item.projectId
    reminder_date = item.reminderDate
    completed_at = item.completedAt
    created_at = item.createdAt
    updated_at = item.updatedAt
    deleted_at = nil
  }

  var taskItem: TaskItem {
    TaskItem(
      id: id,
      title: title,
      details: details,
      status: TaskStatus(rawValue: status) ?? .active,
      priority: TaskPriority(rawValue: priority) ?? .normal,
      isPinned: is_pinned,
      dueDay: due_day.flatMap { CalendarDay(date: $0) },
      projectId: project_id,
      reminderDate: reminder_date,
      createdAt: created_at,
      updatedAt: updated_at,
      completedAt: completed_at
    )
  }
}

struct CloudTombstoneRow: Codable {
  let id: UUID
  let owner_id: UUID
  let deleted_at: String

  init(id: UUID, ownerId: UUID, deletedAt: String) {
    self.id = id
    self.owner_id = ownerId
    self.deleted_at = deletedAt
  }
}
