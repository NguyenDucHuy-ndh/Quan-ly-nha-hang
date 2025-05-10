import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:quanly_nhahang/firebase_options.dart';
import 'package:quanly_nhahang/screens/auth/login_screen.dart';
import 'package:quanly_nhahang/screens/auth/register_screen.dart';
import 'package:quanly_nhahang/screens/home/bottom_navigation_screen.dart';
import 'package:quanly_nhahang/screens/kitchen/kitchen_screen.dart';
import 'package:quanly_nhahang/models/user_model.dart';
import 'package:quanly_nhahang/services/notifications_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService.instance.init();

  // Print FCM token for testing
  String? token = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $token');

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
