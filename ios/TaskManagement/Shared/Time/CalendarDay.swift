import Foundation

/// يوم تقويمي بلا ساعة — العقد: dueDate يوم بلا وقت (docs/architecture/DATA_CONTRACTS.md).
/// التطبيع يتم على بداية اليوم وفق تقويم الجهاز لمنع انزلاق اليوم مع المناطق الزمنية.
struct CalendarDay: Hashable, Comparable, Codable {
  /// بداية اليوم في التقويم المحلي.
  let date: Date

  init?(date: Date, calendar: Calendar = .current) {
    guard let start = calendar.dateInterval(of: .day, for: date)?.start else { return nil }
    self.init(unchecked: start)
  }

  private init(unchecked date: Date) {
    self.date = date
  }

  static func today(now: Date = Date(), calendar: Calendar = .current) -> CalendarDay {
    guard let day = CalendarDay(date: now, calendar: calendar) else {
      return CalendarDay(unchecked: now)
    }
    return day
  }

  static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
    lhs.date < rhs.date
  }

  func relation(to other: CalendarDay) -> DayRelation {
    if date < other.date { return .past }
    if date > other.date { return .future }
    return .sameDay
  }
}

enum DayRelation: Hashable {
  case past
  case sameDay
  case future
}
