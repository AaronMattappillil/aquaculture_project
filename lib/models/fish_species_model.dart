class ParameterThreshold {
  final String name;
  final double? min;
  final double? max;

  ParameterThreshold({required this.name, this.min, this.max});

  factory ParameterThreshold.fromJson(Map<String, dynamic> json) {
    return ParameterThreshold(
      name: json['name'] ?? '',
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'min': min, 'max': max};

  /// Convenience getters for threshold types
  bool get isTemperature => name.toLowerCase().contains('temp');
  bool get isPh => name.toLowerCase().contains('ph');
  bool get isTurbidity => name.toLowerCase().contains('turbid');
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParameterThreshold &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          min == other.min &&
          max == other.max;

  @override
  int get hashCode => name.hashCode ^ min.hashCode ^ max.hashCode;
}

class FishSpeciesModel {
  final String id;
  final String name;
  final double temperatureMin;
  final double temperatureMax;
  final double phMin;
  final double phMax;
  final double turbidity;
  final bool isCustom;
  final String? createdBy;

  FishSpeciesModel({
    required this.id,
    required this.name,
    this.temperatureMin = 22.0,
    this.temperatureMax = 30.0,
    this.phMin = 6.5,
    this.phMax = 8.5,
    this.turbidity = 10.0,
    this.isCustom = false,
    this.createdBy,
  });

  factory FishSpeciesModel.fromJson(Map<String, dynamic> json) {
    return FishSpeciesModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      temperatureMin: (json['temperature_min'] as num?)?.toDouble() ?? 22.0,
      temperatureMax: (json['temperature_max'] as num?)?.toDouble() ?? 30.0,
      phMin: (json['ph_min'] as num?)?.toDouble() ?? 6.5,
      phMax: (json['ph_max'] as num?)?.toDouble() ?? 8.5,
      turbidity: (json['turbidity'] as num?)?.toDouble() ?? 10.0,
      isCustom: json['is_custom'] ?? false,
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'temperature_min': temperatureMin,
        'temperature_max': temperatureMax,
        'ph_min': phMin,
        'ph_max': phMax,
        'turbidity': turbidity,
        'is_custom': isCustom,
        'created_by': createdBy,
      };

  /// Special instance to represent the "Add New" option in dropdowns
  static final addNew = FishSpeciesModel(
    id: 'ADD_NEW',
    name: 'Add Custom Species...',
    temperatureMin: 0,
    temperatureMax: 0,
    phMin: 0,
    phMax: 0,
    turbidity: 0,
    isCustom: true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FishSpeciesModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
