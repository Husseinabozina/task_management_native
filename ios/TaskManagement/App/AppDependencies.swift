import Foundation
import Supabase
import SwiftData

/// نقطة تركيب الاعتماديات — مكان واحد صريح عند بدء التطبيق (العقد المعماري).
@MainActor
enum AppDependencies {
  struct Bootstrap {
    let container: ModelContainer
    let repository: LocalDataRepository
    let reminderSync: ReminderSync
    let cloud: CloudBundle?
  }

  static func bootstrap() -> Result<Bootstrap, RepositoryError> {
    do {
      let schema = Schema([PersistedTask.self, PersistedProject.self])
      let container = try ModelContainer(
        for: schema, configurations: [ModelConfiguration(schema: schema)])
      let repository = LocalDataRepository(container: container)
      let reminderSync = ReminderSync()
      reminderSync.start(repository: repository)

      var cloud: CloudBundle?
      if let values = SupabaseConfig.load() {
        let client = SupabaseClient(supabaseURL: values.url, supabaseKey: values.anonKey)
        cloud = CloudBundle(
          auth: AuthSession(client: client),
          sync: CloudSyncService(client: client, repository: repository))
      }

      return .success(
        Bootstrap(
          container: container, repository: repository,
          reminderSync: reminderSync, cloud: cloud))
    } catch {
      return .failure(.storeFailure(error.localizedDescription))
    }
  }
}
