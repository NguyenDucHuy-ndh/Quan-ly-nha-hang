import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quanly_nhahang/models/menu_category.dart';
import 'package:quanly_nhahang/models/table.dart' as TableModel;
import 'package:quanly_nhahang/screens/waiter/cart_screen.dart';
import 'package:quanly_nhahang/screens/waiter/menu_items_screen.dart';

class PlaceOrderScreen extends StatefulWidget {
  final TableModel.Table table;
  const PlaceOrderScreen({Key? key, required this.table}) : super(key: key);

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  Stream<DocumentSnapshot>? tableStream;
  Stream<QuerySnapshot>? menuCategoriesStream;
  TableModel.Table? currentTable;
  String? selectedCategoryId;
  Stream<QuerySnapshot>? menuItemsStream;
  int _unreadNotificationsCount = 0;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  @override
  void initState() {
    super.initState();
    // Initialize streams
    menuCategoriesStream = FirebaseFirestore.instance
        .collection('menu_categories')
        .orderBy('order')
        .snapshots();

    currentTable = widget.table;
    tableStream = FirebaseFirestore.instance
        .collection('tables')
        .doc(widget.table.id)
        .snapshots();

    // Kiểm tra thông báo liên quan đến bàn này khi mở màn hình
    _checkTableNotifications();

    // Lắng nghe thông báo mới cho bàn này
    _listenForTableNotifications();
  }

  // Lắng nghe thông báo mới
  void _listenForTableNotifications() {
    final notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('targetRole', isEqualTo: 'waiter')
        .where('tableId', isEqualTo: widget.table.id)
        .where('status', isEqualTo: 'unread')
        .snapshots();

    _notificationSubscription = notificationsStream.listen((snapshot) {
      setState(() {
        _unreadNotificationsCount = snapshot.docs.length;
      });

      // Nếu có thông báo mới, hiển thị snackbar
      if (snapshot.docChanges
          .any((change) => change.type == DocumentChangeType.added)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Có thông báo mới về món ăn!'),
              action: SnackBarAction(
                label: 'Xem',
                onPressed: () {
                  _showTableNotifications(snapshot.docs);
                },
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    // Hủy đăng ký lắng nghe khi widget bị hủy
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // Kiểm tra các thông báo liên quan đến bàn hiện tại
  void _checkTableNotifications() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('targetRole', isEqualTo: 'waiter')
          .where('tableId', isEqualTo: widget.table.id)
          .where('status', isEqualTo: 'unread')
          .get();

      setState(() {
        _unreadNotificationsCount = querySnapshot.docs.length;
      });

      if (querySnapshot.docs.isNotEmpty) {
        // Hiển thị thông báo cho người dùng
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Có ${querySnapshot.docs.length} thông báo mới về món ăn cho bàn này'),
              action: SnackBarAction(
                label: 'Xem',
                onPressed: () {
                  _showTableNotifications(querySnapshot.docs);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Lỗi khi kiểm tra thông báo: $e');
    }
  }

  // Hiển thị danh sách thông báo liên quan đến bàn
  void _showTableNotifications(List<QueryDocumentSnapshot> notifications) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo món ăn'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? 'Thông báo'),
                subtitle: Text(data['body'] ?? ''),
                trailing: Text(
                  _formatTimestamp(data['timestamp'] as Timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  // Đánh dấu thông báo đã đọc
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notifications[index].id)
                      .update({'status': 'read'});

                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Đánh dấu tất cả thông báo đã đọc
              for (var doc in notifications) {
                FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(doc.id)
                    .update({'status': 'read'});
              }
              Navigator.pop(context);
            },
            child: const Text('Đánh dấu tất cả đã đọc'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // Định dạng thời gian cho thông báo
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}';
  }

  Future<void> _updateTableStatus(String tableId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('tables')
        .doc(tableId)
        .update({'status': newStatus});
  }

  // Hàm hiển thị dialog chọn trạng thái
  void _showStatusDialog(BuildContext context, TableModel.Table table) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn trạng thái'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Trống'),
                onTap: () async {
                  await _updateTableStatus(table.id, 'empty');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Đã đặt'),
                onTap: () async {
                  await _updateTableStatus(table.id, 'reserved');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Đang sử dụng'),
                onTap: () async {
                  await _updateTableStatus(table.id, 'occupied');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add these methods
  void _selectCategory(String categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
      menuItemsStream = FirebaseFirestore.instance
          .collection('menu_categories')
          .doc(categoryId)
          .collection('items')
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentTable == null || tableStream == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order món - Bàn ${currentTable!.tableNumber}'),
        actions: [
          // Biểu tượng thông báo với số lượng
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  final querySnapshot = await FirebaseFirestore.instance
                      .collection('notifications')
                      .where('targetRole', isEqualTo: 'waiter')
                      .where('tableId', isEqualTo: currentTable!.id)
                      .where('status', isEqualTo: 'unread')
                      .get();

                  if (mounted) {
                    if (querySnapshot.docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không có thông báo mới')),
                      );
                    } else {
                      _showTableNotifications(querySnapshot.docs);
                    }
                  }
                },
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
          // Giỏ hàng
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(
                    tableId: currentTable!.id,
                    currentOrderId: currentTable!.currentOrderId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: tableStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy thông tin bàn'));
          }

          final tableData = snapshot.data!.data() as Map<String, dynamic>;
          currentTable = TableModel.Table.fromMap(tableData, snapshot.data!.id);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table information section
                _buildTableInfo(),
                const SizedBox(height: 16),

                // Buttons section
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _showStatusDialog(context, currentTable!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Đổi trạng thái'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Menu Categories section
                Text(
                  'Danh mục món ăn:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Categories grid
                Expanded(
                  child: _buildCategoriesGrid(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin bàn:',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('Số bàn: ${currentTable!.tableNumber}'),
        Text('Sức chứa: ${currentTable!.capacity}'),
        Text('Trạng thái: ${currentTable!.status}'),
        if (currentTable!.currentOrderId != null)
          Text('ID đơn hàng hiện tại: ${currentTable!.currentOrderId}'),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: menuCategoriesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Lỗi khi tải danh mục'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data!.docs
            .map((doc) => MenuCategory.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuItemsScreen(
                        category: category,
                        tableId: currentTable!.id,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      category.imageUrl ?? '',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.restaurant_menu, size: 60);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
