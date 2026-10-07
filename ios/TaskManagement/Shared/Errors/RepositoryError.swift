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
    case .notFound: return "هذا العنصر غير موجود."
    case .storeFailure(let reason): return "حدثت مشكلة في الحفظ: \(reason)"
    }
  }
}
