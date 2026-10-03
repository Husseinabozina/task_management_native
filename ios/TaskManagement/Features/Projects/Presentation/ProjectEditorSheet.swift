import SwiftUI

/// محرر مشروع جديد — نمط شاشة Add Project (فيجما 101:358): كروت حقول + زر primary.
/// V1 فقط (قرار D12): الاسم + الإيموجي + اللون — بلا تواريخ أو رفع شعار.
struct ProjectEditorSheet: View {
  /// يستدعى مرة عند الحفظ الناجح؛ يعيد رسالة خطأ إن فشل (لا يغلق الـ sheet عند الفشل).
  let onSave: (String, String?, String?) async -> String?
  @Environment(\.dismiss) private var dismiss

  @State private var name = ""
  @State private var emoji: String? = "🚀"
  @State private var colorKey: String? = ProjectPalette.purple.rawValue
  @State private var isSaving = false
  @State private var errorMessage: String?

  private let emojiChoices = ["🚀", "💼", "📚", "🏠", "💪", "🎯", "🎨", "🕌", "🛒", "☕️", "🌱", "💡"]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 12) {
          fieldCard(label: "اسم المشروع") {
            TextField("مثال: مشروع التخرج", text: $name)
              .font(AppTypography.bodyText)
          }
          fieldCard(label: "الأيقونة") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
              ForEach(emojiChoices, id: \.self) { choice in
                Button {
                  emoji = choice
                } label: {
                  Text(choice)
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(
                      RoundedRectangle(cornerRadius: Metrics.chipCornerRadius)
                        .fill(emoji == choice ? Color.appLavender : Color.appBackground)
                    )
                    .overlay(
                      RoundedRectangle(cornerRadius: Metrics.chipCornerRadius)
                        .stroke(
                          emoji == choice ? Color.appPrimary : Color.appLavenderAlt, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
              }
            }
          }
          fieldCard(label: "اللون") {
            HStack(spacing: 10) {
              ForEach(ProjectPalette.allCases, id: \.rawValue) { option in
                Button {
                  colorKey = option.rawValue
                } label: {
                  Circle()
                    .fill(option.color)
                    .frame(width: 30, height: 30)
                    .overlay(
                      Circle().stroke(
                        colorKey == option.rawValue ? Color.appPrimary : .clear,
                        lineWidth: 2
                      )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("لون \(option.rawValue)")
              }
              Spacer()
            }
          }
          if let errorMessage {
            Text(errorMessage)
              .font(AppTypography.metadata)
              .foregroundStyle(Color.appError)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          PrimaryButton(title: isSaving ? "جاري الحفظ…" : "إضافة المشروع") {
            Task { await save() }
          }
          .opacity(isSaving ? 0.6 : 1)
          .padding(.top, 8)
        }
        .padding(.horizontal, Metrics.screenPadding)
        .padding(.vertical, 16)
      }
      .background(Color.appBackground)
      .navigationTitle("مشروع جديد")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("إلغاء") { dismiss() }
            .font(AppTypography.bodyText)
        }
      }
    }
    .presentationDetents([.large])
  }

  private func save() async {
    guard !isSaving else { return }
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      errorMessage = "اسم المشروع مطلوب."
      return
    }
    guard trimmed.count <= 80 else {
      errorMessage = "الاسم أطول من الحد المسموح (80 حرف)."
      return
    }
    isSaving = true
    defer { isSaving = false }
    if let message = await onSave(trimmed, emoji, colorKey) {
      errorMessage = message
    } else {
      dismiss()
    }
  }

  private func fieldCard<Content: View>(
    label: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(AppTypography.fieldLabel)
        .foregroundStyle(Color.appTextSecondary)
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color.appSurface)
    .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
    .cardShadow()
  }
}
