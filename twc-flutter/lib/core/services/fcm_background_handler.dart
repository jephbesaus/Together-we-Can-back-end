import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Show system notification for background messages
  final flutterLocalNotifications = FlutterLocalNotificationsPlugin();

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  const settings = InitializationSettings(android: android, iOS: ios);
  await flutterLocalNotifications.initialize(settings: settings);

  const androidDetails = AndroidNotificationDetails(
    'together_we_can_channel',
    'Together We Can',
    channelDescription: 'Notifications Together We Can',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );
  const iosDetails = DarwinNotificationDetails();
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  await flutterLocalNotifications.show(
    id: message.hashCode,
    title: message.notification?.title ?? 'Together We Can',
    body: message.notification?.body ?? '',
    notificationDetails: details,
  );
}
