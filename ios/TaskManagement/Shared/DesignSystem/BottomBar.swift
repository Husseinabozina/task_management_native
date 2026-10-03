import SwiftUI

enum AppTab: Hashable {
  case home
  case calendar
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
/// 4 تابات حقيقية (قرار D18): الرئيسية + التقويم + مهامي + المشاريع — بنفس مواقع الفيجما.
/// bottomInset = ارتفاع منطقة مؤشر الهوم (يُقاس من الأب) — اللايندر يمتد تحته لآخر الشاشة.
struct BottomBar: View {
  @Binding var selection: AppTab
  let onFab: () -> Void
  var bottomInset: CGFloat = 0

  var body: some View {
    ZStack(alignment: .bottom) {
      // امتداد مستطيل بسيط تحت منطقة مؤشر الهوم.
      Color.appLavender
        .frame(height: bottomInset)
        .frame(maxWidth: .infinity)

      NotchedBarShape()
        .fill(Color.appLavender)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .padding(.bottom, bottomInset)

      // أيقونات التابات على إيقاع الفيجما الحرفي — مراكز LTR الأصلية (44/111/265/331 على 375).
      // في البيئة العربية (RTL) يعكس SwiftUI محور X تلقائيًا في .position فينتاج الترتيب المرآتي الصحيح:
      // home خارجية يمين + تقويم داخلية يمين + [FAB] + مهامي (مستند) داخلية شمال + مشاريع خارجية شمال.
      GeometryReader { geo in
        let w = geo.size.width
        tabButton(.home, icon: "icon_home_bulk", activeIcon: "icon_home_bold")
          .position(x: w * 44 / 375, y: 28)
        tabButton(.calendar, icon: "icon_calendar_bulk", activeIcon: "icon_calendar_bold")
          .position(x: w * 111 / 375, y: 28)
        tabButton(.tasks, icon: "icon_document")
          .position(x: w * 265 / 375, y: 28)
        tabButton(.projects, icon: "icon_briefcase")
          .position(x: w * 331 / 375, y: 28)
      }
      .frame(height: 56)
      .padding(.bottom, bottomInset)

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
      // مركز الـ FAB على الحافة العلوية لشكل الـ notch (فوق امتداد المؤشر).
      .offset(y: -(bottomInset + 34))
      .accessibilityLabel("إضافة مهمة جديدة")
    }
    .frame(height: 78 + bottomInset, alignment: .bottom)
    .animation(.easeOut(duration: 0.15), value: selection)
  }

  private func tabButton(_ tab: AppTab, icon: String, activeIcon: String? = nil) -> some View {
    let isActive = selection == tab
    return Button {
      selection = tab
    } label: {
      Image(isActive ? (activeIcon ?? icon) : icon)
        .resizable()
        .renderingMode(.template)
        .foregroundStyle(isActive ? Color.appPrimary : Color.appTextSecondary)
        .frame(width: 24, height: 24)
        .shadow(
          color: isActive ? Color.appPrimary.opacity(0.35) : .clear,
          radius: 3, x: 0, y: 3
        )
    }
    .accessibilityLabel(
      tab == .home
        ? "الرئيسية" : (tab == .tasks ? "مهامي" : (tab == .calendar ? "التقويم" : "المشاريع"))
    )
  }
}
