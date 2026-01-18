import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../models/tire_data.dart';

class AppState extends ChangeNotifier {
  final List<Vehicle> _vehicles = [];
  int _currentVehicleIndex = 0;

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
  }

  void updateVehicleName(String name) {
    final v = currentVehicle;
    if (v != null) {
      v.name = name;
      notifyListeners();
    }
  }

  Future<void> updateTireData(String position, TireData data) async {
    final v = currentVehicle;
    if (v != null) {
      v.tires[position] = data;
      notifyListeners();
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
  }
}
