import Foundation
import Observation
import Supabase

/// جلسة الحساب — تسجيل دخول/إنشاء حساب بالإيميل (Apple token يُضاف في C2).
@Observable
@MainActor
final class AuthSession {
  private(set) var isSignedIn = false
  private(set) var userEmail: String?
  private(set) var isLoading = false
  private(set) var errorMessage: String?

  private let client: SupabaseClient

  init(client: SupabaseClient) {
    self.client = client
    Task { await restoreSession() }
  }

  func clearError() {
    errorMessage = nil
  }

  func restoreSession() async {
    if let session = try? await client.auth.session {
      apply(session)
    }
  }

  private func apply(_ session: Session) {
    isSignedIn = true
    userEmail = session.user.email
  }

  func signIn(email: String, password: String) async {
    guard !email.isEmpty, !password.isEmpty else {
      errorMessage = "الإيميل وكلمة السر مطلوبين."
      return
    }
    isLoading = true
    defer { isLoading = false }
    do {
      apply(try await client.auth.signIn(email: email, password: password))
      errorMessage = nil
    } catch {
      errorMessage = Self.readable(error)
    }
  }

  func signUp(email: String, password: String) async {
    guard !email.isEmpty, password.count >= 6 else {
      errorMessage = "الإيميل مطلوب وكلمة السر 6 حروف على الأقل."
      return
    }
    isLoading = true
    defer { isLoading = false }
    do {
      let response = try await client.auth.signUp(email: email, password: password)
      if let session = response.session {
        apply(session)
        errorMessage = nil
      } else {
        // Supabase الافتراضي يطلب تأكيد الإيميل قبل الدخول.
        errorMessage = "اتعمل الحساب ✅ — فعّل الإيميل من رسالة التأكيد وبعدها سجّل دخول."
      }
    } catch {
      errorMessage = Self.readable(error)
    }
  }

  func signOut() async {
    try? await client.auth.signOut()
    isSignedIn = false
    userEmail = nil
  }

  static func readable(_ error: Error) -> String {
    let raw = error.localizedDescription
    if raw.contains("Invalid login credentials") { return "الإيميل أو كلمة السر غلط." }
    if raw.contains("already registered") { return "الإيميل ده مسجل قبل كده — سجّل دخول." }
    if raw.contains("Email not confirmed") { return "فعّل الإيميل الأول من رسالة التأكيد." }
    if raw.contains("Internet connection") || raw.contains("network") {
      return "مفيش اتصال إنترنت."
    }
    return "حصلت مشكلة: \(raw)"
  }
}
