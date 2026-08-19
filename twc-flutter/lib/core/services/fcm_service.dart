import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'api_service.dart';
import '../../app/constants.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static int _notificationId = 0;

  final ApiService _api = Get.find<ApiService>();

  Future<void> init() async {
    await _requestPermissions();
    await _setupLocalNotifications();
    await _getToken();
    _setupListeners();
    await _subscribeToTopic('all');
  }

  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('FCM permission: ${settings.authorizationStatus}');
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'together_we_can_channel',
          'Together We Can',
          description: 'Notifications Together We Can',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload);
        final type = data['type'];
        if (type == 'message') {
          Get.toNamed('/messages');
        } else if (type == 'notification') {
          Get.toNamed('/notifications');
        }
      } catch (_) {
        Get.toNamed('/notifications');
      }
    }
  }

  Future<void> _getToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _sendTokenToServer(token);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  void _setupListeners() {
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    _fcm.onTokenRefresh.listen(_sendTokenToServer);
  }

  void _onForegroundMessage(RemoteMessage message) {
    print('FCM foreground: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    print('FCM opened from tap: ${message.data}');
    final data = message.data;
    final type = data['type'];
    if (type == 'message') {
      Get.toNamed('/messages');
    } else if (type == 'notification') {
      Get.toNamed('/notifications');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    _notificationId++;
    final notificationId = _notificationId;

    final type = message.data['type'] ?? 'notification';
    final title = message.notification?.title ?? 'Together We Can';
    final body = message.notification?.body ?? '';

    const android = AndroidNotificationDetails(
      'together_we_can_channel',
      'Together We Can',
      channelDescription: 'Notifications Together We Can',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: android, iOS: ios);

    final payload = jsonEncode({
      'type': type,
      'notification_id': message.data['notification_id'],
    });

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _api.post('/notifications/fcm-token', data: {
        'device_token': token,
        'device_platform': 'android',
      });
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }

  Future<void> _subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }
}
