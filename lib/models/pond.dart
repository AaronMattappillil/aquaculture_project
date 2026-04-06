class Pond {
  Pond({
    required this.id,
    required this.name,
    required this.lengthMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.fishSpecies,
    required this.ownerId,
  });

  final String id;
  final String name;
  final double lengthMeters;
  final double widthMeters;
  final double heightMeters;
  final String fishSpecies;
  final String ownerId;

  factory Pond.fromJson(Map<String, dynamic> json) {
    return Pond(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unnamed Pond',
      lengthMeters: (json['length_m'] as num?)?.toDouble() ?? 0.0,
      widthMeters: (json['width_m'] as num?)?.toDouble() ?? 0.0,
      heightMeters: (json['height_m'] as num?)?.toDouble() ?? 0.0,
      fishSpecies: json['fish_species'] as String? ?? 'Unknown',
      ownerId: json['user_id'] as String? ?? '',
    );
  }
}

