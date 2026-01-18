import 'tire_data.dart';

class Vehicle {
  String id;
  String name;
  Map<String, TireData?> tires;

  Vehicle({required this.id, required this.name, Map<String, TireData?>? tires})
      : tires = tires ??
            {
              'FL': null,
              'FR': null,
              'RL': null,
              'RR': null,
              'SPARE': null,
            };

  factory Vehicle.empty(String id, String name) => Vehicle(id: id, name: name);

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        name: json['name'] as String,
        tires: (json['tires'] as Map<String, dynamic>).map((k, v) => MapEntry(k,
            v == null ? null : TireData.fromJson(v as Map<String, dynamic>))),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tires': tires.map((k, v) => MapEntry(k, v?.toJson())),
      };
}
