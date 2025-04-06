import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quanly_nhahang/models/menu_category.dart';
import 'package:quanly_nhahang/models/table.dart' as TableModel;

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  Stream<DocumentSnapshot>? tableStream;
  Stream<QuerySnapshot>? menuCategoriesStream;
  TableModel.Table? currentTable;

  @override
  void initState() {
    super.initState();
    // Initialize streams
    menuCategoriesStream = FirebaseFirestore.instance
        .collection('menu_categories')
        .orderBy('order')
        .snapshots();

    // Get table from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final table =
          ModalRoute.of(context)?.settings.arguments as TableModel.Table?;
      if (table != null) {
        setState(() {
          currentTable = table;
          tableStream = FirebaseFirestore.instance
              .collection('tables')
              .doc(table.id)
              .snapshots();
        });
      }
    });
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
                  print('Selected category: ${category.name}');
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
