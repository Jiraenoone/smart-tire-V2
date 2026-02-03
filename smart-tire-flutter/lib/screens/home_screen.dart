// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../models/tire_data.dart';
import '../models/vehicle.dart';
import '../services/swap_tire.dart';
import '../services/notification_repository.dart';
import 'tire_detail_screen.dart';
import 'add_tire_screen.dart';
import 'notification_screen.dart'; // ต้องมีไฟล์นี้ (ดูไฟล์ด้านล่าง)

/// HomeScreen
/// - แสดงโครงรถและตำแหน่งยาง
/// - มีปุ่มสลับยาง (swap mode)
/// - มีปุ่มเปิด NotificationScreen เพื่อดูรายการแจ้งเตือนภายในแอป
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TireSwapManager _swapManager;

  @override
  void initState() {
    super.initState();
    _swapManager = TireSwapManager();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final vehicle = appState.currentVehicle;

        // Safety: ถ้าไม่มีรถ ให้แสดงข้อความ
        if (vehicle == null) {
          return const Scaffold(
            body: Center(child: Text('ไม่พบข้อมูลรถ')),
          );
        }

        // NotificationRepository มาจาก AppState (repo ถูกสร้างใน AppState)
        final NotificationRepository repo = appState.repo;

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () => _showEditVehicleNameDialog(context, appState),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(vehicle.name),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 18),
                ],
              ),
            ),
            actions: [
              // ปุ่มดูการแจ้งเตือนในแอป (เปิด NotificationScreen)
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationScreen(repo: repo),
                    ),
                  );
                },
              ),

              // ถ้ามีหลายคัน ให้แสดงเมนูเลือกคัน
              if (appState.vehicles.length > 1)
                PopupMenuButton<int>(
                  icon: const Icon(Icons.directions_car),
                  onSelected: (index) => appState.setCurrentVehicleIndex(index),
                  itemBuilder: (context) => List.generate(
                    appState.vehicles.length,
                    (index) => PopupMenuItem(
                      value: index,
                      child: Text(appState.vehicles[index].name),
                    ),
                  ),
                ),

              // ปุ่มเพิ่มรถใหม่
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showAddVehicleDialog(context, appState),
              ),
            ],
          ),

          // เนื้อหา: โครงรถ + ยาง + ปุ่มสลับยาง
          body: Stack(
            children: [
              _buildVehicleView(vehicle, appState),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    setState(() {
                      _swapManager.toggleSwapMode();
                    });

                    if (!_swapManager.isSwappingMode) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('เลือกยางที่ 1 ที่ต้องการสลับ'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  backgroundColor:
                      _swapManager.isSwappingMode ? Colors.red : const Color(0xFFFFD700),
                  foregroundColor: _swapManager.isSwappingMode ? Colors.white : Colors.black,
                  icon: Icon(_swapManager.isSwappingMode ? Icons.close : Icons.swap_horiz),
                  label: Text(_swapManager.isSwappingMode ? 'ยกเลิก' : 'สลับยาง'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleView(Vehicle vehicle, AppState appState) {
    return Scaffold(
      backgroundColor: const Color(0xFF252525),
      body: Center(
        child: SizedBox(
          width: 350,
          height: 650,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Positioned(
                top: 130,
                child: Container(
                  width: 240,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned(
                bottom: 180,
                child: Container(
                  width: 240,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Container(
                width: 70,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(35),
                ),
              ),

              // FL
              Positioned(
                top: 60,
                left: 20,
                child: Column(
                  children: [
                    _buildTireWidgetCompact('FL', vehicle.tires['FL']),
                    const SizedBox(height: 8),
                    const Text('หน้าซ้าย', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),

              // FR
              Positioned(
                top: 60,
                right: 20,
                child: Column(
                  children: [
                    _buildTireWidgetCompact('FR', vehicle.tires['FR']),
                    const SizedBox(height: 8),
                    const Text('หน้าขวา', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),

              // RL
              Positioned(
                bottom: 100,
                left: 20,
                child: Column(
                  children: [
                    _buildTireWidgetCompact('RL', vehicle.tires['RL']),
                    const SizedBox(height: 8),
                    const Text('หลังซ้าย', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),

              // RR
              Positioned(
                bottom: 100,
                right: 20,
                child: Column(
                  children: [
                    _buildTireWidgetCompact('RR', vehicle.tires['RR']),
                    const SizedBox(height: 8),
                    const Text('หลังขวา', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),

              // SPARE
              Positioned(
                bottom: 10,
                child: Column(
                  children: [
                    _buildTireWidgetCompact('SPARE', vehicle.tires['SPARE'], isHorizontal: true),
                    const SizedBox(height: 8),
                    const Text('อะไหล่', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTireWidgetCompact(String position, TireData? tireData, {bool isHorizontal = false}) {
    final bool isFirst = _swapManager.isFirstTireSelected(position);
    final bool isSecond = _swapManager.isSecondTireSelected(position);

    return GestureDetector(
      onTap: () {
        if (_swapManager.isSwappingMode) {
          if (_swapManager.selectedFirstTire == null) {
            _swapManager.selectFirstTire(position);
            setState(() {});
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เลือกยางที่ 2 เพื่อสลับ'), duration: Duration(seconds: 2)),
            );
            return;
          }

          if (_swapManager.selectedFirstTire == position) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('คุณเลือกยางเดิม กรุณาเลือกอีกล้อหนึ่ง'), duration: Duration(seconds: 2)),
            );
            return;
          }

          _swapManager.selectSecondTire(position);
          setState(() {});

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('ยืนยันการสลับ'),
              content: Text(_swapManager.getSwapPreviewMessage()),
              actions: [
                TextButton(
                  onPressed: () {
                    _swapManager.clearSecondTire();
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('ยกเลิก'),
                ),
                TextButton(
                  onPressed: () {
                    _swapManager.performSwapConfirmed(
                      context,
                      context.read<AppState>(),
                      () {
                        setState(() {});
                      },
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('ยืนยัน'),
                ),
              ],
            ),
          );
        } else {
          if (tireData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TireDetailScreen(position: position, tireData: tireData)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddTireScreen(position: position)),
            );
          }
        }
      },
      child: Container(
        width: isHorizontal ? 120 : 80,
        height: isHorizontal ? 80 : 120,
        decoration: BoxDecoration(
          // แทน withOpacity (deprecated) ด้วย Color.fromRGBO เพื่อกำหนด alpha
          color: isFirst
              ? const Color.fromRGBO(255, 165, 0, 0.22) // สีส้มอ่อนสำหรับยางที่ 1
              : (isSecond
                  ? const Color.fromRGBO(255, 165, 0, 0.12) // สีส้มอ่อนกว่าสำหรับยางที่ 2
                  : (tireData != null ? _getHealthColor(tireData.healthPercentage) : Colors.white)),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isFirst
                ? Colors.orangeAccent
                : (isSecond ? Colors.orange.shade200 : (tireData != null ? const Color(0xFFFFD700) : Colors.grey)),
            width: isFirst ? 4 : (isSecond ? 3 : 2),
          ),
          boxShadow: [
            // แทน withOpacity ด้วย Color.fromRGBO alpha 0.3
            BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Center(
          child: tireData != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${tireData.healthPercentage}%',
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${tireData.treadDepth.toStringAsFixed(1)} mm',
                      style: const TextStyle(color: Colors.black87, fontSize: 10),
                    ),
                  ],
                )
              : const Icon(Icons.add, color: Color(0xFFFFD700), size: 40),
        ),
      ),
    );
  }

  Color _getHealthColor(int percentage) {
    if (percentage >= 70) return Colors.green.shade700;
    if (percentage >= 40) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  void _showEditVehicleNameDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: appState.currentVehicle?.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('แก้ไขชื่อรถ', style: TextStyle(color: Color(0xFFFFD700))),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'ชื่อรถ',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              appState.updateVehicleName(controller.text);
              Navigator.pop(context);
            },
            child: const Text('บันทึก', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: 'รถคันที่ ${appState.vehicles.length + 1}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('เพิ่มรถใหม่', style: TextStyle(color: Color(0xFFFFD700))),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'ชื่อรถ',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              appState.addNewVehicle(controller.text);
              Navigator.pop(context);
            },
            child: const Text('เพิ่ม', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
}
