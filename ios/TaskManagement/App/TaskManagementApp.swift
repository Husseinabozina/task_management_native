import SwiftData
import SwiftUI
import UserNotifications

@main
struct TaskManagementApp: App {
  @State private var session = AppSession()
  private let bootstrap = AppDependencies.bootstrap()
  @State private var notificationDelegate: NotificationDelegate

  init() {
    // عرض الإشعار حتى والتطبيق مفتوح في المقدمة.
    let state = AppSession()
    _session = State(initialValue: state)
    let delegate = NotificationDelegate { id in state.notificationTaskId = id }
    _notificationDelegate = State(initialValue: delegate)
    UNUserNotificationCenter.current().delegate = delegate
  }

  var body: some Scene {
    WindowGroup {
      switch bootstrap {
      case .success(let dependencies):
        RootView()
          .environment(session)
          .environment(\.appRepository, dependencies.repository)
          .environment(\.cloudBundle, dependencies.cloud)
          .modelContainer(dependencies.container)
      case .failure(let error):
        BootFailureView(message: error.readableDescription)
      }
    }
  }
}

/// حالة إقلاع صادقة: فشل فتح المخزن يظهر للمستخدم ولا يُخفى.
struct BootFailureView: View {
  let message: String

  var body: some View {
    ContentUnavailableView(
      "مشكلة في تشغيل التطبيق",
      systemImage: "exclamationmark.triangle",
      description: Text(message)
    )
  }
}
