import SwiftUI

/// شاشة الحساب والمزامنة — تُفتح من أيقونة السحابة في رأس الرئيسية.
/// بدون SupabaseConfig.plist: تعرض حالة إعداد صادقة بخطواتها (لا أزرار ميتة).
struct AccountSheet: View {
  let bundle: CloudBundle?
  let repository: LocalDataRepository

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Group {
        if let bundle {
          if bundle.auth.isSignedIn {
            SignedInView(auth: bundle.auth, sync: bundle.sync)
          } else {
            AuthFormView(auth: bundle.auth)
          }
        } else {
          setupNeededView
        }
      }
      .navigationTitle("الحساب والمزامنة")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("إغلاق") { dismiss() }
            .font(AppTypography.bodyText)
        }
      }

    }
    .presentationDetents([.large])
  }

  /// الحالة الصادقة لما الإعدادات ناقصة — خطوات واضحة لا رسالة غامضة.
  private var setupNeededView: some View {
    VStack(alignment: .leading, spacing: 14) {
      Label("السحابة مش مضبوطة على النسخة دي", systemImage: "cloud.slash")
        .font(AppTypography.screenTitle)
        .foregroundStyle(Color.appTextPrimary)
      VStack(alignment: .leading, spacing: 10) {
        Self.step("1", "اعمل مشروع على supabase.com (بلان مجاني)")
        Self.step("2", "شغّل ملف docs/supabase/schema.sql في SQL Editor بتاع المشروع")
        Self.step("3", "انسخ Project URL و anon key من Settings ← API")
        Self.step(
          "4",
          "انسخ SupabaseConfig.example.plist وسمّه SupabaseConfig.plist واملأ القيمتين، وبعدها ⌘R")
      }
      .font(AppTypography.bodyText)
      .foregroundStyle(Color.appTextPrimary)
      Text("التفاصيل كاملة في docs/supabase/SETUP.md جوه المشروع.")
        .font(AppTypography.metadata)
        .foregroundStyle(Color.appTextSecondary)
      Spacer()
    }
    .padding(Metrics.screenPadding)
    .background(Color.appBackground)
  }

  private static func step(_ number: String, _ text: String) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Text(number)
        .font(AppTypography.numeral)
        .foregroundStyle(Color.white)
        .frame(width: 22, height: 22)
        .background(Circle().fill(Color.appPrimary))
      Text(text)
        .font(AppTypography.bodyText)
        .foregroundStyle(Color.appTextPrimary)
    }
  }
}

/// نموذج الدخول/إنشاء الحساب.
struct AuthFormView: View {
  let auth: AuthSession

  @State private var mode: Mode = .signIn
  @State private var email = ""
  @State private var password = ""

  enum Mode: String, CaseIterable {
    case signIn = "دخول"
    case signUp = "حساب جديد"
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        HStack(spacing: 8) {
          ForEach(Mode.allCases, id: \.rawValue) { value in
            Button {
              mode = value
              auth.clearError()
            } label: {
              Text(value.rawValue)
                .font(mode == value ? AppTypography.chipSelected : AppTypography.bodyText)
                .foregroundStyle(mode == value ? Color.white : Color.appPrimary)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(
                  RoundedRectangle(cornerRadius: Metrics.chipCornerRadius)
                    .fill(mode == value ? Color.appPrimary : Color.appLavenderAlt)
                )
            }
            .buttonStyle(.plain)
          }
          Spacer()
        }
        fieldCard("الإيميل", text: $email)
        fieldCard("كلمة السر", text: $password, secure: true)
        if let message = auth.errorMessage {
          Text(message)
            .font(AppTypography.metadata)
            .foregroundStyle(Color.appError)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        PrimaryButton(title: auth.isLoading ? "لحظة…" : mode.rawValue) {
          Task {
            if mode == .signIn {
              await auth.signIn(email: email, password: password)
            } else {
              await auth.signUp(email: email, password: password)
            }
          }
        }
        .opacity(auth.isLoading ? 0.6 : 1)
        .disabled(auth.isLoading)
      }
      .padding(Metrics.screenPadding)
    }
    .background(Color.appBackground)
  }

  private func fieldCard(_ label: String, text: Binding<String>, secure: Bool = false) -> some View
  {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(AppTypography.fieldLabel)
        .foregroundStyle(Color.appTextSecondary)
      if secure {
        SecureField("••••••", text: text)
          .font(AppTypography.bodyText)
      } else {
        TextField("name@example.com", text: text)
          .font(AppTypography.bodyText)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color.appSurface)
    .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
    .cardShadow()
  }
}

/// الحالة المسجلة: بيانات الحساب + مزامنة الآن + خروج.
struct SignedInView: View {
  let auth: AuthSession
  let sync: CloudSyncService
  @Environment(AppSession.self) private var session
  @Environment(\.dismiss) private var dismiss
  @State private var showReplayConfirm = false

  var body: some View {
    ScrollView {
      VStack(spacing: 14) {
        HStack {
          Image(systemName: "person.crop.circle.fill")
            .font(.system(size: 40))
            .foregroundStyle(Color.appPrimary)
          VStack(alignment: .leading, spacing: 2) {
            Text(auth.userEmail ?? "حسابك")
              .font(AppTypography.chipSelected)
              .foregroundStyle(Color.appTextPrimary)
              .lineLimit(1)
            if let last = sync.lastSyncAt {
              Text("آخر مزامنة: \(Self.dateLabel(last))")
                .font(AppTypography.metadata)
                .foregroundStyle(Color.appTextSecondary)
            } else {
              Text("لسه متزامنتش — أول مزامنة هتعمل نسخة احتياطية لبياناتك")
                .font(AppTypography.metadata)
                .foregroundStyle(Color.appTextSecondary)
            }
          }
          Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardCornerRadius))
        .cardShadow()

        if let error = sync.lastError {
          Text(error)
            .font(AppTypography.metadata)
            .foregroundStyle(Color.appError)
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        PrimaryButton(title: sync.isSyncing ? "جاري المزامنة…" : "مزامنة الآن") {
          Task { await sync.syncNow() }
        }
        .opacity(sync.isSyncing ? 0.6 : 1)
        .disabled(sync.isSyncing)

        Text(
          "بياناتك محفوظة محليًا الأول — المزامنة بتنقلها للسحابة بمعرف موثوق، وأول مزامنة بتعمل نسخة احتياطية تلقائيًا."
        )
        .font(AppTypography.metadata)
        .foregroundStyle(Color.appTextSecondary)

        Button(role: .destructive) {
          Task { await auth.signOut() }
        } label: {
          Text("تسجيل الخروج")
            .font(AppTypography.bodyText)
            .foregroundStyle(Color.appError)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
              RoundedRectangle(cornerRadius: Metrics.cardCornerRadius).fill(Color.appPastelPeach))
        }
        .buttonStyle(.plain)
      }
      .padding(Metrics.screenPadding)
    }
    .background(Color.appBackground)
  }

  private static func dateLabel(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ar_EG")
    formatter.dateFormat = "EEE d MMM، h:mm a"
    return formatter.string(from: date)
  }
}
