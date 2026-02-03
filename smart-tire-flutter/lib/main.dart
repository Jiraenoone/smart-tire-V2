// lib/main.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'; // ขอ permission runtime
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) ขอ permission สำหรับการแจ้งเตือน (Android 13+)
  //    ถ้าเป็น platform ที่ไม่รองรับ permission นี้ ผลลัพธ์จะเป็น denied/limited ตาม platform
  final status = await Permission.notification.status;
  if (status.isDenied || status.isRestricted) {
    await Permission.notification.request();
  }

  // 2) เรียก init ของ NotificationService หลังขอ permission เสร็จ
  //    init() จะสร้าง Android channel และ initialize timezone สำหรับ scheduled notifications
  await NotificationService.init();

  // 3) สร้าง AppState ผ่าน Provider และรันแอป
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Tire',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}