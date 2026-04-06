class SensorReadingModel {
  final String dataId;
  final String sensorId;
  final String pondId;
  final double temperature;
  final double ph;
  final double turbidity;
  final double lightIntensity;
  final double waterLevel;
  final DateTime timestamp;

  // ML-predicted / formula-derived values
  final double? doLevel;
  final double? ammoniaLevel;
  final double? co2Level;

  // Zone status strings: "SAFE" | "WARNING" | "DANGER"
  final String? doStatus;
  final String? ammoniaStatus;

  // ESP32 context fields
  final int? isDay;           // 1 = day, 0 = night
  final bool? day;            // true = day, false = night
  final bool? algaeSensor;    // true = algae detected / light blocked
  final String? waterLevelStr; // "NORMAL" | "LOW"
  final String? predictionSource; // "ml" | "hardware"

  SensorReadingModel({
    required this.dataId,
    required this.sensorId,
    required this.pondId,
    required this.temperature,
    required this.ph,
    required this.turbidity,
    required this.lightIntensity,
    required this.waterLevel,
    required this.timestamp,
    this.doLevel,
    this.ammoniaLevel,
    this.co2Level,
    this.doStatus,
    this.ammoniaStatus,
    this.isDay,
    this.day,
    this.algaeSensor,
    this.waterLevelStr,
    this.predictionSource,
  });

  factory SensorReadingModel.fromJson(Map<String, dynamic> json) {
    return SensorReadingModel(
      dataId: json['data_id'] ?? json['dataId'] ?? '',
      sensorId: json['sensor_id'] ?? json['sensorId'] ?? '',
      pondId: json['pond_id'] ?? json['pondId'] ?? '',
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      ph: (json['ph'] ?? 0.0).toDouble(),
      turbidity: (json['turbidity'] ?? 0.0).toDouble(),
      lightIntensity: (json['light_intensity'] ?? json['lightIntensity'] ?? 0.0).toDouble(),
      waterLevel: (json['water_level'] ?? json['waterLevel'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      doLevel: (json['do'] ?? json['do_level'] ?? 0.0).toDouble(),
      ammoniaLevel: (json['nh3'] ?? json['ammonia'] ?? json['ammonia_level'] ?? 0.0).toDouble(),
      co2Level: (json['co2'] ?? json['co2_level'] ?? 0.0).toDouble(),
      doStatus: json['do_status'] as String?,
      ammoniaStatus: (json['nh3_status'] ?? json['ammonia_status']) as String?,
      isDay: json['is_day'] as int?,
      day: json['day'] ?? (json['is_day'] == 1),
      algaeSensor: json['algae_sensor'] as bool?,
      waterLevelStr: json['water_level'] is String ? json['water_level'] as String : null,
      predictionSource: json['prediction_source'] as String?,
    );
  }

  bool isValid() {
    return temperature > 0 && ph > 0 && turbidity >= 0;
  }
}
