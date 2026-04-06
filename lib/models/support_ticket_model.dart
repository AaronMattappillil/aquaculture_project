class SupportTicketModel {
  final String ticketId;
  final String userId;
  final String userEmail;
  final String category;
  final String subject;
  final String message;
  final String status;
  final String? pondId;
  final String? adminResponse;
  final DateTime createdAt;

  SupportTicketModel({
    required this.ticketId,
    required this.userId,
    required this.userEmail,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    this.pondId,
    this.adminResponse,
    required this.createdAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    String rawSubject = json['subject'] ?? '';
    String category = json['category'] ?? '';
    
    // Support ticket detail mapping (robust field names)
    final ticketId = (json['id'] ?? json['ticket_id'] ?? json['ticketId'] ?? '').toString();
    final description = (json['description'] ?? json['message'] ?? json['content'] ?? 'No description').toString();
    final status = (json['status'] ?? 'open').toString();
    final createdAtStr = json['created_at'] ?? json['timestamp'] ?? json['date'];

    // Extract category from subject if empty (e.g., "[Billing] Bill too high")
    if (category.isEmpty && rawSubject.startsWith('[')) {
      final closingBracket = rawSubject.indexOf(']');
      if (closingBracket > 1) {
        category = rawSubject.substring(1, closingBracket);
        rawSubject = rawSubject.substring(closingBracket + 1).trim();
      }
    }

    return SupportTicketModel(
      ticketId: ticketId,
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      userEmail: (json['user_email'] ?? json['userEmail'] ?? 'no-email@aqua.com').toString(),
      category: category.isEmpty ? 'General' : category,
      subject: rawSubject.isEmpty ? 'No Subject' : rawSubject,
      message: description,
      status: status.toLowerCase(),
      pondId: (json['pond_id'] ?? json['pondId'])?.toString(),
      adminResponse: json['admin_response'] ?? json['adminResponse'],
      createdAt: createdAtStr != null 
          ? DateTime.parse(createdAtStr.toString()) 
          : DateTime.now(),
    );
  }
}
