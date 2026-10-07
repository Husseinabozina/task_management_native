import SwiftUI

/// صف مهمة — شكل فيجما 101:265: اسم المشروع فوق، العنوان، سطر الموعد،
/// وchip المشروع + pill الحالة على الطرف الآخر.
struct TaskRowView: View {
  let item: TaskItem
  let project: ProjectItem?
  let onOpen: () -> Void
  let onToggleCompletion: () -> Void

  private var isOverdue: Bool {
    guard item.status != .completed, let dueDay = item.dueDay else { return false }
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
          HStack(spacing: 4) {
            if item.isPinned {
              Text("📌")
                .font(AppTypography.metadata)
                .accessibilityLabel("مثبتة")
            }
            Text(item.title)
              .font(AppTypography.bodyText)
              .foregroundStyle(Color.appTextPrimary)
              .multilineTextAlignment(.leading)
              .lineLimit(2)
          }
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
  /// الضغط: غير مكتملة → تتمم (أيا كانت حالتها)؛ مكتملة → تُعاد مفتوحة.
  /// التحويل إلى «شغالة عليها» يتم من المحرر (قرار D20).
  private var statusPill: some View {
    Button(action: onToggleCompletion) {
      Text(Self.statusTitle(for: item.status))
        .font(AppTypography.statusPill)
        .foregroundStyle(Self.statusForeground(for: item.status))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
          Capsule().fill(Self.statusBackground(for: item.status))
        )
    }
    .buttonStyle(.plain)
    .animation(.easeOut(duration: 0.15), value: item.status)
    .accessibilityLabel(item.status == .completed ? "إعادة فتح المهمة" : "إتمام المهمة")
  }

  static func statusTitle(for status: TaskStatus) -> String {
    switch status {
    case .active: return "مفتوحة"
    case .inProgress: return "قيد التنفيذ"
    case .completed: return "مكتملة"
    }
  }

  static func statusForeground(for status: TaskStatus) -> Color {
    switch status {
    case .active: return .appStatusTodoText
    case .inProgress: return .appStatusProgress
    case .completed: return .appPrimary
    }
  }

  static func statusBackground(for status: TaskStatus) -> Color {
    switch status {
    case .active: return .appPastelSky
    case .inProgress: return .appPastelPeach
    case .completed: return .appLavenderAlt
    }
  }

  static func dayLabel(for day: CalendarDay) -> String {
    let today = CalendarDay.today()
    if day == today { return "اليوم" }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ar_EG")
    formatter.dateFormat = "d MMM"
    return formatter.string(from: day.date)
  }
}
