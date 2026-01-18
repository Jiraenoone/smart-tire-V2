import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tire_repair, size: 80, color: Color(0xFFFFD700)),
            SizedBox(height: 24),
            Text(
              'SMART TIRE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
            SizedBox(height: 16),
            Text('กำลังโหลด...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
