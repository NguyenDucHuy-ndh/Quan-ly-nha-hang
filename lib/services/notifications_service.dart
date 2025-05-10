import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String ROLE_WAITER = 'waiter';
  static const String ROLE_KITCHEN = 'kitchen';
  static const String ROLE_CASHIER = 'cashier';
  String? _currentRole;

  Future<void> setCurrentRole(String role) async {
    _currentRole = role;
    await _fcm.subscribeToTopic(role);
    _startNotificationListener(); // Start listening after role is set
    print('Set role and subscribed to notifications: $role');
  }

  NotificationService._();

  Future<void> init() async {
    // Khởi tạo local notifications
    await _initLocalNotifications();

    // Yêu cầu quyền thông báo
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Lấy FCM token
    String? token = await _fcm.getToken();
    print('FCM Token: $token');

    // Lắng nghe thông báo mới từ Firestore
    _startNotificationListener();
  }

  void _startNotificationListener() {
    if (_currentRole == null) return;

    _firestore
        .collection('notifications')
        .where('targetRole', isEqualTo: _currentRole)
        .where('status', isEqualTo: 'unread')
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          await _showLocalNotification(
            data['title'] ?? '',
            data['body'] ?? '',
            data,
          );

          // Mark as read
          await change.doc.reference.update(
              {'status': 'read', 'readAt': FieldValue.serverTimestamp()});
        }
      }
    });
  }

  Future<void> _showLocalNotification(
      String title, String body, Map<String, dynamic> payload) async {
    await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'restaurant_orders',
            'Đơn hàng',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: payload.toString());
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification tapped: ${details.payload}');
      },
    );

    // Get the Android-specific plugin
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'restaurant_orders',
          'Đơn hàng',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
    }
  }

  void _setupForegroundNotificationHandling() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got foreground message: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'restaurant_orders',
              'Đơn hàng',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked in background: ${message.data}');
    });
  }

  // Phục vụ gửi đơn mới đến bếp
  Future<void> sendOrderToKitchen(
      {required String tableId,
      required String orderId,
      required List<Map<String, dynamic>> items}) async {
    try {
      // Chỉ lưu vào Firestore
      DocumentReference notifRef =
          await _firestore.collection('notifications').add({
        'type': 'new_order',
        'targetRole': 'kitchen',
        'tableId': tableId,
        'orderId': orderId,
        'items': items,
        'status': 'unread',
        'timestamp': FieldValue.serverTimestamp(),
        'title': 'Đơn hàng mới',
        'body': 'Bàn $tableId vừa đặt ${items.length} món'
      });
      print('Đã lưu thông báo vào Firestore với ID: ${notifRef.id}');
    } catch (e) {
      print('Lỗi khi gửi thông báo: $e');
      throw e;
    }
  }

  // Bếp cập nhật trạng thái món -> thông báo phục vụ
  Future<void> sendOrderStatusUpdate(
      {required String tableId,
      required String orderId,
      required String itemName,
      required String status}) async {
    await _firestore.collection('notifications').add({
      'type': 'status_update',
      'targetRole': 'waiter',
      'tableId': tableId,
      'orderId': orderId,
      'itemName': itemName,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      'title': 'Cập nhật món ăn',
      'body': '$itemName - Bàn $tableId: ${_getStatusText(status)}'
    });
  }

  // Phục vụ gửi yêu cầu thanh toán đến thu ngân
  Future<void> sendPaymentRequest(
      {required String tableId,
      required String orderId,
      required double amount}) async {
    await _firestore.collection('notifications').add({
      'type': 'payment_request',
      'targetRole': 'cashier',
      'tableId': tableId,
      'orderId': orderId,
      'amount': amount,
      'status': 'unread',
      'timestamp': FieldValue.serverTimestamp(),
      'title': 'Yêu cầu thanh toán',
      'body': 'Bàn $tableId yêu cầu thanh toán: ${amount.toStringAsFixed(0)}đ'
    });
  }

  // Subscribe to role-specific notifications
  Future<void> subscribeToRole(String role) async {
    await _fcm.subscribeToTopic(role);
    print('Subscribed to $role notifications');
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'preparing':
        return 'đang chế biến';
      case 'ready':
        return 'đã sẵn sàng';
      default:
        return status;
    }
  }
}
