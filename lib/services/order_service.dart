import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanly_nhahang/models/order_item.dart';

class OrderService {
  static Future<String> createNewOrder({
    required String tableId,
    required String serverId,
  }) async {
    final orderData = {
      'tableId': tableId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'totalAmount': 0.0,
      'isPaid': false,
      'serverId': serverId,
    };

    final docRef =
        await FirebaseFirestore.instance.collection('orders').add(orderData);

    // Update table with new order ID
    await FirebaseFirestore.instance
        .collection('tables')
        .doc(tableId)
        .update({'currentOrderId': docRef.id});

    return docRef.id;
  }

  static Future<void> addItemToOrder({
    required String orderId,
    required OrderItem item,
  }) async {
    final itemData = item.toMap();

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .collection('items')
        .add(itemData);

    // Update order total amount
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'totalAmount': FieldValue.increment(item.price * item.quantity),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
