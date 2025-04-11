import 'package:flutter/material.dart';
import 'package:quanly_nhahang/screens/cashier/cashier_screen.dart';
import 'package:quanly_nhahang/screens/profile_screen.dart';
import 'package:quanly_nhahang/screens/kitchen/kitchen_screen.dart';
import 'package:quanly_nhahang/screens/order/table_screen.dart';
import 'package:quanly_nhahang/models/user_model.dart';

class BottomNavigationScreen extends StatefulWidget {
  final UserModel userModel;

  const BottomNavigationScreen({Key? key, required this.userModel})
      : super(key: key);
  @override
  _BottomNavigationScreenState createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens; // Thay đổi thành late

  @override
  void initState() {
    super.initState();
    // Khởi tạo _screens trong initState
    _screens = [
      CashierScreen(),
      TableScreen(),
      KitchenScreen(),
      ProfileScreen(userModel: widget.userModel),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Xử lý thông báo
            },
          ),
        ],
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'Cashier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Waiter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Kichen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
