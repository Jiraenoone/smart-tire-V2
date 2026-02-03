import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'smart_tire_channel';
  static const String channelName = 'Smart Tire Alerts';

  static Future<void> init() async {
    // timezone สำหรับ scheduled notifications
    tz.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization (request permission already handled in main)
    final DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    // สร้าง Android notification channel (สำคัญ)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'การแจ้งเตือนสำคัญจาก Smart Tire',
        importance: Importance.max,
        playSound: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  static Future<void> showNotification(String title, String body) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  static Future<void> scheduleNotification(
      String title, String body, DateTime scheduledTime) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}