class TireData {
  final String id;
  final String serialNumber;
  final String dotCode;
  final DateTime manufactureDate;
  final double treadDepth;
  final String sidewallImagePath;
  final String treadImagePath;
  final DateTime lastUpdated;

  TireData({
    required this.id,
    required this.serialNumber,
    required this.dotCode,
    required this.manufactureDate,
    required this.treadDepth,
    required this.sidewallImagePath,
    required this.treadImagePath,
    required this.lastUpdated,
  });

  // Estimated expiry date (naive): add years based on treadDepth (e.g., deeper tread lasts longer)
  DateTime get expiryDate {
    final extraYears = (treadDepth / 2).floor(); // every 2mm ~ 1 year
    return manufactureDate
        .add(Duration(days: 365 * (3 + extraYears))); // base 3 years
  }

  // Estimated remaining kilometers
  double get remainingKm => (treadDepth * 4000);

  // Age in whole years
  int get ageInYears {
    final now = DateTime.now();
    final diff = now.difference(manufactureDate);
    return (diff.inDays / 365).floor();
  }

  // Health percentage: simple heuristic based on treadDepth vs fullDepth (10 mm)
  int get healthPercentage {
    const fullDepth = 10.0;
    final pct = ((treadDepth / fullDepth) * 100).clamp(0, 100);
    return pct.round();
  }

  factory TireData.fromJson(Map<String, dynamic> json) => TireData(
        id: json['id'] as String,
        serialNumber: json['serialNumber'] as String,
        dotCode: json['dotCode'] as String,
        manufactureDate: DateTime.parse(json['manufactureDate'] as String),
        treadDepth: (json['treadDepth'] as num).toDouble(),
        sidewallImagePath: json['sidewallImagePath'] as String,
        treadImagePath: json['treadImagePath'] as String,
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'serialNumber': serialNumber,
        'dotCode': dotCode,
        'manufactureDate': manufactureDate.toIso8601String(),
        'treadDepth': treadDepth,
        'sidewallImagePath': sidewallImagePath,
        'treadImagePath': treadImagePath,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}
