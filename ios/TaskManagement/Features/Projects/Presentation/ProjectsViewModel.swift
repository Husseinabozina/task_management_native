import Foundation
import Observation

/// حالة شاشة المشاريع — تراقب المشاريع والمهام وتحسب الإحصاءات الحقيقية.
@Observable
@MainActor
final class ProjectsViewModel {
  private(set) var projects: [ProjectItem] = []
  private(set) var isLoading = true
  private var allTasks: [TaskItem] = []

  private let repository: LocalDataRepository
  private var observationTasks: [Task<Void, Never>] = []

  init(repository: LocalDataRepository) {
    self.repository = repository
    observe()
  }

  /// عدد المهام غير المكتملة لكل مشروع (مفتوحة + شغالة عليها).
  func activeCount(for projectId: UUID) -> Int {
    allTasks.filter { $0.projectId == projectId && $0.status != .completed }.count
  }

  /// نسبة الإنجاز الحقيقية لكل مشروع: المكتمل ÷ الإجمالي.
  func progress(for projectId: UUID) -> Double {
    let projectTasks = allTasks.filter { $0.projectId == projectId }
    guard !projectTasks.isEmpty else { return 0 }
    let done = projectTasks.filter { $0.status == .completed }.count
    return Double(done) / Double(projectTasks.count)
  }

  func createProject(name: String, emoji: String?, colorKey: String?) async -> String? {
    do {
      _ = try repository.createProject(NewProject(name: name, emoji: emoji, colorKey: colorKey))
      return nil
    } catch let error as RepositoryError {
      return error.readableDescription
    } catch {
      return "حدثت مشكلة غير متوقعة أثناء الحفظ."
    }
  }

  /// الحذف ينقل مهام المشروع إلى «بدون مشروع» (العقد) — الواجهة تؤكد قبل الاستدعاء.
  func deleteProject(_ project: ProjectItem) async -> String? {
    do {
      try repository.deleteProject(id: project.id)
      return nil
    } catch let error as RepositoryError {
      return error.readableDescription
    } catch {
      return "حدثت مشكلة غير متوقعة أثناء الحذف."
    }
  }

  private func observe() {
    observationTasks.append(
      Task { [weak self] in
        guard let stream = self?.repository.observeProjects() else { return }
        for await items in stream {
          guard let self, !Task.isCancelled else { break }
          self.projects = items
          self.isLoading = false
        }
      })
    observationTasks.append(
      Task { [weak self] in
        guard let stream = self?.repository.observeTasks(TaskQuery()) else { return }
        for await items in stream {
          guard let self, !Task.isCancelled else { break }
          self.allTasks = items
        }
      })
  }
}
