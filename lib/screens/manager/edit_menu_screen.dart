import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quanly_nhahang/models/menu_category.dart';
import 'package:quanly_nhahang/models/menu_item.dart';
import 'package:intl/intl.dart';

class EditMenuScreen extends StatefulWidget {
  const EditMenuScreen({super.key});

  @override
  State<EditMenuScreen> createState() => _EditMenuScreenState();
}

class _EditMenuScreenState extends State<EditMenuScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedCategoryId;

  Future<void> _showAddItemDialog(
      BuildContext context, String categoryId) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm món mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên món',
                  hintText: 'Nhập tên món',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá (VNĐ)',
                  hintText: 'Nhập giá',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Nhập mô tả món ăn',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL hình ảnh (tùy chọn)',
                  hintText: 'Nhập đường dẫn hình ảnh',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin')),
                );
                return;
              }

              try {
                // Thay đổi đường dẫn collection khi thêm món
                await _firestore
                    .collection('menu_categories')
                    .doc(categoryId)
                    .collection('menu_items')
                    .add({
                  'name': nameController.text.trim(),
                  'price': double.parse(priceController.text.trim()),
                  'description': descriptionController.text.trim(),
                  'imageUrl': imageUrlController.text.trim().isEmpty
                      ? null
                      : imageUrlController.text.trim(),
                  'available': true,
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCategoryDialog(
      BuildContext context, MenuCategory category) async {
    final nameController = TextEditingController(text: category.name);
    final orderController =
        TextEditingController(text: category.order.toString());
    final imageUrlController = TextEditingController(text: category.imageUrl);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa danh mục'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên danh mục'),
              ),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(labelText: 'Thứ tự hiển thị'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore
                    .collection('menu_categories')
                    .doc(category.id)
                    .update({
                  'name': nameController.text.trim(),
                  'order': int.parse(orderController.text.trim()),
                  'imageUrl': imageUrlController.text.trim().isEmpty
                      ? null
                      : imageUrlController.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateItemAvailability(
      String categoryId, String itemId, bool available) async {
    try {
      await _firestore
          .collection('menu_categories')
          .doc(categoryId)
          .collection('menu_items')
          .doc(itemId)
          .update({
        'available': available,
      });
    } catch (e) {
      print('Error updating item availability: $e');
    }
  }

  Future<void> _showEditItemDialog(
      BuildContext context, MenuItem item, String categoryId) async {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final descriptionController = TextEditingController(text: item.description);
    final imageUrlController = TextEditingController(text: item.imageUrl);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa món'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên món'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 2,
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore
                    .collection('menu_categories')
                    .doc(categoryId)
                    .collection('menu_items')
                    .doc(item.id)
                    .update({
                  'name': nameController.text.trim(),
                  'price': double.parse(priceController.text.trim()),
                  'description': descriptionController.text.trim(),
                  'imageUrl': imageUrlController.text.trim().isEmpty
                      ? null
                      : imageUrlController.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteItemDialog(
      BuildContext context, MenuItem item, String categoryId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa món "${item.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore
                    .collection('menu_categories')
                    .doc(categoryId)
                    .collection('menu_items')
                    .doc(item.id)
                    .delete();
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Menu'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn hoặc danh mục...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('menu_categories')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!.docs
              .map((doc) => MenuCategory.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .where((category) =>
                  _searchQuery.isEmpty ||
                  category.name.toLowerCase().contains(_searchQuery))
              .toList();

          return ListView.builder(
            itemCount:
                categories.length + 1, // +1 for the "Add Category" button
            itemBuilder: (context, index) {
              if (index == categories.length) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddCategoryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm danh mục mới'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                );
              }

              final category = categories[index];
              return _buildCategoryCard(category);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(MenuCategory category) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        key: Key(category.id),
        initiallyExpanded: category.id == _expandedCategoryId,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedCategoryId = expanded ? category.id : null;
          });
        },
        leading: category.imageUrl != null
            ? CircleAvatar(backgroundImage: NetworkImage(category.imageUrl!))
            : CircleAvatar(child: Text(category.name[0])),
        title: Row(
          children: [
            Expanded(child: Text(category.name)),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () => _showAddItemDialog(context, category.id),
              tooltip: 'Thêm món mới',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditCategoryDialog(context, category),
              tooltip: 'Sửa danh mục',
            ),
          ],
        ),
        subtitle: Text('Thứ tự hiển thị: ${category.order}'),
        children: [
          _buildMenuItemsList(category.id),
        ],
      ),
    );
  }

  Widget _buildMenuItemsList(String categoryId) {
    print("Loading items for category: $categoryId");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('menu_categories')
          .doc(categoryId)
          .collection('menu_items') // Thay đổi đường dẫn collection
          .snapshots(),
      builder: (context, snapshot) {
        print("Connection state: ${snapshot.connectionState}");
        print("Has error: ${snapshot.hasError}");
        print("Has data: ${snapshot.hasData}");

        if (snapshot.hasError) {
          print("Error: ${snapshot.error}");
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          print("Number of documents: ${snapshot.data!.docs.length}");
        }

        final menuItems = snapshot.data!.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              print("Processing document: $data");
              return MenuItem.fromMap(data, doc.id);
            })
            .where((item) =>
                _searchQuery.isEmpty ||
                item.name.toLowerCase().contains(_searchQuery))
            .toList();

        print("Final filtered items: ${menuItems.map((item) => item.name)}");

        if (menuItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Chưa có món ăn nào trong danh mục này'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildMenuItemTile(item, categoryId);
          },
        );
      },
    );
  }

  Widget _buildMenuItemTile(MenuItem item, String categoryId) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: item.imageUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(item.imageUrl!))
          : const CircleAvatar(child: Icon(Icons.fastfood)),
      title: Text(
        item.name,
        style: TextStyle(
          color: item.available ? Colors.black : Colors.grey,
          decoration: item.available ? null : TextDecoration.lineThrough,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currencyFormat.format(item.price)),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: SizedBox(
        width: 140,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 23,
              child: Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: item.available,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.red.withOpacity(0.5),
                  onChanged: (value) =>
                      _updateItemAvailability(categoryId, item.id, value),
                ),
              ),
            ),
            SizedBox(width: 21),
            IconButton(
              iconSize: 23,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditItemDialog(context, item, categoryId),
            ),
            IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteItemDialog(context, item, categoryId),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final orderController = TextEditingController();
    final imageUrlController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm danh mục mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục',
                  hintText: 'Nhập tên danh mục',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Thứ tự hiển thị',
                  hintText: 'Nhập số thứ tự',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL hình ảnh (tùy chọn)',
                  hintText: 'Nhập đường dẫn hình ảnh',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || orderController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin')),
                );
                return;
              }

              try {
                await _firestore.collection('menu_categories').add({
                  'name': nameController.text.trim(),
                  'order': int.parse(orderController.text.trim()),
                  'imageUrl': imageUrlController.text.trim().isEmpty
                      ? null
                      : imageUrlController.text.trim(),
                });
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
