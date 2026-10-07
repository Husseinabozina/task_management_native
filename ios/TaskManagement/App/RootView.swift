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
          description: Text("تعذّر الاتصال بالتخزين المحلي. أغلق التطبيق وأعد فتحه.")
        )
      }
    } else {
      EntryScreen()
    }
  }
}

/// التابات + FAB — هيكل التنقل الرئيسي بعد شاشة البداية.
/// 4 تابات حقيقية (قرار D18): الرئيسية + التقويم + مهامي + المشاريع.
@MainActor
struct RootTabs: View {
  let repository: LocalDataRepository

  @Environment(AppSession.self) private var session
  @State private var notificationTask: TaskItem?
  @State private var notificationProject: ProjectItem?
  @State private var notificationEdit: TaskItem?
  @State private var notificationError: String?

  @State private var selection: AppTab = .home
  @State private var editorSeed: TaskEditorSeed?
  @State private var homePath = NavigationPath()

  var body: some View {
    GeometryReader { geo in
      // قياس منطقة مؤشر الهوم قبل التمديد، وتمريرها للشريط ليمتد تحتها.
      let bottomInset = geo.safeAreaInsets.bottom
      ZStack(alignment: .bottom) {
        Group {
          switch selection {
          case .home:
            NavigationStack(path: $homePath) {
              HomeView(
                repository: repository,
                onOpenTasks: { selection = .tasks },
                onOpenProject: { project in homePath.append(project) }
              )
              .navigationDestination(for: ProjectItem.self) { project in
                TasksScreen(repository: repository, projectId: project.id)
                  .navigationTitle(project.name)
                  .navigationBarTitleDisplayMode(.inline)
              }
            }
          case .calendar:
            NavigationStack {
              CalendarScreen(repository: repository)
                .navigationTitle("التقويم")
                .navigationBarTitleDisplayMode(.inline)
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
      .sheet(item: $notificationTask, onDismiss: {
        if let item = notificationEdit {
          notificationEdit = nil
          editorSeed = .edit(item)
        }
      }) { item in
        TaskDetailSheet(item: item, project: notificationProject, repository: repository,
          onEdit: { value in notificationEdit = value; notificationTask = nil },
          onDeleted: { notificationTask = nil })
      }
      .task(id: session.notificationTaskId) {
        guard let id = session.notificationTaskId else { return }
        session.notificationTaskId = nil
        do {
          let context = try repository.notificationContext(id: id)
          notificationProject = context.project
          notificationTask = context.task
        } catch {
          notificationError = "تعذّر فتح المهمة. ربما حُذفت؛ مهامك الأخرى محفوظة."
        }
      }
      .alert("التذكير", isPresented: Binding(
        get: { notificationError != nil }, set: { if !$0 { notificationError = nil } }
      )) { Button("حسنًا") { notificationError = nil } }
        message: { Text(notificationError ?? "") }
      .onAppear {
        // مداخل تشخيصية للأدوات فقط: فتح تاب مباشر عند الإقلاع.
        if ProcessInfo.processInfo.arguments.contains("-tmStartTasks") {
          selection = .tasks
        } else if ProcessInfo.processInfo.arguments.contains("-tmStartCalendar") {
          selection = .calendar
        } else if ProcessInfo.processInfo.arguments.contains("-tmStartProjects") {
          selection = .projects
        }
      }
    }
  }
}
