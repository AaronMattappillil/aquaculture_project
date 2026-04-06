class ReportModel {
  final String id;
  final String pondId;
  final String userId;
  final Map<String, dynamic> sensorSnapshot;
  final String trendAnalysis;
  final List<String> recommendations;
  final String? alertId;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.pondId,
    required this.userId,
    required this.sensorSnapshot,
    required this.trendAnalysis,
    required this.recommendations,
    this.alertId,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      pondId: json['pond_id'] ?? '',
      userId: json['user_id'] ?? '',
      sensorSnapshot: json['sensor_snapshot'] ?? {},
      trendAnalysis: json['trend_analysis'] ?? '',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      alertId: json['alert_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}
