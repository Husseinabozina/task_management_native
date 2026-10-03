import SwiftUI

/// شكل الزر الأساسي — مستنسخ حرفيًا من SVG الفيجما 101:107 (331×52):
/// الحافة العلوية والسفلية بقوس خفيف بقمّة عند المنتصف — ليس مستطيلًا بسيطًا.
struct PrimaryButtonShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let sx = rect.width / 331
    let sy = rect.height / 52
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
    }
    path.move(to: p(0, 15.724))
    path.addCurve(to: p(13.6924, 1.74208), control1: p(0, 8.10065), control2: p(6.07036, 1.88083))
    path.addCurve(to: p(166, 0), control1: p(43.5021, 1.19944), control2: p(115.638, -0.00983))
    path.addCurve(
      to: p(317.307, 1.74384), control1: p(215.917, 0.00986), control2: p(287.605, 1.20647))
    path.addCurve(
      to: p(330.999, 15.7262), control1: p(324.93, 1.88176), control2: p(330.999, 8.10196))
    path.addLine(to: p(330.999, 36.2737))
    path.addCurve(
      to: p(317.307, 50.2561), control1: p(330.999, 43.8979), control2: p(324.93, 50.1181))
    path.addCurve(to: p(166, 51.9999), control1: p(287.605, 50.7935), control2: p(215.917, 51.9901))
    path.addCurve(
      to: p(13.6924, 50.2578), control1: p(115.638, 52.0098), control2: p(43.5021, 50.8005))
    path.addCurve(to: p(0, 36.2759), control1: p(6.07035, 50.1191), control2: p(0, 43.8993))
    path.closeSubpath()
    return path
  }
}

/// الزر الأساسي الموحد — شكل فيجما الحرفي + توهج (glow) أسفل الزر.
struct PrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(AppTypography.buttonTitle)
      .foregroundStyle(Color.white)
      .frame(maxWidth: .infinity)
      .frame(height: Metrics.buttonHeight)
      .background(Color.appPrimary)
      .clipShape(PrimaryButtonShape())
      .opacity(configuration.isPressed ? 0.85 : 1)
      .scaleEffect(configuration.isPressed ? 0.98 : 1)
      .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
  }
}

struct PrimaryButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Text(title)
        Image("icon_arrow_left")
          .resizable()
          .renderingMode(.template)
          .frame(width: 20, height: 20)
      }
    }
    .buttonStyle(PrimaryButtonStyle())
    .background(alignment: .bottom) {
      Capsule()
        .fill(Color.appPrimary)
        .frame(width: 310, height: 7)
        .blur(radius: 15)
        .offset(y: 24)
    }
  }
}
