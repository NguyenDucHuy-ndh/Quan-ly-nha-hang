import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quanly_nhahang/models/order.dart' as restaurant_order;
import 'package:quanly_nhahang/models/table.dart' as restaurant_table;
import 'package:quanly_nhahang/models/order_item.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý thanh toán'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.payment), text: 'Chờ thanh toán'),
              Tab(icon: Icon(Icons.done_all), text: 'Đã thanh toán'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList(false),
            _buildOrderList(true),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(bool isPaid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('isPaid', isEqualTo: isPaid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPaid ? Icons.done_all : Icons.payment,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  isPaid
                      ? 'Không có đơn đã thanh toán'
                      : 'Không có đơn chờ thanh toán',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderDoc = orders[index];
            final order = restaurant_order.Order.fromMap(
                orderDoc.data() as Map<String, dynamic>, orderDoc.id);
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildTableInfo(String tableId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tables')
          .doc(tableId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Đang tải...');
        }

        final tableData = snapshot.data!.data() as Map<String, dynamic>;
        final table = restaurant_table.Table.fromMap(tableData, tableId);

        return Row(
          children: [
            const Icon(Icons.table_restaurant, size: 24),
            const SizedBox(width: 8),
            Text(
              'Bàn ${table.tableNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(restaurant_order.Order order) {
    return Card(
      child: InkWell(
        onTap: () => _showPaymentDetails(order),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTableInfo(order.tableId),
              const Divider(),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .doc(order.id)
                    .collection('items')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final items = snapshot.data!.docs;
                  final totalQuantity = items.fold<int>(
                      0,
                      (sum, item) => sum +
                              (item.data() as Map<String, dynamic>)['quantity']
                          as int);

                  return Column(
                    children: [
                      Text(
                        '${items.length} món - $totalQuantity phần',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${order.totalAmount.toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(restaurant_order.Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            PaymentDetailsSheet(order: order),
      ),
    );
  }
}

class PaymentDetailsSheet extends StatefulWidget {
  final restaurant_order.Order order;

  const PaymentDetailsSheet({super.key, required this.order});

  @override
  State<PaymentDetailsSheet> createState() => _PaymentDetailsSheetState();
}

class _PaymentDetailsSheetState extends State<PaymentDetailsSheet> {
  final double vatRate = 0.08; // 8% VAT

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildItemsList()),
        _buildTotalSection(),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tables')
                    .doc(widget.order.tableId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Đang tải...');
                  }
                  final tableData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final table = restaurant_table.Table.fromMap(
                      tableData, widget.order.tableId);
                  return Text(
                    'Bàn ${table.tableNumber}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Thời gian: ${_formatDateTime(widget.order.createdAt)}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .collection('items')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = OrderItem.fromMap(
                items[index].data() as Map<String, dynamic>, items[index].id);
            return ListTile(
              title: Text(item.name),
              subtitle: Text('${item.price}đ x ${item.quantity}'),
              trailing: Text(
                '${(item.price * item.quantity).toStringAsFixed(0)}đ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          _buildTotalRow('Tạm tính:', widget.order.totalAmount),
          _buildTotalRow('VAT (${(vatRate * 100).toStringAsFixed(0)}%):',
              widget.order.totalAmount * vatRate),
          const Divider(),
          _buildTotalRow('Tổng cộng:', widget.order.totalAmount * (1 + vatRate),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              )),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '${amount.toStringAsFixed(0)}đ',
            style: style,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('In hóa đơn'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                // TODO: Implement print functionality
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment),
              label: const Text('Thanh toán'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _processPayment(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    try {
      // Cập nhật trạng thái thanh toán
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.id)
          .update({
        'isPaid': true,
        'paidAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật trạng thái bàn
      await FirebaseFirestore.instance
          .collection('tables')
          .doc(widget.order.tableId)
          .update({
        'status': 'available',
        'currentOrderId': null,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thanh toán: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
