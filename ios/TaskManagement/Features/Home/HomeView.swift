import Observation
import SwiftUI

/// الرئيسية — رأس الترحيب + جرس المتأخرات + الكارت الرئيسي + الكارتين البارزين
/// + «مهام النهارده» + «مشاريعك» — كلها ببيانات حقيقية، والأقسام الفاضية تختفي (SCREEN_PLAN §1).
struct HomeView: View {
  let repository: LocalDataRepository
  let onOpenTasks: () -> Void
  let onOpenProject: (ProjectItem) -> Void

  @State private var viewModel: HomeViewModel?
  @State private var detailItem: TaskItem?
  @State private var editorSeed: TaskEditorSeed?
  @State private var actionMessage: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        header
        heroCard
        if !featured.isEmpty {
          featuredSection
        }
        if !activeToday.isEmpty {
          todaySection
        }
        if !projects.isEmpty {
          projectsSection
        }
      }
      .padding(.horizontal, Metrics.screenPadding)
      .padding(.top, 8)
      .padding(.bottom, 120)
    }
    .background(Color.appBackground)
    .task {
      if viewModel == nil {
        viewModel = HomeViewModel(repository: repository)
      }
    }
    .sheet(item: $detailItem) { item in
      TaskDetailSheet(
        item: item,
        project: viewModel?.project(for: item.projectId),
        repository: repository,
        onEdit: { edited in
          detailItem = nil
          editorSeed = .edit(edited)
        },
        onDeleted: { detailItem = nil }
      )
    }
    .sheet(item: $editorSeed) { seed in
      TaskEditorSheet(seed: seed, repository: repository)
    }
  }

  // MARK: - الرأس + الجرس

  private var header: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 2) {
        Text("أهلًا 👋")
          .font(AppTypography.bodyText)
          .foregroundStyle(Color.appTextSecondary)
        Text(Self.todayLabel())
          .font(AppTypography.screenTitle)
          .foregroundStyle(Color.appTextPrimary)
      }
      Spacer()
      // مؤشر حالة المتأخرات — مؤشر معلوماتي لا زر (لا توجد شاشة إشعارات في V1).
      bell
        .accessibilityLabel(
          (viewModel?.overdueCount ?? 0) > 0
            ? "عندك \(viewModel?.overdueCount ?? 0) مهام متأخرة"
            : "مفيش مهام متأخرة"
        )
    }
  }

  private var bell: some View {
    let overdue = viewModel?.overdueCount ?? 0
    return Image("icon_notification")
      .resizable()
      .frame(width: 24, height: 24)
      .foregroundStyle(Color.appTextPrimary)
      .overlay(alignment: .topTrailing) {
        if overdue > 0 {
          Circle()
            .fill(Color.appPrimary)
            .frame(width: 8, height: 8)
            .offset(x: 3, y: -2)
        }
      }
  }

  // MARK: - الكارت الرئيسي

  private var heroCard: some View {
    let total = viewModel?.totalToday ?? 0
    let completed = viewModel?.completedToday ?? 0
    return HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 10) {
        Text(heroTitle(total: total, completed: completed))
          .font(AppTypography.bodyText)
          .foregroundStyle(Color.white)
          .multilineTextAlignment(.leading)
        Button(action: onOpenTasks) {
          Text("شوف مهامك")
            .font(AppTypography.chipSelected)
            .foregroundStyle(Color.appPrimary)
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background(
              RoundedRectangle(cornerRadius: Metrics.chipCornerRadius)
                .fill(Color.appLavender)
            )
        }
        .buttonStyle(.plain)
      }
      Spacer(minLength: 8)
      donut(progress: total > 0 ? Double(completed) / Double(total) : 0)
    }
    .padding(20)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: Metrics.heroCardCornerRadius)
        .fill(Color.appPrimary)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 0)
    )
  }

  private func heroTitle(total: Int, completed: Int) -> String {
    guard total > 0 else { return "مفيش مهام النهارده — ابدأ بإضافة أول مهمة من زر ＋" }
    if completed == total {
      return "مبروك! خلّصت كل مهام النهارده 🎉"
    }
    return "مهام النهارده: خلّصت \(completed) من \(total)"
  }

  private func donut(progress: Double) -> some View {
    ZStack {
      Circle()
        .stroke(Color.appLavender, lineWidth: 8)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(Color.appDonutFill, style: StrokeStyle(lineWidth: 8, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .animation(.easeOut(duration: 0.25), value: progress)
      Text("\(Int((progress * 100).rounded()))%")
        .font(AppTypography.numeral)
        .foregroundStyle(Color.white)
        .environment(\.layoutDirection, .leftToRight)
    }
    .frame(width: 76, height: 76)
    .accessibilityLabel("تقدم مهام النهارده \(Int((progress * 100).rounded())) بالمئة")
  }

  // MARK: - الكارتان البارزتان (أهم مشروعين نشاطًا)

  private var featured: [ProjectItem] {
    viewModel?.featuredProjects ?? []
  }

  private var featuredSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Text("أهم المشاريع شغالة")
          .font(AppTypography.sectionTitle)
          .foregroundStyle(Color.appTextPrimary)
        countBadge(featured.count)
        Spacer()
      }
      HStack(spacing: 16) {
        ForEach(featured) { project in
          FeaturedProjectCard(
            project: project,
            activeCount: viewModel?.activeCount(projectId: project.id) ?? 0,
            progress: viewModel?.progress(projectId: project.id) ?? 0,
            onTap: { onOpenProject(project) }
          )
        }
      }
    }
  }

  // MARK: - مهام النهارده (أول 3 + الكل)

  private var activeToday: [TaskItem] {
    Array((viewModel?.activeTodayTasks ?? []).prefix(3))
  }

  private var todaySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Text("مهام النهارده")
          .font(AppTypography.sectionTitle)
          .foregroundStyle(Color.appTextPrimary)
        Spacer()
        Button(action: onOpenTasks) {
          Text("الكل")
            .font(AppTypography.chipSelected)
            .foregroundStyle(Color.appPrimary)
        }
        .buttonStyle(.plain)
      }
      LazyVStack(spacing: 12) {
        ForEach(activeToday) { item in
          TaskRowView(
            item: item,
            project: viewModel?.project(for: item.projectId),
            onOpen: { detailItem = item },
            onToggleCompletion: {
              Task {
                if let message = await viewModel?.toggleCompletion(of: item) {
                  actionMessage = message
                }
              }
            }
          )
        }
      }
    }
  }

  // MARK: - مقطع مشاريعك (صفوف Task Group من الفيجما)

  private var projects: [ProjectItem] {
    viewModel?.projects ?? []
  }

  private var projectsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Text("مشاريعك")
          .font(AppTypography.sectionTitle)
          .foregroundStyle(Color.appTextPrimary)
        countBadge(projects.count)
        Spacer()
      }
      LazyVStack(spacing: 12) {
        ForEach(projects) { project in
          ProjectRowView(
            project: project,
            activeCount: viewModel?.activeCount(projectId: project.id) ?? 0,
            progress: viewModel?.progress(projectId: project.id) ?? 0,
            onOpen: { onOpenProject(project) },
            onDelete: nil
          )
        }
      }
    }
  }

  private func countBadge(_ value: Int) -> some View {
    Text("\(value)")
      .font(AppTypography.numeral)
      .foregroundStyle(Color.appPrimary)
      .frame(width: 16, height: 16)
      .background(Circle().fill(Color.appLavender))
      .environment(\.layoutDirection, .leftToRight)
  }

  private static func todayLabel() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ar_EG")
    formatter.dateFormat = "EEEE، d MMMM"
    return formatter.string(from: Date())
  }
}

