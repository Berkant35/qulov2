class SupportTicketModel {
  final String id;
  final String subject;
  final String category;
  final String status;
  final String message;
  final String? adminReply;
  final DateTime? repliedAt;
  final DateTime createdAt;

  const SupportTicketModel({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.message,
    this.adminReply,
    this.repliedAt,
    required this.createdAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as String,
      subject: json['subject'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      message: json['message'] ?? '',
      adminReply: json['admin_reply'] as String?,
      repliedAt: json['replied_at'] != null
          ? DateTime.parse(json['replied_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
