import 'dart:io';
import 'package:flutter/material.dart';
import '../models/tire_data.dart';
import 'add_tire_screen.dart';

class TireDetailScreen extends StatelessWidget {
  final String position;
  final TireData tireData;

  const TireDetailScreen({
    Key? key,
    required this.position,
    required this.tireData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int daysUntilExpiry = tireData.expiryDate.difference(DateTime.now()).inDays;
    bool isExpired = daysUntilExpiry < 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดยาง - ${_getPositionText(position)}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getHealthColor(tireData.healthPercentage),
                    const Color(0xFF1A1A1A),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFFFFD700), width: 4),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${tireData.healthPercentage}%',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _getHealthStatus(tireData.healthPercentage),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('ข้อมูลพื้นฐาน'),
                  _buildDetailCard('เลขซีเรียส', tireData.serialNumber),
                  _buildDetailCard('DOT Code', tireData.dotCode),
                  const SizedBox(height: 24),
                  _buildSectionTitle('สถานะยาง'),
                  _buildDetailCard(
                    'ความลึกดอกยาง',
                    '${tireData.treadDepth.toStringAsFixed(1)} mm',
                    icon: Icons.straighten,
                  ),
                  _buildDetailCard(
                    'กิโลเมตรที่เหลือ',
                    '${tireData.remainingKm.toStringAsFixed(0)} km',
                    icon: Icons.route,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('อายุการใช้งาน'),
                  _buildDetailCard(
                    'วันที่ผลิต',
                    '${tireData.manufactureDate.day}/${tireData.manufactureDate.month}/${tireData.manufactureDate.year + 543}',
                    icon: Icons.calendar_today,
                  ),
                  _buildDetailCard(
                    'อายุการใช้งาน',
                    '${tireData.ageInYears} ปี',
                    icon: Icons.access_time,
                  ),
                  _buildDetailCard(
                    isExpired ? 'หมดอายุแล้ว' : 'หมดอายุใน',
                    isExpired
                        ? '${daysUntilExpiry.abs()} วันที่แล้ว'
                        : '${daysUntilExpiry} วัน',
                    icon: Icons.warning,
                    valueColor: isExpired ? Colors.red : null,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('รูปภาพ'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageCard(
                          'แก้มยาง',
                          tireData.sidewallImagePath,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildImageCard(
                          'ดอกยาง',
                          tireData.treadImagePath,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _remeasure(context, true),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('วัดแก้มยางใหม่'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            backgroundColor: const Color(0xFF2A2A2A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _remeasure(context, false),
                          icon: const Icon(Icons.straighten),
                          label: const Text('วัดดอกยางใหม่'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (tireData.healthPercentage < 50)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 165, 0, 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getRecommendation(tireData.healthPercentage),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFD700),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromRGBO(255, 215, 0, 0.3)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFFFFD700), size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String label, String? imagePath) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromRGBO(255, 215, 0, 0.3)),
            image: imagePath != null && imagePath.isNotEmpty
                ? DecorationImage(
                    image: FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imagePath == null || imagePath.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white30,
                    size: 40,
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Color _getHealthColor(int percentage) {
    if (percentage >= 70) {
      return Colors.green.shade700;
    } else if (percentage >= 40) {
      return Colors.orange.shade700;
    } else {
      return Colors.red.shade700;
    }
  }

  String _getHealthStatus(int percentage) {
    if (percentage >= 70) {
      return 'สภาพดีมาก';
    } else if (percentage >= 40) {
      return 'สภาพปานกลาง';
    } else {
      return 'ควรเปลี่ยนยาง';
    }
  }

  String _getRecommendation(int percentage) {
    if (percentage >= 40 && percentage < 70) {
      return 'แนะนำให้ตรวจสอบยางเป็นประจำและวางแผนเปลี่ยนยางในอนาคตอันใกล้';
    } else if (percentage < 40) {
      return 'ยางของคุณอยู่ในสภาพที่ควรเปลี่ยนโดยเร็วเพื่อความปลอดภัย';
    }
    return '';
  }

  String _getPositionText(String position) {
    switch (position) {
      case 'FL':
        return 'หน้าซ้าย';
      case 'FR':
        return 'หน้าขวา';
      case 'RL':
        return 'หลังซ้าย';
      case 'RR':
        return 'หลังขวา';
      case 'SPARE':
        return 'อะไหล่';
      default:
        return position;
    }
  }

  void _remeasure(BuildContext context, bool isSidewall) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          isSidewall ? 'วัดแก้มยางใหม่' : 'วัดดอกยางใหม่',
          style: const TextStyle(color: Color(0xFFFFD700)),
        ),
        content: Text(
          isSidewall
              ? 'คุณต้องการวัดแก้มยางใหม่หรือไม่? ข้อมูลเก่าจะถูกแทนที่'
              : 'คุณต้องการวัดดอกยางใหม่หรือไม่? ข้อมูลเก่าจะถูกแทนที่',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTireScreen(position: position),
                ),
              );
            },
            child: const Text('ยืนยัน',
                style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
}
