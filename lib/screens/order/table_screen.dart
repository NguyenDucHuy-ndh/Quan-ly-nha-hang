import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanly_nhahang/models/order_item.dart';
import 'package:quanly_nhahang/models/table.dart' as TableModel;
import 'package:quanly_nhahang/screens/order/place_order_screen.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  bool _isGridView = true;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý nhà hàng'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list_alt_sharp : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView
                ? 'Chuyển sang dạng danh sách'
                : 'Chuyển sang dạng lưới',
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
            return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có bàn nào.'));
          }

          final tables = snapshot.data!;

          return _isGridView ? _buildGridView(tables) : _buildListView(tables);
        },
      ),
    );
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
                                ),

                              // Hiển thị món đang chế biến
                              if (itemsByStatus['preparing']!.isNotEmpty)
                                _buildItemStatusSection(
                                  'Đang chế biến',
                                  itemsByStatus['preparing']!,
                                  Colors.blue,
                                ),

                              // Hiển thị món sẵn sàng
                              if (itemsByStatus['ready']!.isNotEmpty)
                                _buildItemStatusSection(
                                  'Sẵn sàng',
                                  itemsByStatus['ready']!,
                                  const Color.fromARGB(255, 237, 19, 219),
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
      String title, List<Map<String, dynamic>> items, Color color) {
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
          child: Text(
            title,
            style: const TextStyle(
              color: Color.fromARGB(255, 28, 6, 154),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Text(
                    '• ${item['name']} (${item['quantity']})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
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
}
