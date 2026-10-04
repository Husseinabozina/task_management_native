import SwiftUI

/// شاشة مهامي — تصميم فيجما 101:265: شريط أيام + chips الحالة + الصفوف + إضافة سريعة.
struct TasksScreen: View {
  @State private var viewModel: TasksViewModel
  @State private var projects: [ProjectItem] = []
  @State private var quickTitle = ""
  @State private var quickError: String?
  @State private var editorSeed: TaskEditorSeed?
  @State private var detailItem: TaskItem?

  private let repository: LocalDataRepository

  /// فلتر ثابت عند الفتح من المشاريع (projectId) أو من التقويم (initialDay).
  init(repository: LocalDataRepository, projectId: UUID? = nil, initialDay: CalendarDay? = nil) {
    self.repository = repository
    let query = TaskQuery(
      day: initialDay.map { TaskQuery.DayFilter.day($0) } ?? .all,
      status: .any,
      projectId: projectId
    )
    _viewModel = State(initialValue: TasksViewModel(repository: repository, query: query))
  }

  var body: some View {
    VStack(spacing: 14) {
      WeekStrip(selection: viewModel.query.day) { viewModel.selectDay($0) }
      StatusChips(selection: viewModel.query.status) { viewModel.selectStatus($0) }
      content
      quickAddBar
    }
    .padding(.horizontal, Metrics.screenPadding)
    // مسافة أسفل الشاشة تفرغ مكان الـ bottom bar (78) + هامش تنفّس.
    .padding(.bottom, 94)
    .background(Color.appBackground)
    .task {
      for await items in repository.observeProjects() {
        projects = items
      }
    }
    .sheet(item: $detailItem) { item in
      TaskDetailSheet(
        item: item,
        project: projects.first { $0.id == item.projectId },
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

  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading {
      Spacer()
      ProgressView()
      Spacer()
    } else if viewModel.tasks.isEmpty {
      Spacer()
      let hasFilters = viewModel.query.day != .all || viewModel.query.status != .any
      ContentUnavailableView(
        hasFilters ? "مفيش نتايج بالفلتر ده" : "مفيش مهام لسه",
        systemImage: hasFilters ? "line.3.horizontal.decrease.circle" : "checklist",
        description: Text(
          hasFilters
            ? "جرّب تغيّر اليوم أو الحالة، أو ارجع لـ«الكل»."
            : "ابدأ من خانة الإضافة السريعة اللي تحت، أو من زر ＋."
        )
      )
      Spacer()
    } else {
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(viewModel.tasks) { item in
            TaskRowView(
              item: item,
              project: item.projectId.flatMap { id in projects.first { $0.id == id } },
              onOpen: { detailItem = item },
              onToggleCompletion: {
                Task {
                  if let message = await viewModel.toggleCompletion(of: item) {
                    quickError = message
                  }
                }
              }
            )
          }
        }
        .padding(.bottom, 96)
      }
    }
  }

  private var quickAddBar: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 8) {
        Image("icon_add")
          .resizable()
          .renderingMode(.template)
          .foregroundStyle(Color.appPrimary)
          .frame(width: 16, height: 16)
        TextField(
          "أضف مهمة…",
          text: $quickTitle,
          prompt: Text("أضف مهمة…").foregroundStyle(Color.appTextSecondary)
        )
        .font(AppTypography.bodyText)
        .submitLabel(.done)
        .onSubmit { Task { await submitQuickAdd() } }
      }
      .padding(.horizontal, 16)
      .frame(height: 52)
      .background(Color.appSurface)
      .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
      .cardShadow()
      if let quickError {
        Text(quickError)
          .font(AppTypography.metadata)
          .foregroundStyle(Color.appError)
      }
    }
  }

  private func submitQuickAdd() async {
    guard !quickTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      quickError = "العنوان مطلوب."
      return
    }
    if let message = await viewModel.addQuickTask(rawTitle: quickTitle) {
      quickError = message
    } else {
      quickTitle = ""
      quickError = nil
    }
  }
}

