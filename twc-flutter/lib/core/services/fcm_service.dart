import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'api_service.dart';
import '../../app/constants.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ApiService _api = Get.find<ApiService>();

  Future<void> init() async {
    await _requestPermissions();
    await _setupLocalNotifications();
    await _getToken();
    _setupListeners();
  }

  Future<void> _requestPermissions() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _localNotifications.initialize(settings);
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
    FirebaseMessaging.onMessage.listen(_onMessage);
    _fcm.onTokenRefresh.listen(_sendTokenToServer);
  }

  void _onMessage(RemoteMessage message) {
    print('Message received: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const android = AndroidNotificationDetails(
      'together_we_can_channel',
      'Together We Can',
      channelDescription: 'Notifications Together We Can',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);

    await _localNotifications.show(
      0,
      message.notification?.title ?? 'Together We Can',
      message.notification?.body ?? '',
      details,
    );
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      // Noms de champs alignés sur NotificationController::updateFcmToken (backend Laravel)
      await _api.post('/notifications/fcm-token', data: {
        'device_token': token,
        'device_platform': 'android',
      });
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }
}
