// menu_item.dart
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String? imageUrl;
  final bool available;
  final int preparationTime;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.imageUrl,
    required this.available,
    required this.preparationTime,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map, String id) {
    return MenuItem(
      id: id,
      name: map['name'],
      description: map['description'],
      price: map['price'].toDouble(),
      categoryId: map['categoryId'],
      imageUrl: map['imageUrl'],
      available: map['available'],
      preparationTime: map['preparationTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'available': available,
      'preparationTime': preparationTime,
    };
  }
}
