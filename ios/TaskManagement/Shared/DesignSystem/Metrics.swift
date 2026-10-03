import SwiftUI

/// مقاسات وأشكال ثابتة — المصدر: docs/design/DESIGN_SYSTEM.md.
enum Metrics {
  static let buttonCornerRadius: CGFloat = 14
  static let cardCornerRadius: CGFloat = 15
  static let heroCardCornerRadius: CGFloat = 24
  static let secondaryCardCornerRadius: CGFloat = 19
  static let chipCornerRadius: CGFloat = 9
  static let smallChipCornerRadius: CGFloat = 7
  static let tabBarTopCornerRadius: CGFloat = 22

  static let buttonHeight: CGFloat = 52
  static let fabSize: CGFloat = 44
  static let iconChipSize: CGFloat = 34
  static let smallIconChipSize: CGFloat = 24
  static let screenPadding: CGFloat = 22
}

/// ظل الكارت من الفيجما: 0 4 32 rgba(0,0,0,0.04) — نصف قطر الظل في SwiftUI = blur/2.
struct CardShadow: ViewModifier {
  func body(content: Content) -> some View {
    content.shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 4)
  }
}

extension View {
  func cardShadow() -> some View {
    modifier(CardShadow())
  }
}
