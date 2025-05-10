import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;
  final String targetRole;
  final String tableId;
  final String orderId;
  final List<Map<String, dynamic>> items;
  final String status;
  final DateTime timestamp;
  final String title;
  final String body;

  NotificationModel({
    required this.id,
    required this.type,
    required this.targetRole,
    required this.tableId,
    required this.orderId,
    required this.items,
    required this.status,
    required this.timestamp,
    required this.title,
    required this.body,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'targetRole': targetRole,
      'tableId': tableId,
      'orderId': orderId,
      'items': items,
      'status': status,
      'timestamp': timestamp,
      'title': title,
      'body': body,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      type: map['type'] ?? '',
      targetRole: map['targetRole'] ?? '',
      tableId: map['tableId'] ?? '',
      orderId: map['orderId'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      status: map['status'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
    );
  }
}
