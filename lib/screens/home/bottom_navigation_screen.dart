import 'package:flutter/material.dart';
import 'package:quanly_nhahang/screens/cashier/cashier_screen.dart';
import 'package:quanly_nhahang/screens/profile_screen.dart';
import 'package:quanly_nhahang/screens/kitchen/kitchen_screen.dart';
import 'package:quanly_nhahang/screens/waiter/table_screen.dart';
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
  late final List<BottomNavigationBarItem> _navigationItems;

  @override
  void initState() {
    super.initState();
    // Khởi tạo _screens trong initState
    _initializeScreens();
  }

  void _initializeScreens() {
    switch (widget.userModel.role) {
      case 'cashier':
        _screens = [
          CashierScreen(),
          ProfileScreen(userModel: widget.userModel),
        ];
        _navigationItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'Thu Ngân',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ];
        break;

      case 'waiter':
        _screens = [
          TableScreen(),
          ProfileScreen(userModel: widget.userModel),
        ];
        _navigationItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Phục vụ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ];
        break;

      case 'kitchen':
        _screens = [
          KitchenScreen(),
          ProfileScreen(userModel: widget.userModel),
        ];
        _navigationItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Bếp',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ];
        break;

      case 'manager':
        _screens = [
          CashierScreen(),
          TableScreen(),
          KitchenScreen(),
          ProfileScreen(userModel: widget.userModel),
        ];
        _navigationItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'Thu Ngân',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Phục vụ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Bếp',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ];
        break;

      default:
        // Trường hợp mặc định hoặc role không hợp lệ
        _screens = [
          ProfileScreen(userModel: widget.userModel),
        ];
        _navigationItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ];
    }
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
        actions: [],
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
        items: _navigationItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
