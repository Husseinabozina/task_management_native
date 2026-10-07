import Foundation
import UserNotifications

/// موتور مزامنة التذكيرات (قرار D22): يراقب كل المهام ويجعل إشعارات النظام
/// مطابقة لها دائمًا — مهمة بتذكير وغير مكتملة = إشعار مجدول بهويتها؛
/// إتمام/حذف/إزالة التذكير = الإشعار يُلغى فورًا.
/// لا يُجدول شيئًا أبدًا بدون إذن — والصمت هنا صادق (المحرر هو من يطلب الإذن ويعرض الخطأ).
@MainActor
final class ReminderSync {
  private var observationTask: Task<Void, Never>?

  func start(repository: TaskRepository) {
    observationTask?.cancel()
    observationTask = Task { [weak self] in
      let stream = repository.observeTasks(TaskQuery())
      for await items in stream {
        guard let self, !Task.isCancelled else { break }
        await self.reconcile(items)
      }
    }
  }

  func reconcile(_ tasks: [TaskItem]) async {
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    // Authorization is requested by the editor, never during app startup.
    guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { return }

    let pending = await center.pendingNotificationRequests()
    let desired = Dictionary(
      uniqueKeysWithValues:
        tasks
        .filter { ($0.reminderDate ?? .distantPast) > Date() && $0.status != .completed }
        .sorted { ($0.reminderDate ?? .distantFuture) < ($1.reminderDate ?? .distantFuture) }
        .prefix(64)
        .map { ($0.id.uuidString, $0) }
    )
    let desiredIds = Set(desired.keys)

    // إلغاء كل إشعار مهمته اتحذفت أو اتمتت أو اتشال تذكيرها.
    let stale = pending.map(\.identifier).filter { !desiredIds.contains($0) }
    if !stale.isEmpty {
      center.removePendingNotificationRequests(withIdentifiers: stale)
    }

    // إضافة/تحديث المطلوب — إعادة الجدولة فقط عندما يختلف الموعد المخزن.
    for (identifier, task) in desired {
      guard let reminderDate = task.reminderDate else { continue }
      if let existing = pending.first(where: { $0.identifier == identifier }),
        let trigger = existing.trigger as? UNCalendarNotificationTrigger,
        let scheduled = trigger.dateComponents.date,
        abs(scheduled.timeIntervalSince(reminderDate)) < 1,
        existing.content.body == task.title,
        existing.content.userInfo["taskId"] as? String == identifier
      {
        continue
      }
      let content = UNMutableNotificationContent()
      content.title = "تذكير بمهمة"
      content.body = task.title
      content.sound = .default
      content.userInfo = ["taskId": task.id.uuidString]
      let components = Calendar.current.dateComponents(
        [.year, .month, .day, .hour, .minute, .second], from: reminderDate)
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      let request = UNNotificationRequest(
        identifier: identifier, content: content, trigger: trigger)
      try? await center.add(request)
    }
  }
}

/// عرض الإشعار حتى والتطبيق مفتوح في المقدمة.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  private let onOpenTask: @MainActor (UUID) -> Void

  init(onOpenTask: @escaping @MainActor (UUID) -> Void) {
    self.onOpenTask = onOpenTask
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
  ) async {
    guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
    let request = response.notification.request
    let raw = request.content.userInfo["taskId"] as? String ?? request.identifier
    guard let id = UUID(uuidString: raw) else { return }
    await onOpenTask(id)
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    [.banner, .sound]
  }
}
