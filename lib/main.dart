import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quanly_nhahang/firebase_options.dart';
import 'package:quanly_nhahang/screens/auth/login_screen.dart';
import 'package:quanly_nhahang/screens/auth/register_screen.dart';
import 'package:quanly_nhahang/screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Đặt route mặc định
      routes: {
        '/': (context) => const LoginScreen(), // Màn hình đăng nhập
        '/register': (context) => RegisterScreen(), // Màn hình đăng ký
//        '/forgot-password': (context) => ForgotPasswordScreen(), // Màn hình quên mật khẩu
        '/home': (context) => const HomeScreen(), // Màn hình chính
      },
    );
  }
}