/// الكارت البارز — 202 عرض radius 19 pastel + اسم المشروع + شريط تقدم (شكل فيجما).
private struct FeaturedProjectCard: View {
  let project: ProjectItem
  let activeCount: Int
  let progress: Double
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 10) {
        Text(project.emoji ?? "📁")
          .font(.system(size: 17))
          .frame(width: Metrics.iconChipSize, height: Metrics.iconChipSize)
          .background(
            RoundedRectangle(cornerRadius: Metrics.chipCornerRadius)
              .fill(Color.appSurface.opacity(0.75))
          )
        Text(project.name)
          .font(AppTypography.chipSelected)
          .foregroundStyle(Color.appTextPrimary)
          .lineLimit(1)
        Text("\(activeCount) مهام مفتوحة")
          .font(AppTypography.metadata)
          .foregroundStyle(Color.appTextSecondary)
        GeometryReader { geo in
          ZStack(alignment: .leading) {
            Capsule().fill(Color.appSurface)
            Capsule()
              .fill(Color.appPrimary)
              .frame(width: max(6, geo.size.width * progress))
              .animation(.easeOut(duration: 0.25), value: progress)
          }
        }
        .frame(height: 6)
      }
      .padding(14)
      .frame(width: 190, height: 116, alignment: .topLeading)
      .background(
        RoundedRectangle(cornerRadius: Metrics.secondaryCardCornerRadius)
          .fill(ProjectPalette.color(forKey: project.colorKey))
      )
    }
    .buttonStyle(.plain)
  }
}
