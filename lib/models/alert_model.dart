class AlertModel {
  final String alertId;
  final String pondId;
  final String severity; // e.g., WARNING, DANGER, CRITICAL
  final String alertType; // THRESHOLD, TREND, PREDICTIVE, SYSTEM
  final String priority; // CRITICAL, WARNING, INFO
  final String paramName;
  final double paramValue;
  final String alertMessage;
  final bool isRead;
  final String status; // OPEN, RESOLVED
  final DateTime timestamp;

  AlertModel({
    required this.alertId,
    required this.pondId,
    required this.severity,
    required this.alertType,
    required this.priority,
    required this.paramName,
    required this.paramValue,
    required this.alertMessage,
    required this.isRead,
    required this.status,
    required this.timestamp,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      alertId: json['id'] ?? json['alert_id'] ?? '',
      pondId: json['pond_id'] ?? '',
      severity: json['level'] ?? json['severity'] ?? 'WARNING',
      alertType: json['alert_type'] ?? 'THRESHOLD',
      priority: json['priority'] ?? 'INFO',
      paramName: json['parameter'] ?? json['param_name'] ?? '',
      paramValue: (json['value'] ?? json['param_value'] ?? 0.0).toDouble(),
      alertMessage: json['message'] ?? json['alert_message'] ?? '',
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      status: json['status'] ?? 'OPEN',
      timestamp: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  String getFormattedValue() {
    final type = paramName.toUpperCase();
    if (type.contains('TEMPERATURE') || type.contains('TURBIDITY')) {
      return paramValue.round().toString();
    } else if (type.contains('PH')) {
      return paramValue.toStringAsFixed(1);
    } else {
      return paramValue.toStringAsFixed(2);
    }
  }
}
