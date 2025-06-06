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

  static Future<double> getOrderTotalAmount(String orderId) async {
    final orderDoc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get();

    if (orderDoc.exists) {
      final orderData = orderDoc.data() as Map<String, dynamic>;
      return (orderData['totalAmount'] ?? 0).toDouble();
    }

    return 0.0;
  }

  static Future<void> requestPayment({
    required String tableId,
    required String orderId,
  }) async {
    try {
      // Get current order amount
      final double totalAmount = await getOrderTotalAmount(orderId);

      // Get table name
      final tableDoc = await FirebaseFirestore.instance
          .collection('tables')
          .doc(tableId)
          .get();
      final tableData = tableDoc.data() as Map<String, dynamic>;
      final tableNumber = tableData['tableNumber'] ?? 0;
      final tableName = 'Bàn $tableNumber';

      // Send notification to cashier
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'paymentRequested': true,
        'paymentRequestedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to cashier
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'payment_request',
        'targetRole': 'cashier',
        'tableId': tableId,
        'tableName': tableName, // Thêm tên bàn
        'orderId': orderId,
        'amount': totalAmount,
        'status': 'unread',
        'timestamp': FieldValue.serverTimestamp(),
        'title': 'Yêu cầu thanh toán',
        'body':
            '$tableName yêu cầu thanh toán: ${totalAmount.toStringAsFixed(0)}đ'
      });
    } catch (e) {
      print('Error requesting payment: $e');
      throw e;
    }
  }
}
