import SwiftUI

/// بذرة المحرر: مهمة جديدة (مع يوم اختياري من السياق) أو تعديل مهمة قائمة.
enum TaskEditorSeed: Hashable, Identifiable {
  case new(dueDay: CalendarDay?)
  case edit(TaskItem)

  var id: String {
    switch self {
    case .new(let day): return "new-\(day?.date.timeIntervalSince1970 ?? 0)"
    case .edit(let item): return "edit-\(item.id.uuidString)"
    }
  }
}

/// محرر المهمة — sheet بحقول كروت (نمط فيجما 101:358) وزر primary واحد.
/// الفشل يحفظ draft ويظهر خطأ؛ الإغلاق فقط بعد حفظ مؤكد (العقد).
struct TaskEditorSheet: View {
  let seed: TaskEditorSeed
  let repository: LocalDataRepository

  @Environment(\.dismiss) private var dismiss
  @State private var title = ""
  @State private var details = ""
  @State private var priority: TaskPriority = .normal
  @State private var hasDueDate = false
  @State private var dueDate = Date()
  @State private var isSaving = false
  @State private var errorMessage: String?
  @State private var projects: [ProjectItem] = []
  @State private var selectedProjectId: UUID?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 12) {
          fieldCard(label: "عنوان المهمة") {
            TextField("مثال: أسلّم التقرير", text: $title)
              .font(AppTypography.bodyText)
          }
          fieldCard(label: "الوصف (اختياري)") {
            TextField("تفاصيل المهمة…", text: $details, axis: .vertical)
              .font(AppTypography.bodyText)
              .lineLimit(3...6)
          }
          fieldCard(label: "الأولوية") {
            HStack(spacing: 8) {
              ForEach(TaskPriority.allCases, id: \.rawValue) { value in
                Button {
                  priority = value
                } label: {
                  Text(Self.priorityLabel(for: value))
                    .font(priority == value ? AppTypography.chipSelected : AppTypography.bodyText)
                    .foregroundStyle(priority == value ? Color.white : Color.appPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(
                      RoundedRectangle(cornerRadius: Metrics.chipCornerRadius)
                        .fill(priority == value ? Color.appPrimary : Color.appLavenderAlt)
                    )
                }
                .buttonStyle(.plain)
              }
              Spacer()
            }
          }
          fieldCard(label: "المشروع (اختياري)") {
            Menu {
              Button("بدون مشروع") { selectedProjectId = nil }
              ForEach(projects) { project in
                Button(project.name) { selectedProjectId = project.id }
              }
            } label: {
              HStack {
                Text(Self.projectLabel(id: selectedProjectId, projects: projects))
                  .font(AppTypography.bodyText)
                  .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Image("icon_arrow_down")
                  .resizable()
                  .frame(width: 16, height: 16)
                  .foregroundStyle(Color.appTextSecondary)
              }
            }
          }
          fieldCard(label: "الموعد (اختياري)") {
            Toggle("مهمة بموعد؟", isOn: $hasDueDate)
              .font(AppTypography.bodyText)
              .tint(Color.appPrimary)
            if hasDueDate {
              DatePicker(
                "اليوم",
                selection: $dueDate,
                displayedComponents: [.date]
              )
              .font(AppTypography.bodyText)
              .environment(\.locale, Locale(identifier: "ar_EG"))
            }
          }
          if let errorMessage {
            Text(errorMessage)
              .font(AppTypography.metadata)
              .foregroundStyle(Color.appError)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          PrimaryButton(title: isSaving ? "جاري الحفظ…" : "حفظ") {
            Task { await save() }
          }
          .opacity(isSaving ? 0.6 : 1)
          .padding(.top, 8)
        }
        .padding(.horizontal, Metrics.screenPadding)
        .padding(.vertical, 16)
      }
      .background(Color.appBackground)
      .navigationTitle(editorTitle)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("إلغاء") { dismiss() }
            .font(AppTypography.bodyText)
        }
      }
    }
    .presentationDetents([.large])
    .onAppear(perform: loadSeed)
    .task {
      for await items in repository.observeProjects() {
        projects = items
      }
    }
  }

  private var editorTitle: String {
    if case .edit = seed { return "تعديل المهمة" }
    return "مهمة جديدة"
  }

  private static func projectLabel(id: UUID?, projects: [ProjectItem]) -> String {
    guard let id, let project = projects.first(where: { $0.id == id }) else {
      return "بدون مشروع"
    }
    return (project.emoji ?? "📁") + " " + project.name
  }

  private func loadSeed() {
    switch seed {
    case .new(let day):
      if let day {
        hasDueDate = true
        dueDate = day.date
      }
    case .edit(let item):
      title = item.title
      details = item.details ?? ""
      priority = item.priority
      selectedProjectId = item.projectId
      if let day = item.dueDay {
        hasDueDate = true
        dueDate = day.date
      }
    }
  }

  private func save() async {
    guard !isSaving else { return }
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedTitle.isEmpty else {
      errorMessage = "العنوان مطلوب."
      return
    }
    guard trimmedTitle.count <= 200 else {
      errorMessage = "العنوان أطول من الحد المسموح (200 حرف)."
      return
    }
    let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
    let dueDay = hasDueDate ? CalendarDay(date: dueDate) : nil
    isSaving = true
    defer { isSaving = false }
    do {
      switch seed {
      case .new:
        _ = try repository.create(
          NewTask(
            title: trimmedTitle,
            details: trimmedDetails.isEmpty ? nil : trimmedDetails,
            priority: priority,
            dueDay: dueDay,
            projectId: selectedProjectId
          )
        )
      case .edit(let item):
        _ = try repository.update(
          id: item.id,
          title: trimmedTitle,
          details: trimmedDetails.isEmpty ? nil : trimmedDetails,
          priority: priority,
          dueDay: dueDay,
          projectId: selectedProjectId
        )
      }
      dismiss()
    } catch let error as RepositoryError {
      errorMessage = error.readableDescription
    } catch {
      errorMessage = "حصلت مشكلة غير متوقعة أثناء الحفظ."
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

  private static func priorityLabel(for value: TaskPriority) -> String {
    switch value {
    case .low: return "هادية"
    case .normal: return "عادية"
    case .high: return "مستعجلة"
    }
  }
}
