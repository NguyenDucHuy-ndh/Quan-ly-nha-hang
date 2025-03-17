// Widget wrapper để kiểm tra và phân quyền
import 'package:flutter/material.dart';
import 'package:quanly_nhahang/models/user_model.dart';
import 'package:quanly_nhahang/services/auth_service.dart';

class RoleBasedWrapper extends StatelessWidget {
  final Widget ownerWidget;
  final Widget staffWidget;
  final Widget loadingWidget;
  final AuthService authService = AuthService();

  RoleBasedWrapper({
    required this.ownerWidget,
    required this.staffWidget,
    Widget? loadingWidget,
  }) : this.loadingWidget =
            loadingWidget ?? Center(child: CircularProgressIndicator());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget;
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;

          // Phân quyền dựa trên role
          if (user.role == 'owner') {
            return ownerWidget;
          } else if (user.role == 'staff') {
            return staffWidget;
          }
        }

        // Nếu không có dữ liệu hoặc không khớp với role nào
        return Center(
          child: Text('Không có quyền truy cập'),
        );
      },
    );
  }
}

// Widget để quản lý chuyển hướng màn hình dựa trên phân quyền
class RoleBasedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RoleBasedWrapper(
      ownerWidget: OwnerDashboard(),
      staffWidget: StaffDashboard(),
    );
  }
}

// Màn hình dành cho Owner
class OwnerDashboard extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chào mừng, Owner!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Điều hướng đến trang quản lý nhân viên
                Navigator.pushNamed(context, '/manage-staff');
              },
              child: Text('Quản lý nhân viên'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Điều hướng đến trang báo cáo
                Navigator.pushNamed(context, '/reports');
              },
              child: Text('Xem báo cáo'),
            ),
          ],
        ),
      ),
    );
  }
}

// Màn hình dành cho Staff
class StaffDashboard extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chào mừng, Nhân viên!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Điều hướng đến trang công việc
                Navigator.pushNamed(context, '/tasks');
              },
              child: Text('Danh sách công việc'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Điều hướng đến trang hồ sơ
                Navigator.pushNamed(context, '/profile');
              },
              child: Text('Hồ sơ cá nhân'),
            ),
          ],
        ),
      ),
    );
  }
}
