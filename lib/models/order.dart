// order.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanly_nhahang/models/order_item.dart';

class Order {
  final String id;
  final String tableId;
  final String status; // 'pending', 'preparing', 'completed', 'paid'
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalAmount;
  final bool isPaid;
  final String serverId;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.tableId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.totalAmount,
    required this.isPaid,
    required this.serverId,
    this.items,
  });

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      tableId: map['tableId'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      isPaid: map['isPaid'] ?? false,
      serverId: map['serverId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'totalAmount': totalAmount,
      'isPaid': isPaid,
      'serverId': serverId,
    };
  }
}
