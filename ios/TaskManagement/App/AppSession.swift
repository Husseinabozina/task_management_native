import SwiftUI

/// حالة الجلسة العامة: هل اكتملت شاشة البداية؟ تُحفظ محليًا وتُقرأ عند الإقلاع.
@Observable
final class AppSession {
  private static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

  var hasCompletedOnboarding: Bool {
    didSet {
      UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.hasCompletedOnboardingKey)
    }
  }

  init(defaults: UserDefaults = .standard) {
    hasCompletedOnboarding = defaults.bool(forKey: Self.hasCompletedOnboardingKey)
  }

  func completeOnboarding() {
    hasCompletedOnboarding = true
  }
}
