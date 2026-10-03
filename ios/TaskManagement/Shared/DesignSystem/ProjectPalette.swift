import SwiftUI

/// لوحة ألوان المشاريع الثابتة (8 ألوان pastel من الفيجما) — تُخزن كمفتاح نصي لا كقيمة لونية.
enum ProjectPalette: String, CaseIterable, Codable {
  case pink
  case purple
  case orange
  case yellow
  case blue
  case peach
  case sky

  var color: Color {
    switch self {
    case .pink: return .appPastelPink
    case .purple: return .appPastelPurple
    case .orange: return .appPastelOrange
    case .yellow: return .appPastelYellow
    case .blue: return .appPastelBlue
    case .peach: return .appPastelPeach
    case .sky: return .appPastelSky
    }
  }

  static func color(forKey key: String?) -> Color {
    guard let key, let palette = ProjectPalette(rawValue: key) else { return .appPastelPurple }
    return palette.color
  }
}
