import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../models/tire_data.dart';
import '../services/notification_repository.dart'; // ✅ import repository

class AppState extends ChangeNotifier {
  final List<Vehicle> _vehicles = [];
  int _currentVehicleIndex = 0;

  // ✅ สร้างตัวแปร repository สำหรับแจ้งเตือน
  final NotificationRepository repo = NotificationRepository();

  AppState() {
    // initialize with a default vehicle
    _vehicles.add(Vehicle.empty(const Uuid().v4(), 'รถคันที่ 1'));
  }

  List<Vehicle> get vehicles => _vehicles;

  Vehicle? get currentVehicle =>
      _vehicles.isEmpty ? null : _vehicles[_currentVehicleIndex];

  void setCurrentVehicleIndex(int index) {
    if (index >= 0 && index < _vehicles.length) {
      _currentVehicleIndex = index;
      notifyListeners();
    }
  }

  void addNewVehicle(String name) {
    _vehicles.add(Vehicle.empty(const Uuid().v4(), name));
    notifyListeners();

    // ✅ แจ้งเตือนเมื่อเพิ่มรถใหม่
    repo.addNotification(
      "เพิ่มรถใหม่",
      "คุณได้เพิ่มรถคันใหม่เรียบร้อยแล้ว",
      scheduledTime: DateTime.now().add(Duration(seconds: 10)),
    );
  }

  void updateVehicleName(String name) {
    final v = currentVehicle;
    if (v != null) {
      v.name = name;
      notifyListeners();

      // ✅ แจ้งเตือนเมื่อแก้ชื่อรถ
      repo.addNotification(
        "แก้ไขชื่อรถ",
        "คุณได้เปลี่ยนชื่อรถเป็น $name",
      );
    }
  }

  Future<void> updateTireData(String position, TireData data) async {
    final v = currentVehicle;
    if (v != null) {
      v.tires[position] = data;
      notifyListeners();

      // ✅ แจ้งเตือนเมื่ออัปเดตข้อมูลยาง
      repo.addNotification(
        "อัปเดตข้อมูลยาง",
        "ยางตำแหน่ง $position ถูกอัปเดตเรียบร้อยแล้ว",
      );
    }
  }

  void swapTires(Map<String, String> mapping) {
    final v = currentVehicle;
    if (v == null) return;

    final newMap = Map<String, TireData?>.from(v.tires);
    mapping.forEach((from, to) {
      newMap[to] = v.tires[from];
    });

    v.tires = newMap;
    notifyListeners();

    // ✅ แจ้งเตือนเมื่อสลับยางเสร็จ
    repo.addNotification(
      "สลับยางเสร็จสิ้น",
      "คุณได้สลับยางเรียบร้อยแล้ว",
    );
  }
}
