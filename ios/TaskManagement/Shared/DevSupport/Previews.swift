import SwiftData
import SwiftUI

/// أدوات المعاينة فقط (Xcode Previews) — لا تدخل في سلوك التطبيق.
/// مخزن في الذاكرة يعيد البناء من الصفر مع كل معاينة، بلا أي أثر على بيانات حقيقية.
#if DEBUG
  @MainActor
  enum PreviewSupport {
    static func inMemoryRepository() -> LocalDataRepository {
      let schema = Schema([PersistedTask.self, PersistedProject.self])
      let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
      let container = try! ModelContainer(for: schema, configurations: [configuration])
      return LocalDataRepository(container: container)
    }

    static let sampleActiveTask = TaskItem(
      id: UUID(),
      title: "أسلّم تقرير المشروع",
      details: "مراجعة نهائية قبل التسليم",
      status: .active,
      priority: .high,
      dueDay: CalendarDay.today(),
      projectId: nil,
      createdAt: Date(),
      updatedAt: Date(),
      completedAt: nil
    )

    static let sampleCompletedTask = TaskItem(
      id: UUID(),
      title: "مكالمة العميل",
      details: nil,
      status: .completed,
      priority: .normal,
      dueDay: CalendarDay.today(),
      projectId: nil,
      createdAt: Date(),
      updatedAt: Date(),
      completedAt: Date()
    )

    /// رئيسية فيها مهام (واحدة مكتملة) لتجربة الكارت الحقيقي.
    static func homeWithTasks() -> HomeView {
      let repository = inMemoryRepository()
      if let first = try? repository.create(
        NewTask(
          title: "أسلّم تقرير المشروع", details: nil, priority: .high, dueDay: CalendarDay.today(),
          projectId: nil)
      ) {
        _ = try? repository.create(
          NewTask(
            title: "مكالمة العميل", details: nil, priority: .normal, dueDay: CalendarDay.today(),
            projectId: nil)
        )
        _ = try? repository.setCompleted(id: first.id, true)
      }
      return HomeView(repository: repository, onOpenTasks: {})
    }

    /// شاشة مهامي فيها مهام متنوعة (مكتملة/مفتوحة/بموعد/بدون).
    static func tasksWithSamples() -> TasksScreen {
      let repository = inMemoryRepository()
      _ = try? repository.create(
        NewTask(
          title: "أسلّم تقرير المشروع", details: "مراجعة نهائية قبل التسليم", priority: .high,
          dueDay: CalendarDay.today(), projectId: nil)
      )
      _ = try? repository.create(
        NewTask(title: "اقرأ 20 صفحة", details: nil, priority: .normal, dueDay: nil, projectId: nil)
      )
      if let done = try? repository.create(
        NewTask(
          title: "مكالمة العميل", details: nil, priority: .normal, dueDay: CalendarDay.today(),
          projectId: nil)
      ) {
        _ = try? repository.setCompleted(id: done.id, true)
      }
      return TasksScreen(repository: repository)
    }

    /// شاشة المشاريع فيها مشاريع تجربة بعدد مهام ونسب إنجاز متنوعة.
    static func projectsWithSamples() -> ProjectsScreen {
      let repository = inMemoryRepository()
      if let work = try? repository.createProject(
        NewProject(name: "مشروع الشغل", emoji: "💼", colorKey: ProjectPalette.blue.rawValue)
      ) {
        _ = try? repository.create(
          NewTask(
            title: "أسلّم تقرير المشروع", details: nil, priority: .high, dueDay: CalendarDay.today(),
            projectId: work.id)
        )
        if let done = try? repository.create(
          NewTask(
            title: "مكالمة العميل", details: nil, priority: .normal, dueDay: CalendarDay.today(),
            projectId: work.id)
        ) {
          _ = try? repository.setCompleted(id: done.id, true)
        }
      }
      _ = try? repository.createProject(
        NewProject(name: "المذاكرة", emoji: "📚", colorKey: ProjectPalette.orange.rawValue)
      )
      return ProjectsScreen(repository: repository)
    }
  }

  #Preview("شاشة البداية") {
    EntryScreen()
      .environment(AppSession())
  }

  #Preview("الرئيسية — فاضية") {
    HomeView(repository: PreviewSupport.inMemoryRepository(), onOpenTasks: {})
  }

  #Preview("الرئيسية — فيها مهام") {
    PreviewSupport.homeWithTasks()
  }

  #Preview("مهامي — فيها مهام") {
    PreviewSupport.tasksWithSamples()
  }

  #Preview("المشاريع — فيها مشاريع") {
    NavigationStack {
      PreviewSupport.projectsWithSamples()
    }
  }

  #Preview("صف مهمة") {
    VStack(spacing: 12) {
      TaskRowView(
        item: PreviewSupport.sampleActiveTask, project: nil, onOpen: {}, onToggleCompletion: {})
      TaskRowView(
        item: PreviewSupport.sampleCompletedTask, project: nil, onOpen: {}, onToggleCompletion: {})
    }
    .padding(16)
    .background(Color.appBackground)
  }

  #Preview("محرر مهمة") {
    TaskEditorSheet(seed: .new(dueDay: nil), repository: PreviewSupport.inMemoryRepository())
  }
#endif
