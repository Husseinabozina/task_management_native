import SwiftUI

/// شاشة البداية «لنبدأ» — تخطيط فيجما 101:100 مع صورة تنظيم مهام جديدة ونصوص فصحى (قرار D26).
/// تظهر لأول تشغيل فقط ثم تفتح الرئيسية مباشرة (قرار D8 + SCREEN_PLAN).
struct EntryScreen: View {
  @Environment(AppSession.self) private var session

  var body: some View {
    GeometryReader { geo in
      ZStack {
        Color.appBackground.ignoresSafeArea()
        DecorativeBlobs(canvas: geo.size)
        VStack(spacing: 0) {
          Spacer()
          Image("onboarding_productivity")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 200)
            .accessibilityHidden(true)
          Text("نظّم يومك\nوأنجز مهامك")
            .font(AppTypography.heroTitle)
            .foregroundStyle(Color.appTextPrimary)
            .multilineTextAlignment(.center)
            .padding(.top, 28)
          Text("نظّم مهامك ومشاريعك في مكان واحد، واجعل كل يوم خطوة نحو أهدافك.")
            .font(AppTypography.bodyText)
            .foregroundStyle(Color.appTextSecondary)
            .multilineTextAlignment(.center)
            .padding(.top, 16)
            .padding(.horizontal, 36)
          Spacer()
          PrimaryButton(title: "لنبدأ") {
            session.completeOnboarding()
          }
          .padding(.horizontal, Metrics.screenPadding)
          .padding(.bottom, 24)
        }
      }
    }
  }
}

/// الفقاعات والنقاط الزخرفية — مواقع وألوان فيجما 101:100 بالظبط، بإحداثيات نسبية لعرض الشاشة.
private struct DecorativeBlobs: View {
  let canvas: CGSize

  /// (x/375، y/812، الحجم، لون الأعلى، شفافية الأسفل)
  private static let blobs:
    [(x: CGFloat, y: CGFloat, size: CGFloat, top: Color, bottomAlpha: Double)] = [
      (333 / 375, 232 / 812, 60, Color(red: 37 / 255, green: 85 / 255, blue: 1), 0.25),
      (76 / 375, 424 / 812, 58, Color(red: 70 / 255, green: 189 / 255, blue: 240 / 255), 0.15),
      (240 / 375, 767 / 812, 58, Color(red: 240 / 255, green: 182 / 255, blue: 70 / 255), 0.15),
      (-15 / 375, 126 / 812, 70, Color(red: 70 / 255, green: 240 / 255, blue: 128 / 255), 0.15),
      (263 / 375, 0 / 812, 70, Color(red: 237 / 255, green: 240 / 255, blue: 70 / 255), 0.15),
    ]

  private static let dots: [(x: CGFloat, y: CGFloat, size: CGFloat, color: Color)] = [
    (250 / 375, 383 / 812, 8, Color(red: 234 / 255, green: 237 / 255, blue: 42 / 255)),
    (138 / 375, 391 / 812, 8, Color(red: 1, green: 215 / 255, blue: 228 / 255)),
    (252 / 375, 73 / 812, 8, Color(red: 146 / 255, green: 222 / 255, blue: 1)),
    (202 / 375, 92 / 812, 4, Color(red: 190 / 255, green: 159 / 255, blue: 1)),
    (281 / 375, 362 / 812, 4, Color(red: 127 / 255, green: 252 / 255, blue: 170 / 255)),
    (176 / 375, 405 / 812, 4, Color(red: 164 / 255, green: 231 / 255, blue: 249 / 255)),
  ]

  var body: some View {
    ZStack {
      ForEach(Array(Self.blobs.enumerated()), id: \.offset) { _, blob in
        Ellipse()
          .fill(
            LinearGradient(
              colors: [blob.top, blob.top.opacity(blob.bottomAlpha)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(width: blob.size, height: blob.size)
          .blur(radius: 25)
          .position(x: canvas.width * blob.x, y: canvas.height * blob.y)
      }
      ForEach(Array(Self.dots.enumerated()), id: \.offset) { _, dot in
        Circle()
          .fill(dot.color)
          .frame(width: dot.size, height: dot.size)
          .position(x: canvas.width * dot.x, y: canvas.height * dot.y)
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}
