import SwiftData
import SwiftUI

@main
struct TaskManagementApp: App {
  @State private var session = AppSession()
  private let bootstrap = AppDependencies.bootstrap()

  var body: some Scene {
    WindowGroup {
      switch bootstrap {
      case .success(let dependencies):
        RootView()
          .environment(session)
          .environment(\.appRepository, dependencies.repository)
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
