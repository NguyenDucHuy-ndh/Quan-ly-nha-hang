import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanly_nhahang/models/table.dart' as TableModel;
import 'package:quanly_nhahang/screens/waiter/place_order_screen.dart';
import 'package:quanly_nhahang/services/notifications_service.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  bool _isGridView = true;
  int _unreadNotificationsCount = 0;
  Stream<QuerySnapshot>? _notificationsStream;

  // Lấy danh sách bàn từ Firestore
  Stream<List<TableModel.Table>> _getTables() {
    return FirebaseFirestore.instance
        .collection('tables')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return TableModel.Table.fromMap(doc.data(), doc.id);
            }).toList());
  }

  // Hàm xác định màu sắc dựa trên trạng thái bàn
  Color _getStatusColor(String status) {
    switch (status) {
      case 'empty':
        return Colors.green;
      case 'reserved':
        return const Color.fromARGB(255, 233, 150, 6);
      case 'occupied':
        return const Color.fromARGB(255, 214, 53, 41);
      default:
        return Colors.grey;
    }
  }

  // Hàm cập nhật trạng thái bàn trong Firestore
  Future<void> _updateTableStatus(String tableId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('tables')
        .doc(tableId)
        .update({'status': newStatus});
  }

  @override
  void initState() {
    super.initState();
    // Thiết lập role cho NotificationService
    _setupNotifications();
    // Lắng nghe các thông báo mới
    _listenForNotifications();
  }

  Future<void> _setupNotifications() async {
    await NotificationService.instance
        .setCurrentRole(NotificationService.ROLE_WAITER);
  }

  void _listenForNotifications() {
    _notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetRole', isEqualTo: 'waiter')
        .where('status', isEqualTo: 'unread')
        .snapshots();

    _notificationsStream?.listen((snapshot) {
      setState(() {
        _unreadNotificationsCount = snapshot.docs.length;
      });
    });
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
          .where('targetRole', isEqualTo: 'waiter')
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
          .where('targetRole', isEqualTo: 'waiter')
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
                backgroundColor: Colors.blue,
                child: Icon(
                  data['type'] == 'status_update'
                      ? Icons.restaurant_menu
                      : Icons.notifications,
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

                // Nếu là thông báo món ăn đã sẵn sàng, có thể mở chi tiết bàn
                if (data['type'] == 'status_update' &&
                    data['status'] == 'ready') {
                  Navigator.pop(context); // Đóng dialog thông báo
                  _handleReadyItemNotification(data['tableId'] as String);
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

  // Xử lý khi nhấn vào thông báo món ăn đã sẵn sàng
  void _handleReadyItemNotification(String tableId) async {
    try {
      // Lấy thông tin bàn
      final tableDoc = await FirebaseFirestore.instance
          .collection('tables')
          .doc(tableId)
          .get();

      if (!tableDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin bàn')),
        );
        return;
      }

      final table = TableModel.Table.fromMap(
          tableDoc.data() as Map<String, dynamic>, tableId);

      // Chuyển đến màn hình chi tiết bàn
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceOrderScreen(table: table),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Widget _buildGridView(List<TableModel.Table> tables) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return _buildTableCard(table);
      },
    );
  }

  Widget _buildListView(List<TableModel.Table> tables) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: _getStatusColor(table.status),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaceOrderScreen(table: table),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bàn ${table.tableNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tìm order hiện tại cho bàn
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('tableId', isEqualTo: table.id)
                        .where('isPaid', isEqualTo: false)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Text('Lỗi khi tải dữ liệu',
                            style: TextStyle(color: Colors.white));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('Không có đơn hàng',
                            style: TextStyle(color: Colors.white));
                      }

                      final orderDoc = snapshot.data!.docs.first;
                      final orderId = orderDoc.id;

                      // Truy cập subcollection items
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderId)
                            .collection('items')
                            .snapshots(),
                        builder: (context, itemSnapshot) {
                          if (itemSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            );
                          }

                          if (itemSnapshot.hasError) {
                            return const Text('Lỗi khi tải dữ liệu món',
                                style: TextStyle(color: Colors.white));
                          }

                          if (!itemSnapshot.hasData ||
                              itemSnapshot.data!.docs.isEmpty) {
                            return const Text('Không có món',
                                style: TextStyle(color: Colors.white));
                          }

                          // Map để lưu món theo trạng thái
                          Map<String, List<Map<String, dynamic>>>
                              itemsByStatus = {
                            'pending': [],
                            'preparing': [],
                            'ready': [],
                          };

                          // Phân loại từng món theo trạng thái
                          for (var doc in itemSnapshot.data!.docs) {
                            final itemData = doc.data() as Map<String, dynamic>;
                            final status =
                                itemData['status'] as String? ?? 'pending';

                            // Chỉ xử lý các trạng thái đã định nghĩa
                            if (itemsByStatus.containsKey(status)) {
                              itemsByStatus[status]!.add({
                                'name': itemData['name'] ?? 'Món không tên',
                                'quantity': itemData['quantity'] ?? 1,
                              });
                            }
                          }

                          // Kiểm tra tất cả món đã sẵn sàng
                          final bool allItemsReady =
                              itemsByStatus['pending']!.isEmpty &&
                                  itemsByStatus['preparing']!.isEmpty &&
                                  itemsByStatus['ready']!.isNotEmpty;

                          // Hiển thị danh sách các món theo từng trạng thái
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hiển thị món đang chờ
                              if (itemsByStatus['pending']!.isNotEmpty)
                                _buildItemStatusSection(
                                  'Đang chờ',
                                  itemsByStatus['pending']!,
                                  const Color.fromARGB(255, 191, 204, 3),
                                  table.id, // Add tableId
                                  orderId, // Add orderId
                                ),

                              // Hiển thị món đang chế biến
                              if (itemsByStatus['preparing']!.isNotEmpty)
                                _buildItemStatusSection(
                                  'Đang chế biến',
                                  itemsByStatus['preparing']!,
                                  Colors.blue,
                                  table.id, // Add tableId
                                  orderId, // Add orderId
                                ),

                              // Hiển thị món sẵn sàng
                              if (itemsByStatus['ready']!.isNotEmpty)
                                _buildItemStatusSection(
                                  'Sẵn sàng',
                                  itemsByStatus['ready']!,
                                  const Color.fromARGB(255, 237, 19, 219),
                                  table.id, // Add tableId
                                  orderId, // Add orderId
                                ),

                              if (allItemsReady)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      double total = itemSnapshot.data!.docs
                                          .fold(0.0, (sum, doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        return sum +
                                            (data['price'] as num) *
                                                (data['quantity'] as num);
                                      });

                                      await NotificationService.instance
                                          .sendPaymentRequest(
                                        tableId: table.id,
                                        orderId: orderId,
                                        amount: total,
                                      );

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Đã gửi yêu cầu thanh toán')),
                                      );
                                    },
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Yêu cầu thanh toán'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
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
  }

