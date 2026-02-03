// lib/screens/notification_screen.dart
import 'package:flutter/material.dart';
import '../services/notification_repository.dart';

/// หน้าจอแสดงรายการแจ้งเตือนภายในแอป (in-app notifications)
class NotificationScreen extends StatelessWidget {
  final NotificationRepository repo;

  const NotificationScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    final notifications = repo.getAllNotifications();

    return Scaffold(
      appBar: AppBar(title: const Text("การแจ้งเตือน")),
      body: notifications.isEmpty
          ? const Center(child: Text("ยังไม่มีการแจ้งเตือน"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                final scheduled = n['scheduledTime'];
                final scheduledText = scheduled != null ? scheduled.toString() : null;

                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(n['title'] ?? ''),
                  subtitle: Text(n['body'] ?? ''),
                  trailing: scheduledText != null ? Text(scheduledText) : null,
                );
              },
            ),
    );
  }
}