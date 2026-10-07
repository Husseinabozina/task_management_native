import SwiftUI

/// شاشة المشاريع — صفوف Task Group بستايل فيجما (chip إيموجي pastel + الاسم + عدد المهام + النسبة)
/// وإنشاء مشروع بنفس نمط شاشة Add Project (قرار D12: الاسم + الإيموجي + اللون فقط).
struct ProjectsScreen: View {
  let repository: LocalDataRepository

  @State private var viewModel: ProjectsViewModel?
  @State private var showCreateSheet = false
  @State private var deleteTarget: ProjectItem?
  @State private var actionMessage: String?
  @State private var openedProject: ProjectItem?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("مشاريعك")
          .font(AppTypography.screenTitle)
          .foregroundStyle(Color.appTextPrimary)
        Spacer()
        Button {
          showCreateSheet = true
        } label: {
          HStack(spacing: 6) {
            Image("icon_add")
              .resizable()
              .renderingMode(.template)
              .foregroundStyle(.white)
              .frame(width: 14, height: 14)
            Text("مشروع جديد")
              .font(AppTypography.chipSelected)
              .foregroundStyle(.white)
          }
          .padding(.horizontal, 12)
          .frame(height: 34)
          .background(
            RoundedRectangle(cornerRadius: Metrics.chipCornerRadius).fill(Color.appPrimary))
        }
        .accessibilityLabel("إنشاء مشروع جديد")
      }

      content
    }
    .padding(.horizontal, Metrics.screenPadding)
    // مسافة أسفل الشاشة تفرغ مكان الـ bottom bar (78) + هامش تنفّس.
    .padding(.bottom, 94)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.appBackground)
    .task {
      if viewModel == nil {
        viewModel = ProjectsViewModel(repository: repository)
      }
      await seedDemoProjectIfRequested()
    }
    .sheet(isPresented: $showCreateSheet) {
      ProjectEditorSheet { name, emoji, colorKey in
        let message = await viewModel?.createProject(name: name, emoji: emoji, colorKey: colorKey)
        actionMessage = message
        return message
      }
    }
    .confirmationDialog(
      "حذف مشروع «\(deleteTarget?.name ?? "")»؟",
      isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }),
      titleVisibility: .visible
    ) {
      Button("حذف المشروع — نقل مهامه إلى «بدون مشروع»", role: .destructive) {
        guard let target = deleteTarget else { return }
        Task {
          actionMessage = await viewModel?.deleteProject(target)
          deleteTarget = nil
        }
      }
      Button("إلغاء", role: .cancel) { deleteTarget = nil }
    } message: {
      Text("ستبقى المهام محفوظة ضمن «بدون مشروع».")
    }
    .navigationDestination(item: $openedProject) { project in
      TasksScreen(repository: repository, projectId: project.id)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
    }
  }

  /// مدخل تشخيصي: -tmSeedDemoProject ينشئ مشروع تجربة واحد معلّم إذا كانت القايمة فاضية.
  private func seedDemoProjectIfRequested() async {
    guard ProcessInfo.processInfo.arguments.contains("-tmSeedDemoProject") else { return }
    guard let viewModel, viewModel.projects.isEmpty else { return }
    _ = await viewModel.createProject(
      name: "مشروع تجريبي — قابل للحذف", emoji: "🚀", colorKey: ProjectPalette.purple.rawValue)
  }

  @ViewBuilder
  private var content: some View {
    if viewModel?.isLoading == true {
      Spacer()
      ProgressView()
      Spacer()
    } else if let projects = viewModel?.projects, projects.isEmpty {
      Spacer()
      ContentUnavailableView(
        "لا توجد مشاريع بعد",
        systemImage: "folder.badge.plus",
        description: Text("أنشئ مشروعك الأول لتنظيم مهامك من زر «مشروع جديد» أعلاه.")
      )
      Spacer()
    } else if let projects = viewModel?.projects {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(projects) { project in
            ProjectRowView(
              project: project,
              activeCount: viewModel?.activeCount(for: project.id) ?? 0,
              progress: viewModel?.progress(for: project.id) ?? 0,
              onOpen: { openedProject = project },
              onDelete: { deleteTarget = project }
            )
          }
        }
        .padding(.bottom, 8)
      }
    }
    if let actionMessage {
      Text(actionMessage)
        .font(AppTypography.metadata)
        .foregroundStyle(Color.appError)
    }
  }
}

/// صف مشروع — شكل Task Group من الفيجما: chip 34 pastel بإيموجي + الاسم + «N مهام» + النسبة.
/// onDelete اختياري: شاشة المشاريع تمرره، والرئيسية تعرض الصف للفتح فقط.
struct ProjectRowView: View {
  let project: ProjectItem
  let activeCount: Int
  let progress: Double
  let onOpen: () -> Void
  var onDelete: (() -> Void)? = nil

  var body: some View {
    Button(action: onOpen) {
      HStack(spacing: 14) {
        Text(project.emoji ?? "📁")
          .font(.system(size: 17))
          .frame(width: Metrics.iconChipSize, height: Metrics.iconChipSize)
          .background(
            RoundedRectangle(cornerRadius: Metrics.chipCornerRadius)
              .fill(ProjectPalette.color(forKey: project.colorKey))
          )
        VStack(alignment: .leading, spacing: 3) {
          Text(project.name)
            .font(AppTypography.bodyText)
            .foregroundStyle(Color.appTextPrimary)
            .lineLimit(1)
          Text("\(activeCount) مهام مفتوحة")
            .font(AppTypography.metadata)
            .foregroundStyle(Color.appTextSecondary)
        }
        Spacer(minLength: 8)
        Text("\(Int((progress * 100).rounded()))%")
          .font(AppTypography.metadata)
          .foregroundStyle(Color.appTextSecondary)
          .environment(\.layoutDirection, .leftToRight)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(Color.appSurface)
      .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
      .cardShadow()
    }
    .buttonStyle(.plain)
    .contextMenu {
      if let onDelete {
        Button(role: .destructive, action: onDelete) {
          Label("حذف المشروع", systemImage: "trash")
        }
      }
    }
  }
}
