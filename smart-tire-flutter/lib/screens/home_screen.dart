import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/tire_data.dart';
import '../models/vehicle.dart';
import '../services/swap_tire.dart';
import 'tire_detail_screen.dart';
import 'add_tire_screen.dart';

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

        if (vehicle == null) {
          return const Scaffold(
            body: Center(child: Text('ไม่พบข้อมูลรถ')),
          );
        }

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
              if (appState.vehicles.length > 1)
                PopupMenuButton<int>(
                  icon: const Icon(Icons.directions_car),
                  onSelected: (index) {
                    appState.setCurrentVehicleIndex(index);
                  },
                  itemBuilder: (context) {
                    return List.generate(
                      appState.vehicles.length,
                      (index) => PopupMenuItem(
                        value: index,
                        child: Text(appState.vehicles[index].name),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showAddVehicleDialog(context, appState),
              ),
            ],
          ),
          body: Stack(
            children: [
              _buildVehicleView(vehicle),
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
                          content: Text('กดที่ล้อที่ 1 ที่ต้องการสลับ'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  backgroundColor: _swapManager.isSwappingMode
                      ? Colors.red
                      : const Color(0xFFFFD700),
                  foregroundColor:
                      _swapManager.isSwappingMode ? Colors.white : Colors.black,
                  icon: Icon(_swapManager.isSwappingMode
                      ? Icons.close
                      : Icons.swap_horiz),
                  label:
                      Text(_swapManager.isSwappingMode ? 'ยกเลิก' : 'สลับล้อ'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleView(Vehicle vehicle) {
    return Scaffold(
      backgroundColor: const Color(0xFF252525),
      body: Center(
        child: SizedBox(
          width: 350,
          height: 650,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Chassis Structure - Vertical axle
              Container(
                width: 40,
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              // Front axle (horizontal)
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
              // Rear axle (horizontal)
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
              // Center differential
              Container(
                width: 70,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(35),
                ),
              ),

              // Front Left Tire
              Positioned(
                top: 60,
                left: 20,
                child: Column(
                  children: [
                    _buildTireWidgetCompact('FL', vehicle.tires['FL']),
                    const SizedBox(height: 8),
                    const Text(
                      'หน้าซ้าย',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Front Right Tire
              Positioned(
                top: 60,
                right: 20,
                child: Column(
                  children: [
                    _buildTireWidgetCompact('FR', vehicle.tires['FR']),
                    const SizedBox(height: 8),
                    const Text(
                      'หน้าขวา',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Rear Left Tire
              Positioned(
                bottom: 100,
                left: 20,
                child: Column(
                  children: [
                    _buildTireWidgetCompact('RL', vehicle.tires['RL']),
                    const SizedBox(height: 8),
                    const Text(
                      'หลังซ้าย',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Rear Right Tire
              Positioned(
                bottom: 100,
                right: 20,
                child: Column(
                  children: [
                    _buildTireWidgetCompact('RR', vehicle.tires['RR']),
                    const SizedBox(height: 8),
                    const Text(
                      'หลังขวา',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Spare Tire
              Positioned(
                bottom: 10,
                child: Column(
                  children: [
                    _buildTireWidgetCompact('SPARE', vehicle.tires['SPARE'],
                        isHorizontal: true),
                    const SizedBox(height: 8),
                    const Text(
                      'อะไหล่',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTireWidgetCompact(String position, TireData? tireData,
      {bool isHorizontal = false}) {
    return GestureDetector(
      onTap: () {
        if (_swapManager.isSwappingMode) {
          _swapManager.performSwap(
            context,
            context.read<AppState>(),
            position,
            () {
              setState(() {
                _swapManager.resetSelection();
              });
            },
          );
          if (_swapManager.selectedFirstTire != null &&
              _swapManager.selectedFirstTire != position) {
            setState(() {});
          } else if (_swapManager.selectedFirstTire == position) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_swapManager.getSnackBarMessage(position)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (tireData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TireDetailScreen(position: position, tireData: tireData),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTireScreen(position: position),
              ),
            );
          }
        }
      },
      child: Container(
        width: isHorizontal ? 120 : 80,
        height: isHorizontal ? 80 : 120,
        decoration: BoxDecoration(
          color: _swapManager.isFirstTireSelected(position)
              ? Colors.orange
              : (tireData != null
                  ? _getHealthColor(tireData.healthPercentage)
                  : Colors.white),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: _swapManager.isFirstTireSelected(position)
                ? Colors.orangeAccent
                : (tireData != null ? const Color(0xFFFFD700) : Colors.grey),
            width: _swapManager.isFirstTireSelected(position) ? 4 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: tireData != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${tireData.healthPercentage}%',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${tireData.treadDepth.toStringAsFixed(1)} mm',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              : const Icon(
                  Icons.add,
                  color: Color(0xFFFFD700),
                  size: 40,
                ),
        ),
      ),
    );
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

  Color _getHealthColor(int percentage) {
    if (percentage >= 70) {
      return Colors.green.shade700;
    } else if (percentage >= 40) {
      return Colors.orange.shade700;
    } else {
      return Colors.red.shade700;
    }
  }

  void _showEditVehicleNameDialog(BuildContext context, AppState appState) {
    final controller =
        TextEditingController(text: appState.currentVehicle?.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('แก้ไขชื่อรถ',
            style: TextStyle(color: Color(0xFFFFD700))),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'ชื่อรถ',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFD700)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              appState.updateVehicleName(controller.text);
              Navigator.pop(context);
            },
            child: const Text('บันทึก',
                style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context, AppState appState) {
    final controller =
        TextEditingController(text: 'รถคันที่ ${appState.vehicles.length + 1}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('เพิ่มรถใหม่',
            style: TextStyle(color: Color(0xFFFFD700))),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'ชื่อรถ',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFD700)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              appState.addNewVehicle(controller.text);
              Navigator.pop(context);
            },
            child:
                const Text('เพิ่ม', style: TextStyle(color: Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
}
