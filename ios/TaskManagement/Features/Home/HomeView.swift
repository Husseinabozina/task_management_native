import Observation
import SwiftUI

/// حالة الرئيسية — تراقب مهام اليوم لحساب تقدم الكارت الرئيسي بيانات حقيقية.
@Observable
@MainActor
final class HomeViewModel {
  private(set) var todayTasks: [TaskItem] = []

  private let repository: TaskRepository
  private var observationTask: Task<Void, Never>?

  init(repository: TaskRepository) {
    self.repository = repository
    observationTask = Task { [weak self] in
      let query = TaskQuery(day: .day(CalendarDay.today()), status: .any)
      for await items in repository.observeTasks(query) {
        guard let self, !Task.isCancelled else { break }
        self.todayTasks = items
      }
    }
  }

  var completedToday: Int {
    todayTasks.filter { $0.status == .completed }.count
  }

  var totalToday: Int {
    todayTasks.count
  }

  var progress: Double {
    guard totalToday > 0 else { return 0 }
    return Double(completedToday) / Double(totalToday)
  }
}

/// الرئيسية — رأس الترحيب + الكارت الرئيسي (تقدم اليوم الحقيقي) + مدخل شاشة مهامي.
/// مقطع المشاريع يُضاف في checkpoint المشاريع (لا عناصر وهمية).
struct HomeView: View {
  let repository: LocalDataRepository
  let onOpenTasks: () -> Void

  @State private var viewModel: HomeViewModel?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        header
        heroCard
      }
      .padding(.horizontal, Metrics.screenPadding)
      .padding(.top, 8)
      .padding(.bottom, 110)
    }
    .background(Color.appBackground)
    .task {
      if viewModel == nil {
        viewModel = HomeViewModel(repository: repository)
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("أهلًا 👋")
        .font(AppTypography.bodyText)
        .foregroundStyle(Color.appTextSecondary)
      Text(Self.todayLabel())
        .font(AppTypography.screenTitle)
        .foregroundStyle(Color.appTextPrimary)
    }
  }

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
        // النسبة رقم لاتيني — يثبت اتجاهه LTR حتى لا ينقلب داخل RTL.
        .environment(\.layoutDirection, .leftToRight)
    }
    .frame(width: 76, height: 76)
    .accessibilityLabel("تقدم مهام النهارده \(Int((progress * 100).rounded())) بالمئة")
  }

  private static func todayLabel() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ar_EG")
    formatter.dateFormat = "EEEE، d MMMM"
    return formatter.string(from: Date())
  }
}
