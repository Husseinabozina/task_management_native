import SwiftUI
import UIKit

extension UIColor {
  fileprivate convenience init(appHex: UInt32) {
    self.init(
      red: CGFloat((appHex >> 16) & 0xFF) / 255,
      green: CGFloat((appHex >> 8) & 0xFF) / 255,
      blue: CGFloat(appHex & 0xFF) / 255,
      alpha: 1
    )
  }
}

private func themeColor(light: UInt32, dark: UInt32) -> Color {
  Color(
    uiColor: UIColor { traits in
      traits.userInterfaceStyle == .dark ? UIColor(appHex: dark) : UIColor(appHex: light)
    })
}

private func fixedColor(_ hex: UInt32) -> Color {
  Color(uiColor: UIColor(appHex: hex))
}

/// ألوان الهوية — المصدر: docs/design/DESIGN_SYSTEM.md (فيجما معتمدة، قرار D8).
/// قيم الـ Light حرفية من الفيجما؛ درجات الدارك مشتقة مبدئيًا وتُراجع في أول معاينة بصرية.
extension Color {
  static let appPrimary = themeColor(light: 0x5F33E1, dark: 0x7B52F0)
  static let appBackground = themeColor(light: 0xFFFFFF, dark: 0x161618)
  static let appSurface = themeColor(light: 0xFFFFFF, dark: 0x232326)
  static let appTextPrimary = themeColor(light: 0x24252C, dark: 0xF2F2F2)
  static let appTextSecondary = themeColor(light: 0x6E6A7C, dark: 0xA0A0A8)
  static let appLavender = themeColor(light: 0xEEE9FF, dark: 0x2A2140)
  static let appLavenderAlt = themeColor(light: 0xEDE8FF, dark: 0x2E2447)

  static let appPastelPink = themeColor(light: 0xFFE4F2, dark: 0x3C2433)
  static let appPastelPurple = themeColor(light: 0xEDE4FF, dark: 0x2C2440)
  static let appPastelOrange = themeColor(light: 0xFFE6D4, dark: 0x3D2A1D)
  static let appPastelYellow = themeColor(light: 0xFFF6D4, dark: 0x3B351D)
  static let appPastelBlue = themeColor(light: 0xE7F3FF, dark: 0x1A2B3D)
  static let appPastelPeach = themeColor(light: 0xFFE9E1, dark: 0x3C2921)
  static let appPastelSky = themeColor(light: 0xE3F2FF, dark: 0x1C2C3C)

  static let appTimeText = fixedColor(0xAB94FF)
  static let appStatusTodoText = fixedColor(0x0087FF)
  static let appStatusProgress = fixedColor(0xFF7D53)
  static let appDonutFill = fixedColor(0x8764FF)
  /// لون أخطاء التحقق والحفظ — مش موجود في الفيجما؛ مشتق للوضوح ويُراجع في المعاينة.
  static let appError = fixedColor(0xDC2626)
}
