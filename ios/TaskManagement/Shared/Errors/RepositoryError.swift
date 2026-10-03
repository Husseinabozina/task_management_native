import Foundation

/// أخطاء عمليات المخزن — العقد يعيد failures معلومة لا استثناءات صامتة.
enum RepositoryError: Error, Equatable {
  case validationFailed(String)
  case notFound
  case storeFailure(String)

  /// رسالة مفهومة للمستخدم دون كشف تفاصيل تقنية خام.
  var readableDescription: String {
    switch self {
    case .validationFailed(let reason): return reason
    case .notFound: return "العنصر ده مش موجود."
    case .storeFailure(let reason): return "حصلت مشكلة في الحفظ: \(reason)"
    }
  }
}
