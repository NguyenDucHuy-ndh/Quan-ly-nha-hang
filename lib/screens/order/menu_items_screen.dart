import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanly_nhahang/models/menu_category.dart';
import 'package:quanly_nhahang/models/menu_item.dart';
import 'package:quanly_nhahang/models/order_item.dart';
import 'package:quanly_nhahang/services/order_service.dart';

class MenuItemsScreen extends StatefulWidget {
  final MenuCategory category;
  final String tableId;

  const MenuItemsScreen({
    Key? key,
    required this.category,
    required this.tableId,
  }) : super(key: key);

  @override
  State<MenuItemsScreen> createState() => _MenuItemsScreenState();
}

class _MenuItemsScreenState extends State<MenuItemsScreen> {
  // Lưu số lượng của từng món
  final Map<String, int> _quantities = {};
  final Map<String, String> _notes = {};
  final Map<String, MenuItem> _menuItems = {};
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<QueryDocumentSnapshot> _allItems = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNoteDialog(MenuItem item) {
    final textController = TextEditingController(text: _notes[item.id]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ghi chú cho ${item.name}'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Nhập ghi chú...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (textController.text.isNotEmpty) {
                  _notes[item.id] = textController.text;
                } else {
                  _notes.remove(item.id);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _addToOrder() async {
    try {
      setState(() => _isLoading = true);

      // Lấy hoặc tạo order mới
      String? orderId; // Thay đổi kiểu thành String?
      final tableDoc = await FirebaseFirestore.instance
          .collection('tables')
          .doc(widget.tableId)
          .get();

      final tableData = tableDoc.data() as Map<String, dynamic>;
      orderId = tableData['currentOrderId'] as String?; // Ép kiểu an toàn

      if (orderId == null) {
        orderId = await OrderService.createNewOrder(
          tableId: widget.tableId,
          serverId: 'current_server_id', // Thay bằng ID của nhân viên hiện tại
        );
      }

      // Thêm từng món vào order
      for (final entry in _quantities.entries) {
        final item = _menuItems[entry.key]!;
        final orderItem = OrderItem(
          menuItemId: item.id!,
          name: item.name,
          price: item.price,
          quantity: entry.value,
          note: _notes[item.id],
          status: 'pending',
        );

        await OrderService.addItemToOrder(
          orderId: orderId, // Bây giờ orderId chắc chắn có giá trị
          item: orderItem,
        );
      }

      // Hiển thị thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm món vào đơn hàng')),
        );
        // Xóa các món đã thêm
        setState(() {
          _quantities.clear();
          _notes.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm món ăn...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('menu_categories')
                      .doc(widget.category.id)
                      .collection('menu_items')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Đã xảy ra lỗi'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    _allItems = snapshot.data!.docs;
                    final filteredItems = _allItems.where((doc) {
                      final item = MenuItem.fromMap(
                          doc.data() as Map<String, dynamic>, doc.id);
                      return item.name.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredItems.isEmpty) {
                      return const Center(
                        child: Text(
                          'Không tìm thấy món ăn',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final doc = filteredItems[index];
                        final item = MenuItem.fromMap(
                            doc.data() as Map<String, dynamic>, doc.id);
                        _menuItems[item.id!] = item;

                        return Card(
                          child: Column(
                            children: [
                              ListTile(
                                enabled: item.available, // Disable nếu hết hàng
                                leading: Image.network(
                                  item.imageUrl ?? '',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.fastfood, size: 56);
                                  },
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        color: !item.available
                                            ? Colors.grey
                                            : null,
                                      ),
                                    ),
                                    if (!item.available)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(color: Colors.red),
                                        ),
                                        child: const Text(
                                          'Hết hàng',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${item.price} đ'),
                                    if (_notes[item.id] != null)
                                      Text(
                                        'Ghi chú: ${_notes[item.id]}',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: !item.available
                                          ? null
                                          : (_quantities[item.id] != null &&
                                                  _quantities[item.id]! > 0
                                              ? () =>
                                                  _updateQuantity(item.id, -1)
                                              : null),
                                    ),
                                    Text(
                                      '${_quantities[item.id] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: !item.available
                                            ? Colors.grey
                                            : null,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: !item.available
                                          ? null
                                          : () => _updateQuantity(item.id, 1),
                                    ),
                                  ],
                                ),
                              ),
                              if (_quantities[item.id] != null &&
                                  _quantities[item.id]! > 0)
                                ButtonBar(
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.note_add),
                                      label: const Text('Thêm ghi chú'),
                                      onPressed: () => _showNoteDialog(item),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_quantities.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Text(
                        'Tổng số món: ${_quantities.values.fold(0, (sum, quantity) => sum + quantity)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _addToOrder,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Thêm vào đơn hàng'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _updateQuantity(String itemId, int delta) {
    setState(() {
      _quantities[itemId] = (_quantities[itemId] ?? 0) + delta;
      if (_quantities[itemId] == 0) {
        _quantities.remove(itemId);
      }
    });
  }
}
