import SwiftUI

/// تمرير المخزن عبر البيئة — تنفيذ واحد حقيقي الآن، والاستهلاك عبر العقود.
private struct AppRepositoryKey: EnvironmentKey {
  static let defaultValue: LocalDataRepository? = nil
}

extension EnvironmentValues {
  var appRepository: LocalDataRepository? {
    get { self[AppRepositoryKey.self] }
    set { self[AppRepositoryKey.self] = newValue }
  }
}
