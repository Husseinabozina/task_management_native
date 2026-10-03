import Foundation

/// مشروع المنتج — هوية بالإيموجي واللون (قرار D3)، بلا تواريخ في V1 (قرار D12).
struct ProjectItem: Identifiable, Hashable {
  let id: UUID
  var name: String
  var emoji: String?
  /// مفتاح من لوحة الألوان الثابتة — لا قيمة لونية خام هنا.
  var colorKey: String?
  let createdAt: Date
}

struct NewProject: Hashable {
  var name: String
  var emoji: String?
  var colorKey: String?
}
