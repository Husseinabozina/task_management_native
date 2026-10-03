import Observation
import SwiftUI

struct RootView: View {
  @Environment(AppSession.self) private var session
  @Environment(\.appRepository) private var appRepository

  var body: some View {
    // -tmSkipOnboarding: مدخل تشخيصي للأدوات فقط.
    if session.hasCompletedOnboarding
      || ProcessInfo.processInfo.arguments.contains("-tmSkipOnboarding")
    {
      if let repository = appRepository {
        RootTabs(repository: repository)
      } else {
        ContentUnavailableView(
          "مشكلة في تشغيل التطبيق",
          systemImage: "exclamationmark.triangle",
          description: Text("المخزن مش متوصّل — اقفل التطبيق وافتحه تاني.")
        )
      }
    } else {
      EntryScreen()
    }
  }
}

/// التابات + FAB — هيكل التنقل الرئيسي بعد شاشة البداية.
/// تابات حقيقية فقط (قرار D17): الرئيسية + مهامي؛ المشاريع ستُضاف عند توفر شاشتها.
@MainActor
struct RootTabs: View {
  let repository: LocalDataRepository

  @State private var selection: AppTab = .home
  @State private var editorSeed: TaskEditorSeed?

  var body: some View {
    GeometryReader { geo in
      // قياس منطقة مؤشر الهوم قبل التمديد، وتمريرها للشريط ليمتد تحتها.
      let bottomInset = geo.safeAreaInsets.bottom
      ZStack(alignment: .bottom) {
        Group {
          switch selection {
          case .home:
            HomeView(repository: repository) {
              selection = .tasks
            }
          case .tasks:
            TasksScreen(repository: repository)
              .navigationTitle("مهامي")
              .navigationBarTitleDisplayMode(.inline)
          case .projects:
            NavigationStack {
              ProjectsScreen(repository: repository)
            }
          }
        }
        BottomBar(selection: $selection, bottomInset: bottomInset) {
          editorSeed = .new(dueDay: nil)
        }
      }
      .ignoresSafeArea(.container, edges: .bottom)
      .ignoresSafeArea(.keyboard, edges: .bottom)
      .sheet(item: $editorSeed) { seed in
        TaskEditorSheet(seed: seed, repository: repository)
      }
      .onAppear {
        // مداخل تشخيصية للأدوات فقط: فتح تاب مباشر عند الإقلاع.
        if ProcessInfo.processInfo.arguments.contains("-tmStartTasks") {
          selection = .tasks
        } else if ProcessInfo.processInfo.arguments.contains("-tmStartProjects") {
          selection = .projects
        }
      }
    }
  }
}
