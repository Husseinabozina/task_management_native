import SwiftUI

/// أدوار الخطوط — المصدر: docs/design/DESIGN_SYSTEM.md.
/// العربي Cairo والاتيني/الأرقام Lexend Deca (قرار D9)، مربوطة بـ Dynamic Type.
enum AppTypography {
  static let heroTitle = Font.custom("Cairo-SemiBold", size: 24, relativeTo: .largeTitle)
  static let screenTitle = Font.custom("Cairo-SemiBold", size: 19, relativeTo: .title3)
  static let sectionTitle = Font.custom("Cairo-SemiBold", size: 19, relativeTo: .title3)
  static let buttonTitle = Font.custom("Cairo-SemiBold", size: 19, relativeTo: .title3)
  static let chipSelected = Font.custom("Cairo-SemiBold", size: 14, relativeTo: .headline)
  static let bodyText = Font.custom("Cairo-Regular", size: 14, relativeTo: .body)
  static let metadata = Font.custom("Cairo-Regular", size: 11, relativeTo: .caption)
  static let fieldLabel = Font.custom("Cairo-Regular", size: 9, relativeTo: .caption2)
  static let statusPill = Font.custom("Cairo-Regular", size: 9, relativeTo: .caption2)
  static let numeral = Font.custom("LexendDeca-Regular", size: 11, relativeTo: .caption)
  static let numeralTitle = Font.custom("LexendDeca-SemiBold", size: 19, relativeTo: .title3)
}
