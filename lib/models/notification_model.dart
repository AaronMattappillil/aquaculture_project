class NotificationModel {
  final String notificationId;
  final String title;
  final String body;
  final bool isRead;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.isRead,
  });
}
