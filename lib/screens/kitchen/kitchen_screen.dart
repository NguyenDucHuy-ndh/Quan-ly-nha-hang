import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quanly_nhahang/models/order.dart' as restaurant_order;
import 'package:quanly_nhahang/models/table.dart' as restaurant_table;
import 'package:quanly_nhahang/models/order_item.dart';
import 'package:quanly_nhahang/services/notifications_service.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  late Stream<QuerySnapshot> ordersStream;
  int _unreadNotificationsCount = 0;
  Stream<QuerySnapshot>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    // Lấy các đơn hàng chưa hoàn thành
    ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('status', whereIn: ['pending', 'preparing']).snapshots();

    // Thiết lập role cho NotificationService
    _setupNotifications();
    // Lắng nghe các thông báo mới
    _listenForNotifications();
  }

  Future<void> _setupNotifications() async {
    await NotificationService.instance
        .setCurrentRole(NotificationService.ROLE_KITCHEN);
  }

  void _listenForNotifications() {
    _notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetRole', isEqualTo: 'kitchen')
        .where('status', isEqualTo: 'unread')
        .snapshots();

    _notificationsStream?.listen((snapshot) {
      setState(() {
        _unreadNotificationsCount = snapshot.docs.length;
      });
    });
  }

  Future<void> _updateItemStatus(
      String orderId, String itemId, String newStatus) async {
    try {
      // Get order details
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      final order = restaurant_order.Order.fromMap(
          orderDoc.data() as Map<String, dynamic>, orderId);

      // Get item details
      final itemDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('items')
          .doc(itemId)
          .get();
      final item =
          OrderItem.fromMap(itemDoc.data() as Map<String, dynamic>, itemId);

      // Cập nhật trạng thái của món
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('items')
          .doc(itemId)
          .update({'status': newStatus});

      // Kiểm tra trạng thái của tất cả các món trong order
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('items')
          .get();

      // Xác định trạng thái mới cho order
      String newOrderStatus = 'pending';
      final items = itemsSnapshot.docs;

      if (items.isNotEmpty) {
        bool allReady = true;
        bool anyPreparing = false;

        for (var doc in items) {
          final status = doc.data()['status'] as String;
          if (status != 'ready') {
            allReady = false;
          }
          if (status == 'preparing') {
            anyPreparing = true;
          }
        }

        if (allReady) {
          newOrderStatus = 'ready';
        } else if (anyPreparing) {
          newOrderStatus = 'preparing';
        }
      }

      // Cập nhật trạng thái của order
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newOrderStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Thêm thông báo khi cập nhật trạng thái
      await NotificationService.instance.sendOrderStatusUpdate(
          tableId: order.tableId,
          orderId: orderId,
          itemName: item.name,
          status: newStatus);

      // Nếu món chuyển sang trạng thái hoàn thành, đặt timer để ẩn sau 5 phút
      if (newStatus == 'ready') {
        Future.delayed(const Duration(minutes: 5), () {
          FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .collection('items')
              .doc(itemId)
              .update({'status': 'served'});
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Bếp'),
          actions: [
            // Hiển thị biểu tượng thông báo với số lượng
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => _showNotifications(context),
                ),
                if (_unreadNotificationsCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.access_time),
                text: 'Chờ chế biến',
              ),
              Tab(
                icon: Icon(Icons.restaurant),
                text: 'Đang chế biến',
              ),
              Tab(
                icon: Icon(Icons.check_circle),
                text: 'Hoàn thành',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrderList('pending'),
            _buildOrderList('preparing'),
            _buildOrderList('ready'),
          ],
        ),
      ),
    );
  }

  // Thêm phương thức hiển thị thông báo
  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Thông báo'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thêm nút "Đánh dấu tất cả đã đọc"
                TextButton(
                  onPressed: () {
                    _markAllNotificationsAsRead();
                    Navigator.pop(context);
                  },
                  child: const Text('Đánh dấu tất cả đã đọc'),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: _buildNotificationsList(),
        ),
      ),
    );
  }

  // Phương thức đánh dấu tất cả thông báo là đã đọc
  Future<void> _markAllNotificationsAsRead() async {
    try {
      // Lấy tất cả thông báo chưa đọc
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('targetRole', isEqualTo: 'kitchen')
          .where('status', isEqualTo: 'unread')
          .get();

      // Cập nhật từng thông báo
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tất cả thông báo đã được đánh dấu là đã đọc'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
          ),
        );
      }
    }
  }

  // Widget danh sách thông báo
  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('targetRole', isEqualTo: 'kitchen')
          // Bỏ orderBy để tránh lỗi index
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Không có thông báo nào'),
          );
        }

        // Sắp xếp thông báo ở client, hiển thị mới nhất đầu tiên
        final notifications = snapshot.data!.docs;
        notifications.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimestamp = aData['timestamp'] as Timestamp?;
          final bTimestamp = bData['timestamp'] as Timestamp?;

          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          // Sắp xếp giảm dần (mới nhất trước)
          return bTimestamp.compareTo(aTimestamp);
        });

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final data = notification.data() as Map<String, dynamic>;
            final isUnread = data['status'] == 'unread';

            return ListTile(
              title: Text(
                data['title'] as String? ?? 'Thông báo mới',
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(data['body'] as String? ?? ''),
              leading: CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(
                  Icons.restaurant,
                  color: Colors.white,
                ),
              ),
              trailing: Text(
                _formatTimestamp(data['timestamp'] as Timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: isUnread ? Colors.blue : Colors.grey,
                ),
              ),
              tileColor: isUnread ? Colors.blue.withOpacity(0.1) : null,
              onTap: () {
                // Đánh dấu thông báo là đã đọc
                if (isUnread) {
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notification.id)
                      .update({'status': 'read'});
                }

                // Xử lý thông báo (nếu cần)
                if (data['type'] == 'new_order') {
                  // Xử lý đơn hàng mới
                  _handleNewOrder(data['orderId'] as String);
                }
              },
            );
          },
        );
      },
    );
  }

  // Định dạng thời gian cho thông báo
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}';
  }

  // Xử lý khi thông báo đơn hàng mới
  void _handleNewOrder(String orderId) {
    Navigator.pop(context); // Đóng dialog thông báo

    // Tìm đơn hàng và hiển thị
    FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final order = restaurant_order.Order.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
        _showOrderDetails(order);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy đơn hàng này')),
        );
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải đơn hàng: $error')),
      );
    });
  }

  Widget _buildOrderList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.hasError) {
          return Center(child: Text('Lỗi: ${orderSnapshot.error}'));
        }

        if (!orderSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: orderSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final orderDoc = orderSnapshot.data!.docs[index];
            final order = restaurant_order.Order.fromMap(
                orderDoc.data() as Map<String, dynamic>, orderDoc.id);

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .doc(order.id)
                  .collection('items')
                  .where('status', isEqualTo: status) // Lọc món theo trạng thái
                  .snapshots(),
              builder: (context, itemSnapshot) {
                if (!itemSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final items = itemSnapshot.data!.docs;
                if (items.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () => _showOrderDetails(order),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTableInfo(order.tableId),
                              Text(
                                _formatDateTime(order.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, itemIndex) {
                              final item = OrderItem.fromMap(
                                  items[itemIndex].data()
                                      as Map<String, dynamic>,
                                  items[itemIndex].id);
                              return ListTile(
                                title: Text(item.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Số lượng: ${item.quantity}'),
                                    if (item.note != null &&
                                        item.note!.isNotEmpty)
                                      Text(
                                        'Ghi chú: ${item.note}',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.red,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: _buildStatusUpdateButton(
                                    order.id, items[itemIndex].id, item),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusUpdateButton(
      String orderId, String itemId, OrderItem item) {
    return PopupMenuButton<String>(
      initialValue: item.status,
      onSelected: (String newStatus) =>
          _updateItemStatus(orderId, itemId, newStatus),
      child: Chip(
        avatar: Icon(
          _getStatusIcon(item.status),
          color: Colors.white,
          size: 18,
        ),
        label: Text(
          _getStatusText(item.status),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _getStatusColor(item.status),
      ),
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: 'pending',
          child: Text('Chờ chế biến'),
        ),
        const PopupMenuItem(
          value: 'preparing',
          child: Text('Đang chế biến'),
        ),
        const PopupMenuItem(
          value: 'ready',
          child: Text('Hoàn thành'),
        ),
      ],
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

  void _showOrderDetails(restaurant_order.Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailHeader(order),
              _buildDetailItems(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailHeader(restaurant_order.Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi tiết đơn hàng',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTableInfo(order.tableId),
          const SizedBox(height: 8),
          Text(
            'Thời gian đặt: ${_formatDateTime(order.createdAt)}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItems(restaurant_order.Order order) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .collection('items')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = OrderItem.fromMap(
                items[index].data() as Map<String, dynamic>, items[index].id);
            return _buildDetailItemTile(order.id, items[index].id, item);
          },
        );
      },
    );
  }

  Widget _buildDetailItemTile(String orderId, String itemId, OrderItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Số lượng: ${item.quantity}'),
                      if (item.note != null && item.note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Ghi chú: ${item.note}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusUpdateButton(orderId, itemId, item),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods...
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
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
        return const Color.fromARGB(255, 255, 0, 0);
      case 'preparing':
        return const Color.fromARGB(255, 243, 194, 33);
      case 'ready':
        return const Color.fromARGB(255, 6, 227, 14);
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
