import SwiftUI

/// صف مهمة — شكل فيجما 101:265: اسم المشروع فوق، العنوان، سطر الموعد،
/// وchip المشروع + pill الحالة على الطرف الآخر.
struct TaskRowView: View {
  let item: TaskItem
  let project: ProjectItem?
  let onOpen: () -> Void
  let onToggleCompletion: () -> Void

  private var isOverdue: Bool {
    guard item.status == .active, let dueDay = item.dueDay else { return false }
    return dueDay < CalendarDay.today()
  }

  var body: some View {
    Button(action: onOpen) {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 5) {
          if let project {
            Text(project.name)
              .font(AppTypography.metadata)
              .foregroundStyle(Color.appTextSecondary)
              .lineLimit(1)
          }
          Text(item.title)
            .font(AppTypography.bodyText)
            .foregroundStyle(Color.appTextPrimary)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
          if let dueDay = item.dueDay {
            HStack(spacing: 4) {
              Image("icon_time_circle")
                .resizable()
                .frame(width: 14, height: 14)
              Text(Self.dayLabel(for: dueDay))
                .font(AppTypography.metadata)
            }
            .foregroundStyle(isOverdue ? Color.appStatusProgress : Color.appTimeText)
          }
        }
        Spacer(minLength: 8)
        VStack(spacing: 6) {
          if let project {
            Text(project.emoji ?? "📁")
              .font(.system(size: 13))
              .frame(width: Metrics.smallIconChipSize, height: Metrics.smallIconChipSize)
              .background(
                RoundedRectangle(cornerRadius: Metrics.smallChipCornerRadius)
                  .fill(ProjectPalette.color(forKey: project.colorKey))
              )
          }
          statusPill
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.appSurface)
      .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
      .cardShadow()
    }
    .buttonStyle(.plain)
  }

  /// pill الحالة هو زر الإتمام/الإعادة — سلوك حقيقي لا زخرفة.
  private var statusPill: some View {
    Button(action: onToggleCompletion) {
      Text(item.status == .active ? "مفتوحة" : "مكتملة")
        .font(AppTypography.statusPill)
        .foregroundStyle(item.status == .active ? Color.appStatusTodoText : Color.appPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
          Capsule().fill(item.status == .active ? Color.appPastelSky : Color.appLavenderAlt)
        )
    }
    .buttonStyle(.plain)
    .animation(.easeOut(duration: 0.15), value: item.status)
    .accessibilityLabel(item.status == .active ? "إتمام المهمة" : "إعادة فتح المهمة")
  }

  static func dayLabel(for day: CalendarDay) -> String {
    let today = CalendarDay.today()
    if day == today { return "النهارده" }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ar_EG")
    formatter.dateFormat = "d MMM"
    return formatter.string(from: day.date)
  }
}
