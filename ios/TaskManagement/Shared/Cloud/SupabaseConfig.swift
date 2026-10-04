import Foundation
import SwiftUI

/// إعدادات Supabase — تُقرأ من SupabaseConfig.plist المرفق بالتطبيق (غير مرفوع على git).
/// أنشئ نسختك من SupabaseConfig.example.plist (D23 — CLOUD_PLAN.md).
enum SupabaseConfig {
  struct Values {
    let url: URL
    let anonKey: String
  }

  static func load() -> Values? {
    guard let url = Bundle.main.url(forResource: "SupabaseConfig", withExtension: "plist"),
      let data = try? Data(contentsOf: url),
      let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
        as? [String: String],
      let urlString = plist["SUPABASE_URL"],
      let anonKey = plist["SUPABASE_ANON_KEY"],
      let url_ = URL(string: urlString)
    else { return nil }
    return Values(url: url_, anonKey: anonKey)
  }

  static var isConfigured: Bool { load() != nil }
}

/// حزمة خدمات السحابة — nil عندما لا يوجد SupabaseConfig.plist.
@MainActor
struct CloudBundle {
  let auth: AuthSession
  let sync: CloudSyncService
}

private struct CloudBundleKey: EnvironmentKey {
  static let defaultValue: CloudBundle? = nil
}

extension EnvironmentValues {
  var cloudBundle: CloudBundle? {
    get { self[CloudBundleKey.self] }
    set { self[CloudBundleKey.self] = newValue }
  }
}
