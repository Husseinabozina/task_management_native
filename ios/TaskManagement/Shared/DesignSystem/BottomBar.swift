import SwiftUI

enum AppTab: Hashable {
  case home
  case tasks
  case projects
}

/// شكل الشريط السفلي — مستنسخ حرفيًا من SVG الفيجما 101:216 (375×56):
/// رأس دائري 22 + notch منحدر بنعومة في المنتصف يحتضن الـ FAB.
struct NotchedBarShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let sx = rect.width / 375
    let sy = rect.height / 56
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
    }
    path.move(to: p(0, 22))
    path.addCurve(to: p(22, 0), control1: p(0, 9.84974), control2: p(9.84974, 0))
    path.addLine(to: p(154, 0))
    path.addCurve(to: p(187.5, 27), control1: p(164.148, 0), control2: p(162, 27))
    path.addCurve(to: p(220.5, 0), control1: p(214.5, 27), control2: p(210.735, 0))
    path.addLine(to: p(353, 0))
    path.addCurve(to: p(375, 22), control1: p(365.15, 0), control2: p(375, 9.84974))
    path.addLine(to: p(375, 56))
    path.addLine(to: p(0, 56))
    path.closeSubpath()
    return path
  }
}

/// الشريط السفلي — شكل فيجما الحرفي: notch حول FAB دائري 44 بظل بنفسجي.
/// تابات حقيقية فقط (قرار D10/D17): الرئيسية + مهامي + المشاريع.
struct BottomBar: View {
  @Binding var selection: AppTab
  let onFab: () -> Void

  var body: some View {
    ZStack(alignment: .top) {
      NotchedBarShape()
        .fill(Color.appLavender)
        .frame(height: 56)
        .frame(maxWidth: .infinity)

      HStack {
        tabButton(.home, icon: "icon_home_bold")
        Spacer()
        tabButton(.tasks, icon: "icon_calendar_bold")
        Color.clear.frame(width: 64)
        Spacer()
        tabButton(.projects, icon: "icon_briefcase")
      }
      .padding(.horizontal, 44)
      .frame(height: 56)
      .frame(maxWidth: .infinity)

      Button(action: onFab) {
        Image("icon_add")
          .resizable()
          .renderingMode(.template)
          .foregroundStyle(.white)
          .frame(width: 20, height: 20)
          .frame(width: Metrics.fabSize, height: Metrics.fabSize)
          .background(Circle().fill(Color.appPrimary))
          .shadow(color: Color.appPrimary.opacity(0.49), radius: 9, x: 2, y: 10)
      }
      .offset(y: -22)
      .accessibilityLabel("إضافة مهمة جديدة")
    }
    .frame(height: 78)
    .animation(.easeOut(duration: 0.15), value: selection)
  }

  private func tabButton(_ tab: AppTab, icon: String) -> some View {
    Button {
      selection = tab
    } label: {
      Image(icon)
        .resizable()
        .renderingMode(.template)
        .foregroundStyle(selection == tab ? Color.appPrimary : Color.appTextSecondary)
        .frame(width: 24, height: 24)
        .shadow(
          color: selection == tab ? Color.appPrimary.opacity(0.35) : .clear,
          radius: 3, x: 0, y: 3
        )
    }
    .accessibilityLabel(
      tab == .home ? "الرئيسية" : (tab == .tasks ? "مهامي" : "المشاريع")
    )
  }
}
