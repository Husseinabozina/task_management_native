import Foundation
import SwiftData

/// نماذج التخزين — طبقة data فقط، لا تسرّب للواجهة (العقد).
@Model
final class PersistedTask {
  @Attribute(.unique) var id: UUID
  var title: String
  var details: String?
  var statusRaw: String
  var priorityRaw: String
  /// بداية اليوم المحلي — يوم تقويمي بلا ساعة.
  var dueDayDate: Date?
  var projectId: UUID?
  var createdAt: Date
  var updatedAt: Date
  var completedAt: Date?

  init(
    id: UUID,
    title: String,
    details: String?,
    statusRaw: String,
    priorityRaw: String,
    dueDayDate: Date?,
    projectId: UUID?,
    createdAt: Date,
    updatedAt: Date,
    completedAt: Date?
  ) {
    self.id = id
    self.title = title
    self.details = details
    self.statusRaw = statusRaw
    self.priorityRaw = priorityRaw
    self.dueDayDate = dueDayDate
    self.projectId = projectId
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.completedAt = completedAt
  }
}

@Model
final class PersistedProject {
  @Attribute(.unique) var id: UUID
  var name: String
  var emoji: String?
  var colorKey: String?
  var createdAt: Date

  init(id: UUID, name: String, emoji: String?, colorKey: String?, createdAt: Date) {
    self.id = id
    self.name = name
    self.emoji = emoji
    self.colorKey = colorKey
    self.createdAt = createdAt
  }
}
