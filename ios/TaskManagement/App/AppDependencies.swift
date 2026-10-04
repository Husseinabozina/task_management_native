import Foundation
import SwiftData

/// نقطة تركيب الاعتماديات — مكان واحد صريح عند بدء التطبيق (العقد المعماري).
@MainActor
enum AppDependencies {
  struct Bootstrap {
    let container: ModelContainer
    let repository: LocalDataRepository
    let reminderSync: ReminderSync
  }

  static func bootstrap() -> Result<Bootstrap, RepositoryError> {
    do {
      let schema = Schema([PersistedTask.self, PersistedProject.self])
      let container = try ModelContainer(
        for: schema, configurations: [ModelConfiguration(schema: schema)])
      let repository = LocalDataRepository(container: container)
      let reminderSync = ReminderSync()
      reminderSync.start(repository: repository)
      return .success(
        Bootstrap(container: container, repository: repository, reminderSync: reminderSync))
    } catch {
      return .failure(.storeFailure(error.localizedDescription))
    }
  }
}
