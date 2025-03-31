// menu_category.dart
class MenuCategory {
  final String id;
  final String name;
  final int order;
  final String? imageUrl;

  MenuCategory({
    required this.id,
    required this.name,
    required this.order,
    this.imageUrl,
  });

  factory MenuCategory.fromMap(Map<String, dynamic> map, String id) {
    return MenuCategory(
      id: id,
      name: map['name'],
      order: map['order'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'order': order,
      'imageUrl': imageUrl,
    };
  }
}