// Widget hiển thị danh sách món theo từng trạng thái
  Widget _buildItemStatusSection(
    String title,
    List<Map<String, dynamic>> items,
    Color color,
    String tableId,
    String orderId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' (${items.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        ...items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '• ${item['name']} (${item['quantity']})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String newStatus) async {
                          await NotificationService.instance
                              .sendOrderStatusUpdate(
                            tableId: tableId,
                            orderId: orderId,
                            itemName: item['name'],
                            status: newStatus,
                          );
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'preparing',
                            child: Text('Đang chế biến'),
                          ),
                          const PopupMenuItem(
                            value: 'ready',
                            child: Text('Sẵn sàng'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildTableCard(TableModel.Table table) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceOrderScreen(table: table),
          ),
        );
      },
      child: Card(
        color: _getStatusColor(table.status),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bàn ${table.tableNumber}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sức chứa: ${table.capacity}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trạng thái: ${table.status}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hiển thị AppBar với thông báo và chuyển đổi chế độ xem
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách bàn'),
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
          // Chuyển đổi chế độ xem
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<TableModel.Table>>(
        stream: _getTables(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có bàn nào'));
          }

          final tables = snapshot.data!;
          return _isGridView ? _buildGridView(tables) : _buildListView(tables);
        },
      ),
    );
  }
}
