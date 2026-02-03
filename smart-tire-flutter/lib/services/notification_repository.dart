import 'notification_service.dart';

class NotificationRepository {
  final List<Map<String, dynamic>> _notifications = [];

  void addNotification(String title, String body, {DateTime? scheduledTime}) {
    _notifications.add({
      'title': title,
      'body': body,
      'scheduledTime': scheduledTime,
    });

    if (scheduledTime == null) {
      NotificationService.showNotification(title, body);
    } else {
      NotificationService.scheduleNotification(title, body, scheduledTime);
    }
  }

  List<Map<String, dynamic>> getAllNotifications() {
    return _notifications;
  }
}