/// شريط الأيام: «الكل» + 7 أيام قادمة — اختيار يوم = فلتر حقيقي (العقد).
private struct WeekStrip: View {
  let selection: TaskQuery.DayFilter
  let onSelect: (TaskQuery.DayFilter) -> Void

  private var upcomingDays: [CalendarDay] {
    let today = CalendarDay.today()
    let calendar = Calendar.current
    return (1...7).compactMap { offset in
      calendar.date(byAdding: .day, value: offset, to: today.date).flatMap { CalendarDay(date: $0) }
    }
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        dayCard(isSelected: selection == .all, width: 64) {
          Text("الكل")
            .font(AppTypography.chipSelected)
            .foregroundStyle(selection == .all ? Color.white : Color.appTextPrimary)
        } action: {
          onSelect(.all)
        }
        ForEach(upcomingDays, id: \.date) { day in
          dayCard(isSelected: isDaySelected(day), width: 64) {
            VStack(spacing: 2) {
              Text(Self.monthLabel(for: day))
                .font(AppTypography.metadata)
              Text(Self.dayNumberLabel(for: day))
                .font(AppTypography.numeralTitle)
              Text(Self.weekdayLabel(for: day))
                .font(AppTypography.metadata)
            }
          } action: {
            onSelect(.day(day))
          }
        }
      }
      .padding(.vertical, 2)
    }
  }

  private func isDaySelected(_ day: CalendarDay) -> Bool {
    if case .day(let selected) = selection { return selected == day }
    return false
  }

  private func dayCard<Content: View>(
    isSelected: Bool,
    width: CGFloat,
    @ViewBuilder label: () -> Content,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      label()
        .foregroundStyle(isSelected ? Color.white : Color.appTextPrimary)
        .frame(width: width, height: 84)
        .background(
          RoundedRectangle(cornerRadius: Metrics.chipCornerRadius + 6)
            .fill(isSelected ? Color.appPrimary : Color.appSurface)
        )
        .cardShadow()
    }
    .buttonStyle(.plain)
  }

  private static let arabicFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ar_EG")
    return formatter
  }()

  static func monthLabel(for day: CalendarDay) -> String {
    arabicFormatter.dateFormat = "MMM"
    return arabicFormatter.string(from: day.date)
  }

  static func dayNumberLabel(for day: CalendarDay) -> String {
    arabicFormatter.dateFormat = "d"
    return arabicFormatter.string(from: day.date)
  }

  static func weekdayLabel(for day: CalendarDay) -> String {
    arabicFormatter.dateFormat = "EEE"
    return arabicFormatter.string(from: day.date)
  }
}

/// chips الحالة: الكل / مفتوحة / مكتملة (قرار D11 — لا In Progress في V1).
private struct StatusChips: View {
  let selection: TaskQuery.StatusFilter
  let onSelect: (TaskQuery.StatusFilter) -> Void

  var body: some View {
    HStack(spacing: 8) {
      chip(title: "الكل", value: .any)
      chip(title: "مفتوحة", value: .active)
      chip(title: "مكتملة", value: .completed)
      Spacer()
    }
  }

  private func chip(title: String, value: TaskQuery.StatusFilter) -> some View {
    let isSelected = selection == value
    return Button {
      onSelect(value)
    } label: {
      Text(title)
        .font(isSelected ? AppTypography.chipSelected : AppTypography.bodyText)
        .foregroundStyle(isSelected ? Color.white : Color.appPrimary)
        .padding(.horizontal, 14)
        .frame(height: 34)
        .background(
          RoundedRectangle(cornerRadius: Metrics.chipCornerRadius)
            .fill(isSelected ? Color.appPrimary : Color.appLavenderAlt)
        )
    }
    .buttonStyle(.plain)
  }
}
