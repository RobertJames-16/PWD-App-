// One update notification linked to a complaint.
class PwdNotification {
  PwdNotification({
    required this.id,
    required this.reportId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String reportId;
  final String title;
  final String message;
  final DateTime createdAt;

  bool isRead;
}