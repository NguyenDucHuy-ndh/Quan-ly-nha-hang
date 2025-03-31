import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanly_nhahang/models/table.dart' as TableModel;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        return Colors.yellow;
      case 'occupied':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý nhà hàng'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Đăng xuất'),
              onTap: () {
                // Đăng xuất và điều hướng về màn hình đăng nhập
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
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

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Số cột trong lưới
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5, // Tỷ lệ chiều rộng / chiều cao
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return Card(
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
              );
            },
          );
        },
      ),
    );
  }
}
