import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:quanly_nhahang/firebase_options.dart';
import 'package:quanly_nhahang/screens/auth/login_screen.dart';
import 'package:quanly_nhahang/screens/auth/register_screen.dart';
import 'package:quanly_nhahang/screens/home/bottom_navigation_screen.dart';
import 'package:quanly_nhahang/screens/home/order_screen.dart';
import 'package:quanly_nhahang/models/user_model.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/order': (context) => OrderScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final userModel = settings.arguments as UserModel;
          return MaterialPageRoute(
            builder: (context) => BottomNavigationScreen(userModel: userModel),
          );
        }
        return null;
      },
    );
  }
}
