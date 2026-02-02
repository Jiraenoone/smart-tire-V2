import 'package:flutter/material.dart'; // นำเข้า Flutter UI หลัก
import 'package:provider/provider.dart'; // นำเข้า Provider สำหรับ state management
import '../providers/app_state.dart'; // นำเข้า AppState ที่เก็บข้อมูลรถและยาง
import '../models/tire_data.dart'; // โมเดลข้อมูลยาง (healthPercentage, treadDepth ฯลฯ)
import '../models/vehicle.dart'; // โมเดลข้อมูลรถ (เก็บแผนที่ตำแหน่งยาง)
import '../services/swap_tire.dart'; // นำเข้า TireSwapManager สำหรับ logic การสลับยาง
import 'tire_detail_screen.dart'; // หน้ารายละเอียดยาง (เปิดเมื่อแตะยางที่มีข้อมูล)
import 'add_tire_screen.dart'; // หน้าเพิ่มยางใหม่ (เปิดเมื่อแตะยางว่าง)

// ประกาศ StatefulWidget สำหรับหน้าหลักของแอป
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key); // คอนสตรัคเตอร์ของ widget

  @override
  State<HomeScreen> createState() => _HomeScreenState(); // สร้าง state ของ widget
}

// State ของ HomeScreen
class _HomeScreenState extends State<HomeScreen> {
  late TireSwapManager _swapManager; // ตัวจัดการโหมดสลับและสถานะการเลือกยาง

