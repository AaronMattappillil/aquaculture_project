import 'sensor_reading_model.dart';

class PondModel {
  final String id;
  final String pondName;
  final String location;
  final String fishSpecies;
  final int fishUnits;
  final double lengthM;
  final double widthM;
  final double heightM;
  final double volumeM3;
  final String status;
  final double temperatureMin;
  final double temperatureMax;
  final double phMin;
  final double phMax;
  final double turbidityMin;
  final double turbidityMax;
  final int? estimatedFishCount;
  final bool isActive;
  final bool isHardwareLinked;
  final bool emailAlerts;
  final bool pushNotifications;
  final SensorReadingModel? sensorData;

  PondModel({
    required this.id,
    required this.pondName,
    required this.location,
    required this.fishSpecies,
    required this.fishUnits,
    required this.lengthM,
    required this.widthM,
    required this.heightM,
    required this.volumeM3,
    required this.status,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.phMin,
    required this.phMax,
    required this.turbidityMin,
    required this.turbidityMax,
    this.estimatedFishCount,
    this.isActive = false,
    this.isHardwareLinked = false,
    this.emailAlerts = false,
    this.pushNotifications = true,
    this.sensorData,
  });

  factory PondModel.fromJson(Map<String, dynamic> json) {
    return PondModel(
      id: json['id'] ?? json['_id'] ?? '',
      pondName: json['name'] ?? json['pond_name'] ?? json['pondName'] ?? '',
      location: json['location'] ?? json['location_label'] ?? '',
      fishSpecies: json['fish_species'] ?? json['fishSpecies'] ?? '',
      fishUnits: json['fish_units'] ?? json['fishUnits'] ?? 0,
      lengthM: (json['length_m'] ?? json['lengthM'] ?? 0.0).toDouble(),
      widthM: (json['width_m'] ?? json['widthM'] ?? 0.0).toDouble(),
      heightM: (json['height_m'] ?? json['depth_m'] ?? json['depthM'] ?? 0.0).toDouble(),
      volumeM3: (json['volume_m3'] ?? json['volumeM3'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'INACTIVE',

      temperatureMin: (json['temperature_min'] ?? json['temp_min'] ?? json['tempMin'] ?? 22.0).toDouble(),
      temperatureMax: (json['temperature_max'] ?? json['temp_max'] ?? json['tempMax'] ?? 30.0).toDouble(),
      phMin: (json['ph_min'] ?? json['phMin'] ?? 6.5).toDouble(),
      phMax: (json['ph_max'] ?? json['phMax'] ?? 8.5).toDouble(),
      turbidityMin: (json['turbidity_min'] ?? json['turbidityMin'] ?? 0.0).toDouble(),
      turbidityMax: (json['turbidity_max'] ?? json['turbidityMax'] ?? 40.0).toDouble(),
      estimatedFishCount: json['estimated_fish_count'] ?? json['estimatedFishCount'],
      isActive: (json['status']?.toString().toUpperCase() == 'ACTIVE'),
      isHardwareLinked: json['device_connected'] ?? json['isHardwareLinked'] ?? json['is_hardware_linked'] ?? false,
      emailAlerts: json['email_alerts'] ?? false,
      pushNotifications: json['push_notifications'] ?? true,
      sensorData: json['sensor_data'] != null ? SensorReadingModel.fromJson(json['sensor_data']) : null,
    );
  }
}
