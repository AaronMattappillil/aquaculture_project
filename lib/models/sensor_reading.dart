class SensorReading {
  SensorReading({
    required this.pondId,
    required this.timestamp,
    required this.temperatureC,
    required this.ph,
    required this.turbidityNtu,
    required this.lightLux,
    required this.waterLevelM,
    this.dissolvedOxygen,
    this.ammonia,
    this.co2,
  });

  final String pondId;
  final DateTime timestamp;
  final double temperatureC;
  final double ph;
  final double turbidityNtu;
  final double lightLux;
  final double waterLevelM;

  // Predicted/Calculated values
  final double? dissolvedOxygen;
  final double? ammonia;
  final double? co2;

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      pondId: json['pond_id'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      temperatureC: (json['temperature'] as num).toDouble(),
      ph: (json['ph'] as num).toDouble(),
      turbidityNtu: (json['turbidity'] as num).toDouble(),
      lightLux: (json['light_intensity'] as num).toDouble(),
      waterLevelM: (json['water_level'] as num).toDouble(),
      dissolvedOxygen: (json['dissolved_oxygen'] as num?)?.toDouble(),
      ammonia: (json['ammonia'] as num?)?.toDouble(),
      co2: (json['co2'] as num?)?.toDouble(),
    );
  }
}