  @override
  void initState() {
    super.initState(); // เรียก init ของ superclass
    _swapManager = TireSwapManager(); // สร้าง instance ของ TireSwapManager
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ Consumer เพื่อฟังการเปลี่ยนแปลงของ AppState (รถและยาง)
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final vehicle = appState.currentVehicle; // ดึงรถปัจจุบันจาก AppState

        // ถ้าไม่มีรถ ให้แสดงข้อความแจ้งผู้ใช้
        if (vehicle == null) {
          return const Scaffold(
            body: Center(child: Text('ไม่พบข้อมูลรถ')), // ข้อความเมื่อไม่มีข้อมูลรถ
          );
        }

        // ถ้ามีรถ ให้แสดง UI หลัก
        return Scaffold(
          appBar: AppBar(
            // ชื่อรถเป็นปุ่มแตะเพื่อแก้ไขชื่อ
            title: GestureDetector(
              onTap: () => _showEditVehicleNameDialog(context, appState), // เปิด dialog แก้ไขชื่อ
              child: Row(
                mainAxisSize: MainAxisSize.min, // ขนาดแถวพอดีกับเนื้อหา
                children: [
                  Text(vehicle.name), // แสดงชื่อรถ
                  const SizedBox(width: 8), // เว้นระยะระหว่างชื่อกับไอคอน
                  const Icon(Icons.edit, size: 18), // ไอคอนแก้ไข
                ],
              ),
            ),
            actions: [
              // ถ้ามีหลายคัน ให้แสดงเมนูเลือกคัน
              if (appState.vehicles.length > 1)
                PopupMenuButton<int>(
                  icon: const Icon(Icons.directions_car), // ไอคอนเมนูรถ
                  onSelected: (index) => appState.setCurrentVehicleIndex(index), // เปลี่ยนรถปัจจุบัน
                  itemBuilder: (context) => List.generate(
                    appState.vehicles.length, // จำนวนรายการเท่าจำนวนรถ
                    (index) => PopupMenuItem(
                      value: index, // ค่าที่ส่งกลับเมื่อเลือก
                      child: Text(appState.vehicles[index].name), // ชื่อรถแต่ละคัน
                    ),
                  ),
                ),
              // ปุ่มเพิ่มรถใหม่
              IconButton(
                icon: const Icon(Icons.add_circle_outline), // ไอคอนเพิ่ม
                onPressed: () => _showAddVehicleDialog(context, appState), // เปิด dialog เพิ่มรถ
              ),
            ],
          ),

          // เนื้อหา: โครงรถ + ยาง + ปุ่มสลับยาง
          body: Stack(
            children: [
              _buildVehicleView(vehicle), // วาดโครงรถและตำแหน่งยางทั้งหมด
              Positioned(
                bottom: 20, // ระยะจากล่าง
                right: 20, // ระยะจากขวา
                child: FloatingActionButton.extended(
                  onPressed: () {
                    // สลับโหมดสลับยาง (เปิด/ปิด)
                    setState(() {
                      _swapManager.toggleSwapMode();
                    });

                    // แสดงหรือซ่อน SnackBar แนะนำการใช้งาน
                    if (!_swapManager.isSwappingMode) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // ซ่อน SnackBar
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('เลือกยางที่ 1 ที่ต้องการสลับ'), // ข้อความแนะนำ
                          duration: Duration(seconds: 2), // ระยะเวลาแสดง
                        ),
                      );
                    }
                  },
                  backgroundColor: _swapManager.isSwappingMode ? Colors.red : const Color(0xFFFFD700), // สีปุ่มตามโหมด
                  foregroundColor: _swapManager.isSwappingMode ? Colors.white : Colors.black, // สีไอคอน/ข้อความ
                  icon: Icon(_swapManager.isSwappingMode ? Icons.close : Icons.swap_horiz), // ไอคอนเปลี่ยนตามโหมด
                  label: Text(_swapManager.isSwappingMode ? 'ยกเลิก' : 'สลับยาง'), // ข้อความบนปุ่ม
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// วาดโครงรถและตำแหน่งยางทั้ง 5 ตำแหน่ง (FL, FR, RL, RR, SPARE)
  Widget _buildVehicleView(Vehicle vehicle) {
    return Scaffold(
      backgroundColor: const Color(0xFF252525), // พื้นหลังสีเข้ม
      body: Center(
        child: SizedBox(
          width: 350, // ความกว้างคงที่ของโครง
          height: 650, // ความสูงคงที่ของโครง
          child: Stack(
            alignment: Alignment.center, // จัดตำแหน่งลูกให้ตรงกลาง
            children: [
              // โครงรถแนวตั้ง (ตัวถัง)
              Container(
                width: 40, // ความกว้างตัวถัง
                height: 350, // ความสูงตัวถัง
                decoration: BoxDecoration(
                  color: Colors.black, // สีตัวถัง
                  borderRadius: BorderRadius.circular(20), // มุมโค้ง
                ),
              ),

              // เพลาหน้า (ตำแหน่งแนวนอน)
              Positioned(
                top: 130, // ระยะจากบน
                child: Container(
                  width: 240, // ความกว้างเพลา
                  height: 35, // ความสูงเพลา
                  decoration: BoxDecoration(
                    color: Colors.black, // สีเพลา
                    borderRadius: BorderRadius.circular(10), // มุมโค้ง
                  ),
                ),
              ),

              // เพลาหลัง
              Positioned(
                bottom: 180, // ระยะจากล่าง
                child: Container(
                  width: 240, // ความกว้างเพลา
                  height: 35, // ความสูงเพลา
                  decoration: BoxDecoration(
                    color: Colors.black, // สีเพลา
                    borderRadius: BorderRadius.circular(10), // มุมโค้ง
                  ),
                ),
              ),

              // เฟืองกลาง (แสดงเป็นวงกลมตรงกลาง)
              Container(
                width: 70, // ความกว้างเฟือง
                height: 100, // ความสูงเฟือง
                decoration: BoxDecoration(
                  color: Colors.black, // สีเฟือง
                  borderRadius: BorderRadius.circular(35), // มุมโค้งกลม
                ),
              ),

              // Front Left (FL)
              Positioned(
                top: 60, // ระยะจากบน
                left: 20, // ระยะจากซ้าย
                child: Column(
                  children: [
                    _buildTireWidgetCompact('FL', vehicle.tires['FL']), // วาดยางตำแหน่ง FL
                    const SizedBox(height: 8), // เว้นระยะ
                    const Text('หน้าซ้าย', style: TextStyle(color: Colors.white70, fontSize: 12)), // ป้ายตำแหน่ง
                  ],
                ),
              ),

              // Front Right (FR)
              Positioned(
                top: 60, // ระยะจากบน
                right: 20, // ระยะจากขวา
                child: Column(
                  children: [
                    _buildTireWidgetCompact('FR', vehicle.tires['FR']), // วาดยางตำแหน่ง FR
                    const SizedBox(height: 8), // เว้นระยะ
                    const Text('หน้าขวา', style: TextStyle(color: Colors.white70, fontSize: 12)), // ป้ายตำแหน่ง
                  ],
                ),
              ),

              // Rear Left (RL)
              Positioned(
                bottom: 100, // ระยะจากล่าง
                left: 20, // ระยะจากซ้าย
                child: Column(
                  children: [
                    _buildTireWidgetCompact('RL', vehicle.tires['RL']), // วาดยางตำแหน่ง RL
                    const SizedBox(height: 8), // เว้นระยะ
                    const Text('หลังซ้าย', style: TextStyle(color: Colors.white70, fontSize: 12)), // ป้ายตำแหน่ง
                  ],
                ),
              ),

              // Rear Right (RR)
              Positioned(
                bottom: 100, // ระยะจากล่าง
                right: 20, // ระยะจากขวา
                child: Column(
                  children: [
                    _buildTireWidgetCompact('RR', vehicle.tires['RR']), // วาดยางตำแหน่ง RR
                    const SizedBox(height: 8), // เว้นระยะ
                    const Text('หลังขวา', style: TextStyle(color: Colors.white70, fontSize: 12)), // ป้ายตำแหน่ง
                  ],
                ),
              ),

              // Spare (ยางอะไหล่)
              Positioned(
                bottom: 10, // ระยะจากล่าง
                child: Column(
                  children: [
                    _buildTireWidgetCompact('SPARE', vehicle.tires['SPARE'], isHorizontal: true), // วาดยางอะไหล่
                    const SizedBox(height: 8), // เว้นระยะ
                    const Text('อะไหล่', style: TextStyle(color: Colors.white70, fontSize: 12)), // ป้ายตำแหน่ง
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget แสดงยางแบบ compact
  /// - ถ้าอยู่ในโหมดสลับ: แตะครั้งแรกเป็นยางที่ 1, แตะครั้งที่สองเป็นยางที่ 2 (preview) แล้วแสดง dialog ยืนยัน
  /// - ถ้าไม่ใช่โหมดสลับ: แตะเปิดหน้า detail หรือหน้าเพิ่มยาง
  Widget _buildTireWidgetCompact(String position, TireData? tireData, {bool isHorizontal = false}) {
    // ตรวจสถานะการเลือกจาก manager
    final bool isFirst = _swapManager.isFirstTireSelected(position); // true ถ้าเป็นยางที่ 1
    final bool isSecond = _swapManager.isSecondTireSelected(position); // true ถ้าเป็นยางที่ 2 (preview)

    return GestureDetector(
      onTap: () {
        if (_swapManager.isSwappingMode) {
          // ถ้ายังไม่มียางแรก ให้ตั้งเป็นยางแรก
          if (_swapManager.selectedFirstTire == null) {
            _swapManager.selectFirstTire(position); // เก็บตำแหน่งยางที่ 1
            setState(() {}); // รีเฟรช UI ให้เห็นกรอบยางที่ 1
            ScaffoldMessenger.of(context).clearSnackBars(); // เคลียร์ SnackBar เก่า
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เลือกยางที่ 2 เพื่อสลับ'), duration: Duration(seconds: 2)),
            ); // แจ้งให้เลือกยางที่ 2
            return; // จบการทำงานของ onTap
          }

          // ถ้าแตะตำแหน่งเดียวกับยางแรก → แจ้งเตือนให้เลือกยางอื่น
          if (_swapManager.selectedFirstTire == position) {
            ScaffoldMessenger.of(context).clearSnackBars(); // เคลียร์ SnackBar เก่า
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('คุณเลือกยางเดิม กรุณาเลือกอีกล้อหนึ่ง'), duration: Duration(seconds: 2)),
            ); // แจ้งเตือน
            return; // จบการทำงานของ onTap
          }

          // ถ้ามียางแรกแล้ว และแตะตำแหน่งต่างกัน → ตั้งเป็นยางที่สอง (preview) แล้วแสดง confirm dialog
          _swapManager.selectSecondTire(position); // เก็บตำแหน่งยางที่ 2 (preview)
          setState(() {}); // อัพเดต UI ให้เห็นทั้งสองยางถูกไฮไลท์

          // แสดง dialog ยืนยันการสลับ
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('ยืนยันการสลับ'), // หัวข้อ dialog
              content: Text(_swapManager.getSwapPreviewMessage()), // ข้อความ preview จาก manager
              actions: [
                TextButton(
                  onPressed: () {
                    // ยกเลิกเฉพาะยางที่ 2 (เก็บยางที่ 1 ไว้)
                    _swapManager.clearSecondTire(); // ล้างยางที่ 2
                    setState(() {}); // รีเฟรช UI
                    Navigator.pop(context); // ปิด dialog
                  },
                  child: const Text('ยกเลิก'), // ปุ่มยกเลิก
                ),
                TextButton(
                  onPressed: () {
                    // ยืนยัน → ทำการสลับจริง
                    _swapManager.performSwapConfirmed(
                      context,
                      context.read<AppState>(), // ส่ง AppState ให้ manager เพื่อสลับข้อมูล
                      () {
                        setState(() {}); // รีเฟรช UI หลังสลับเสร็จ
                      },
                    );
                    Navigator.pop(context); // ปิด dialog
                  },
                  child: const Text('ยืนยัน'), // ปุ่มยืนยัน
                ),
              ],
            ),
          );
        } else {
          // ไม่ใช่โหมดสลับ → เปิดหน้ารายละเอียดหรือหน้าเพิ่มยาง
          if (tireData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TireDetailScreen(position: position, tireData: tireData)),
            ); // เปิดหน้ารายละเอียดยาง
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddTireScreen(position: position)),
            ); // เปิดหน้าเพิ่มยาง
          }
        }
      },

      // รูปทรงยาง: ขนาด, สีพื้น, ขอบ, เงา
      child: Container(
        width: isHorizontal ? 120 : 80, // ขนาดกว้างตามแนวนอนหรือแนวตั้ง
        height: isHorizontal ? 80 : 120, // ขนาดสูงตามแนวนอนหรือแนวตั้ง
        decoration: BoxDecoration(
          // ไฮไลท์: ยางที่ 1 ใช้สีส้มเข้มกว่า ยางที่ 2 สีอ่อนกว่า
          color: isFirst
              ? Colors.orange.withValues(alpha: 0.22) // พื้นหลังอ่อนสำหรับยางที่ 1
              : (isSecond ? Colors.orange.withValues(alpha: 0.12) // พื้นหลังอ่อนกว่าสำหรับยางที่ 2
                  : (tireData != null ? _getHealthColor(tireData.healthPercentage) : Colors.white)), // ถ้าไม่มีข้อมูลใช้สีขาว
          borderRadius: BorderRadius.circular(40), // มุมกลมของวงกลมยาง
          border: Border.all(
            color: isFirst
                ? Colors.orangeAccent // ขอบสีส้มสำหรับยางที่ 1
                : (isSecond ? Colors.orange.shade200 // ขอบสีอ่อนสำหรับยางที่ 2
                    : (tireData != null ? const Color(0xFFFFD700) : Colors.grey)), // ขอบปกติถ้ามียางหรือสีเทาถ้าว่าง
            width: isFirst ? 4 : (isSecond ? 3 : 2), // ความหนาขอบตามสถานะ
          ),
          boxShadow: [
            // เงาใต้ยาง ใช้ withValues แทน withOpacity เพื่อหลีกเลี่ยง deprecation
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Center(
          // แสดงข้อมูลยางถ้ามี หรือไอคอนเพิ่มถ้าว่าง
          child: tireData != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center, // จัดแนวกลาง
                  children: [
                    Text(
                      '${tireData.healthPercentage}%', // แสดงเปอร์เซ็นสุขภาพ
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${tireData.treadDepth.toStringAsFixed(1)} mm', // แสดงความลึกหน้ายาง
                      style: const TextStyle(color: Colors.black87, fontSize: 10),
                    ),
                  ],
                )
              : const Icon(Icons.add, color: Color(0xFFFFD700), size: 40), // ไอคอนเพิ่มยาง
        ),
      ),
    );
  }

  /// แปลงเปอร์เซ็นสุขภาพเป็นสี (ช่วยแสดงสถานะยาง)
  Color _getHealthColor(int percentage) {
    if (percentage >= 70) return Colors.green.shade700; // สีเขียวถ้าสุขภาพดี
    if (percentage >= 40) return Colors.orange.shade700; // สีส้มถ้ากลาง ๆ
    return Colors.red.shade700; // สีแดงถ้าต่ำ
  }

  // Dialog แก้ไขชื่อรถ
  void _showEditVehicleNameDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: appState.currentVehicle?.name); // เตรียม controller พร้อมชื่อเดิม
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A), // พื้นหลัง dialog
        title: const Text('แก้ไขชื่อรถ', style: TextStyle(color: Color(0xFFFFD700))), // หัวข้อ
        content: TextField(
          controller: controller, // ใช้ controller ที่เตรียมไว้
          style: const TextStyle(color: Colors.white), // สีข้อความใน TextField
          decoration: const InputDecoration(
            hintText: 'ชื่อรถ', // ข้อความแนะนำ
            hintStyle: TextStyle(color: Colors.white54), // สีข้อความแนะนำ
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))), // เส้นใต้สีทอง
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))), // ปุ่มยกเลิก
          TextButton(
            onPressed: () {
              appState.updateVehicleName(controller.text); // บันทึกชื่อใหม่ลง AppState
              Navigator.pop(context); // ปิด dialog
            },
            child: const Text('บันทึก', style: TextStyle(color: Color(0xFFFFD700))), // ปุ่มบันทึก
          ),
        ],
      ),
    );
  }

  // Dialog เพิ่มรถใหม่
  void _showAddVehicleDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: 'รถคันที่ ${appState.vehicles.length + 1}'); // ตั้งชื่อเริ่มต้น
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A), // พื้นหลัง dialog
        title: const Text('เพิ่มรถใหม่', style: TextStyle(color: Color(0xFFFFD700))), // หัวข้อ
        content: TextField(
          controller: controller, // controller สำหรับชื่อรถใหม่
          style: const TextStyle(color: Colors.white), // สีข้อความ
          decoration: const InputDecoration(
            hintText: 'ชื่อรถ', // ข้อความแนะนำ
            hintStyle: TextStyle(color: Colors.white54), // สีข้อความแนะนำ
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))), // เส้นใต้สีทอง
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey))), // ปุ่มยกเลิก
          TextButton(
            onPressed: () {
              appState.addNewVehicle(controller.text); // เพิ่มรถใหม่ลง AppState
              Navigator.pop(context); // ปิด dialog
            },
            child: const Text('เพิ่ม', style: TextStyle(color: Color(0xFFFFD700))), // ปุ่มเพิ่ม
          ),
        ],
      ),
    );
  }
}