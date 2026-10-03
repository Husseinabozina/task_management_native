import SwiftUI

/// شاشة التقويم — عرض شهري لمهامك (إضافة معتمدة بروح Notion: database calendar view).
/// الديزاين من توكنز مشروعنا (ليس من الفيجما — المرجع لا يحتوي شاشة تقويم) — قرار D18.
struct CalendarScreen: View {
  let repository: LocalDataRepository

  @State private var viewModel: CalendarViewModel?
  @State private var monthAnchor: Date = Date()
  @State private var selectedDay: CalendarDay?

  private let calendar = Calendar.current

  var body: some View {
    VStack(spacing: 14) {
      monthHeader
      weekdayHeader
      monthGrid
    }
    .padding(.horizontal, Metrics.screenPadding)
    // مسافة أسفل الشاشة تفرغ مكان الـ bottom bar (78) + هامش تنفّس.
    .padding(.bottom, 94)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.appBackground)
    .task {
      if viewModel == nil {
        viewModel = CalendarViewModel(repository: repository)
      }
    }
    .navigationDestination(item: $selectedDay) { day in
      TasksScreen(repository: repository, initialDay: day)
        .navigationTitle(Self.dayTitle(for: day))
        .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var monthHeader: some View {
    HStack {
      Button {
        moveMonth(-1)
      } label: {
        Image(systemName: "chevron.right")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(Color.appTextSecondary)
          .frame(width: 34, height: 34)
          .background(
            RoundedRectangle(cornerRadius: Metrics.chipCornerRadius).fill(Color.appLavenderAlt))
      }
      Spacer()
      Text(Self.monthTitle(for: monthAnchor))
        .font(AppTypography.screenTitle)
        .foregroundStyle(Color.appTextPrimary)
      Spacer()
      Button {
        moveMonth(1)
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(Color.appTextSecondary)
          .frame(width: 34, height: 34)
          .background(
            RoundedRectangle(cornerRadius: Metrics.chipCornerRadius).fill(Color.appLavenderAlt))
      }
    }
  }

  private var weekdayHeader: some View {
    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    // رموز الأيام دايمًا تبدأ من الأحد — نلف المصفوفة لتبدأ من أول يوم حسب تقويم الجهاز.
    let rotationIndex = (calendar.firstWeekday - 1) % symbols.count
    let ordered = Array(symbols[rotationIndex...] + symbols[0..<rotationIndex])
    return HStack(spacing: 8) {
      ForEach(ordered, id: \.self) { symbol in
        Text(symbol)
          .font(AppTypography.metadata)
          .foregroundStyle(Color.appTextSecondary)
          .frame(maxWidth: .infinity)
      }
    }
  }

  private var monthGrid: some View {
    let cells = Self.gridDays(for: monthAnchor, calendar: calendar)
    let today = CalendarDay.today()
    return ScrollView {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8)
      {
        ForEach(cells, id: \.self) { day in
          if let day {
            dayCell(day: day, today: today)
          } else {
            Color.clear.frame(height: 56)
          }
        }
      }
    }
  }

  private func dayCell(day: CalendarDay, today: CalendarDay) -> some View {
    let isSelected = selectedDay == day
    let isToday = day == today
    let count = viewModel?.activeCount(on: day) ?? 0
    return Button {
      selectedDay = day
    } label: {
      VStack(spacing: 4) {
        Text(Self.dayNumber(for: day))
          .font(AppTypography.numeralTitle)
          .foregroundStyle(isSelected ? Color.white : Color.appTextPrimary)
        Text(count > 0 ? "\(count)" : " ")
          .font(AppTypography.metadata)
          .foregroundStyle(isSelected ? Color.white : Color.appPrimary)
          .padding(.horizontal, 7)
          .padding(.vertical, 1)
          .background(
            Capsule().fill(isSelected ? Color.white.opacity(0.25) : Color.appLavenderAlt)
          )
          .opacity(count > 0 ? 1 : 0)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(
        RoundedRectangle(cornerRadius: Metrics.chipCornerRadius + 2)
          .fill(isSelected ? Color.appPrimary : Color.appSurface)
      )
      .overlay(
        RoundedRectangle(cornerRadius: Metrics.chipCornerRadius + 2)
          .stroke(isToday && !isSelected ? Color.appPrimary : .clear, lineWidth: 1.5)
      )
      .cardShadow()
    }
    .buttonStyle(.plain)
  }

  private func moveMonth(_ delta: Int) {
    guard let next = calendar.date(byAdding: .month, value: delta, to: monthAnchor) else { return }
    monthAnchor = next
  }

  // MARK: - أدوات الشبكة

  /// خلايا الشهر (42 خلية = 6 أسابيع) مع backfill لبداية الأسبوع حسب تقويم الجهاز — nil = خلية فاضية.
  static func gridDays(for anchor: Date, calendar: Calendar) -> [CalendarDay?] {
    guard let monthInterval = calendar.dateInterval(of: .month, for: anchor) else { return [] }
    let backOffset =
      (calendar.component(.weekday, from: monthInterval.start) - calendar.firstWeekday + 7) % 7
    guard
      let firstCell = calendar.date(byAdding: .day, value: -backOffset, to: monthInterval.start),
      let start = CalendarDay(date: firstCell)
    else { return [] }
    return (0..<42).compactMap { offset in
      calendar.date(byAdding: .day, value: offset, to: start.date).flatMap { CalendarDay(date: $0) }
    }
  }

  private static let arabicFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ar_EG")
    return formatter
  }()

  static func monthTitle(for anchor: Date) -> String {
    arabicFormatter.dateFormat = "MMMM yyyy"
    return arabicFormatter.string(from: anchor)
  }

  static func dayNumber(for day: CalendarDay) -> String {
    arabicFormatter.dateFormat = "d"
    return arabicFormatter.string(from: day.date)
  }

  static func dayTitle(for day: CalendarDay) -> String {
    arabicFormatter.dateFormat = "EEEE، d MMMM"
    return arabicFormatter.string(from: day.date)
  }
}

extension CalendarDay: Identifiable {
  public var id: Date { date }
}
