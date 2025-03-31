// order_item.dart
class OrderItem {
  final String? id;
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? note;
  final String status; // 'pending', 'preparing', 'ready'

  OrderItem({
    this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.note,
    required this.status,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map, String id) {
    return OrderItem(
      id: id,
      menuItemId: map['menuItemId'],
      name: map['name'],
      price: map['price'].toDouble(),
      quantity: map['quantity'],
      note: map['note'],
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'note': note,
      'status': status,
    };
  }
}
