import SwiftUI

/// شاشة قراءة المهمة — الوصف منسق بـ Markdown + كل البيانات + تعديل وحذف بتأكيد.
/// الضغط على الصف في القوائم يفتحها بدل المحرر؛ التعديل يفتح المحرر منها (SCREEN_PLAN §4).
struct TaskDetailSheet: View {
  let item: TaskItem
  let project: ProjectItem?
  let repository: LocalDataRepository
  /// يستدعى عند ضغط «تعديل» — الشاشة المستدعية تفتح المحرر.
  let onEdit: (TaskItem) -> Void
  let onDeleted: () -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var showDeleteConfirmation = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          statusAndPriority
          titleCard
          if let details = item.details, !details.isEmpty {
            detailsCard(details)
          }
          metadataCard
          if let errorMessage {
            Text(errorMessage)
              .font(AppTypography.metadata)
              .foregroundStyle(Color.appError)
          }
        }
        .padding(.horizontal, Metrics.screenPadding)
        .padding(.vertical, 16)
      }
      .background(Color.appBackground)
      .navigationTitle("تفاصيل المهمة")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            onEdit(item)
          } label: {
            Text("تعديل")
              .font(AppTypography.chipSelected)
              .foregroundStyle(Color.appPrimary)
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button(role: .destructive) {
            showDeleteConfirmation = true
          } label: {
            Image(systemName: "trash")
              .foregroundStyle(Color.appError)
          }
          .accessibilityLabel("حذف المهمة")
        }
      }
      .confirmationDialog(
        "تحب تحذف المهمة؟",
        isPresented: $showDeleteConfirmation,
        titleVisibility: .visible
      ) {
        Button("حذف — مش هترجع تاني", role: .destructive) {
          delete()
        }
        Button("إلغاء", role: .cancel) {}
      } message: {
        Text("«\(item.title)» هتتمسح نهائيًا.")
      }
    }
    .presentationDetents([.large])
  }

  // MARK: - الأجزاء

  private var statusAndPriority: some View {
    HStack(spacing: 8) {
      Text(TaskRowView.statusTitle(for: item.status))
        .font(AppTypography.statusPill)
        .foregroundStyle(TaskRowView.statusForeground(for: item.status))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(TaskRowView.statusBackground(for: item.status)))
      if item.isPinned {
        Text("📌 مثبتة")
          .font(AppTypography.statusPill)
          .foregroundStyle(Color.appTextSecondary)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Capsule().fill(Color.appLavenderAlt))
      }
      if item.priority != .normal {
        Text(Self.priorityLabel(for: item.priority))
          .font(AppTypography.statusPill)
          .foregroundStyle(
            item.priority == .high ? Color.appStatusProgress : Color.appTextSecondary
          )
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(
            Capsule().fill(item.priority == .high ? Color.appPastelPeach : Color.appLavenderAlt))
      }
      Spacer()
    }
  }

  private var titleCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(item.title)
        .font(AppTypography.heroTitle)
        .foregroundStyle(Color.appTextPrimary)
      if let project {
        HStack(spacing: 6) {
          Text(project.emoji ?? "📁")
            .font(.system(size: 13))
          Text(project.name)
            .font(AppTypography.metadata)
            .foregroundStyle(Color.appTextSecondary)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color.appSurface)
    .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
    .cardShadow()
  }

  /// الوصف بـ Markdown-lite: بولد/مائل/كود/روابط — وفشل التحليل يرجع نصًا عاديًا (العقد).
  private func detailsCard(_ details: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("الوصف")
        .font(AppTypography.fieldLabel)
        .foregroundStyle(Color.appTextSecondary)
      Text(Self.attributedDetails(details))
        .font(AppTypography.bodyText)
        .foregroundStyle(Color.appTextPrimary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color.appSurface)
    .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
    .cardShadow()
  }

  private var metadataCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      if let dueDay = item.dueDay {
        metadataRow(label: "الموعد", value: TaskRowView.dayLabel(for: dueDay), isWarning: isOverdue)
      }
      metadataRow(label: "الأولوية", value: Self.priorityLabel(for: item.priority))
      metadataRow(label: "أُنشئت", value: Self.dateLabel(for: item.createdAt))
      metadataRow(label: "آخر تحديث", value: Self.dateLabel(for: item.updatedAt))
      if let completedAt = item.completedAt {
        metadataRow(label: "اِتّمّت", value: Self.dateLabel(for: completedAt))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color.appSurface)
    .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
    .cardShadow()
  }

  private var isOverdue: Bool {
    guard item.status != .completed, let dueDay = item.dueDay else { return false }
    return dueDay < CalendarDay.today()
  }

  private func metadataRow(label: String, value: String, isWarning: Bool = false) -> some View {
    HStack {
      Text(label)
        .font(AppTypography.metadata)
        .foregroundStyle(Color.appTextSecondary)
      Spacer()
      Text(value)
        .font(AppTypography.bodyText)
        .foregroundStyle(isWarning ? Color.appStatusProgress : Color.appTextPrimary)
    }
  }

  // MARK: - الأفعال

  private func delete() {
    do {
      try repository.deleteTask(id: item.id)
      onDeleted()
      dismiss()
    } catch let error as RepositoryError {
      errorMessage = error.readableDescription
    } catch {
      errorMessage = "حصلت مشكلة غير متوقعة أثناء الحذف."
    }
  }

  // MARK: - أدوات

  static func attributedDetails(_ details: String) -> AttributedString {
    do {
      return try AttributedString(
        markdown: details,
        options: AttributedString.MarkdownParsingOptions(
          interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
      )
    } catch {
      return AttributedString(details)
    }
  }

  private static func priorityLabel(for value: TaskPriority) -> String {
    switch value {
    case .low: return "هادية"
    case .normal: return "عادية"
    case .high: return "مستعجلة"
    }
  }

  private static func dateLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ar_EG")
    formatter.dateFormat = "d MMM، h:mm a"
    return formatter.string(from: date)
  }
}
