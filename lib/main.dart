import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quanly_nhahang/screens/auth/login_screen.dart';
import 'package:quanly_nhahang/screens/auth/register_screen.dart';
import 'package:quanly_nhahang/services/auth_service.dart';
import 'package:quanly_nhahang/widgets/role_based_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng quản lý',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              // Người dùng đã đăng nhập, chuyển hướng đến màn hình dựa trên vai trò
              return RoleBasedScreen();
            } else {
              // Người dùng chưa đăng nhập, chuyển hướng đến màn hình đăng nhập
              return LoginScreen();
            }
          }

          // Đang kiểm tra trạng thái đăng nhập
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => RoleBasedScreen(),
        // Thêm các màn hình khác tại đây
      },
    );
  }
}

// Màn hình kiểm tra quyền truy cập
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return RoleBasedScreen();
          } else {
            return LoginScreen();
          }
        }

        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
