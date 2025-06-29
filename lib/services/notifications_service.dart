import 'dart:ui';

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

          // Không tự động đánh dấu đã đọc để người dùng có thể thấy thông báo trong app
          // Thông báo sẽ được đánh dấu đã đọc khi người dùng tương tác với chúng
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
          channelDescription: 'Thông báo đơn hàng từ phục vụ đến bếp',
          importance: Importance.max,
          priority: Priority.max,
          sound:
              const RawResourceAndroidNotificationSound('notification_sound'),
          playSound: true,
          enableLights: true,
          enableVibration: true,
          ticker: 'Đơn hàng mới',
          color: const Color(0xFF4CAF50),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'notification_sound.wav',
        ),
      ),
      payload: payload.toString(),
    );
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
          description:
              'Thông báo đơn hàng từ phục vụ đến bếp', // Thêm description
          importance: Importance.max, // Đổi từ high thành max
          enableVibration: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(
              'notification_sound'), // Cấu hình âm thanh
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
      // Lấy thông tin tên bàn từ Firestore
      DocumentSnapshot tableDoc =
          await _firestore.collection('tables').doc(tableId).get();
      String tableName = tableDoc.exists
          ? (tableDoc.data() as Map<String, dynamic>)['name'] ??
              'Bàn không xác định'
          : 'Bàn không xác định';

      // Tạo danh sách món ăn chi tiết
      List<String> itemDetails = [];
      for (var item in items) {
        String name = item['name'] ?? 'Không tên';
        int quantity = item['quantity'] ?? 1;
        String note = item['note'] != null && item['note'].toString().isNotEmpty
            ? ' (${item['note']})'
            : '';
        itemDetails.add('$quantity x $name$note');
      }

      // Tạo nội dung thông báo
      String itemsText = itemDetails.join('\n- ');
      String title = 'Đơn hàng mới - $tableName';
      String body = 'Danh sách món:\n- $itemsText';

      // Lưu thông báo vào Firestore
      DocumentReference notifRef =
          await _firestore.collection('notifications').add({
        'type': 'new_order',
        'targetRole': 'kitchen',
        'tableId': tableId,
        'tableName': tableName, // Thêm tên bàn
        'orderId': orderId,
        'items': items,
        'status': 'unread',
        'timestamp': FieldValue.serverTimestamp(),
        'title': title,
        'body': body
      });

      print('Đã lưu thông báo với ID: ${notifRef.id}');
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

  // Thông báo khi món ăn bị xóa
  Future<void> sendItemDeletedNotification(
      {required String tableId,
      required String orderId,
      required String itemName}) async {
    await _firestore.collection('notifications').add({
      'type': 'item_deleted',
      'targetRole': 'kitchen',
      'tableId': tableId,
      'orderId': orderId,
      'itemName': itemName,
      'status': 'unread',
      'timestamp': FieldValue.serverTimestamp(),
      'title': 'Món ăn đã bị xóa',
      'body': '$itemName - Bàn $tableId đã bị xóa khỏi đơn hàng'
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
