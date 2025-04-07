import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanly_nhahang/models/order.dart' as restaurant_order;
import 'package:quanly_nhahang/models/order_item.dart';

class CartScreen extends StatefulWidget {
  final String tableId;
  final String? currentOrderId;

  const CartScreen({
    Key? key,
    required this.tableId,
    this.currentOrderId,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Stream<QuerySnapshot>? _orderItemsStream;

  @override
  void initState() {
    super.initState();
    if (widget.currentOrderId != null) {
      _orderItemsStream = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.currentOrderId)
          .collection('items')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentOrderId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Giỏ hàng'),
        ),
        body: const Center(
          child: Text('Chưa có món nào được chọn'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _orderItemsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Đã xảy ra lỗi'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final items = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final item = OrderItem.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    );

                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${item.price} đ x ${item.quantity} = ${item.price * item.quantity} đ'),
                            if (item.note != null)
                              Text(
                                'Ghi chú: ${item.note}',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              'Trạng thái: ${_getStatusText(item.status)}',
                              style: TextStyle(
                                color: _getStatusColor(item.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeItem(doc.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .doc(widget.currentOrderId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final orderData = snapshot.data!.data() as Map<String, dynamic>;
                // Thay đổi dòng này trong cart_screen.dart:
                final order = restaurant_order.Order.fromMap(
                    orderData, snapshot.data!.id);

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng cộng:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${order.totalAmount} đ',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'preparing':
        return 'Đang chế biến';
      case 'ready':
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _removeItem(String itemId) async {
    try {
      // Lấy thông tin món để trừ tổng tiền
      final itemDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.currentOrderId)
          .collection('items')
          .doc(itemId)
          .get();

      final itemData = itemDoc.data() as Map<String, dynamic>;
      final price = itemData['price'] as double;
      final quantity = itemData['quantity'] as int;

      // Xóa món
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.currentOrderId)
          .collection('items')
          .doc(itemId)
          .delete();

      // Cập nhật tổng tiền
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.currentOrderId)
          .update({
        'totalAmount': FieldValue.increment(-(price * quantity)),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa món: $e')),
        );
      }
    }
  }
}
