import '../../../../shared/models/models.dart';

class SupportTicketModel {
  final String id;
  final String ticketNumber;
  final String subject;
  final String issue;
  final String category;
  final String status;
  final String? orderId;
  final DateTime createdAt;
  final List<Map<String, dynamic>> messages;

  const SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.issue,
    required this.category,
    required this.status,
    this.orderId,
    required this.createdAt,
    required this.messages,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as String? ?? json['id'] as String? ?? '';
    final ticketNumber = json['ticketNumber'] as String? ?? (id.isNotEmpty ? '#$id' : '#EAT-88902');
    final subject = json['subject'] as String? ?? json['title'] as String? ?? '';
    final issue = subject.isNotEmpty
        ? subject
        : json['issue'] as String? ?? json['description'] as String? ?? 'General Assistance';
    final category = json['category'] as String? ?? 'ORDER_ISSUE';
    final status = json['status'] as String? ?? 'Open';
    final orderId = json['orderId'] as String? ?? json['order'] as String?;

    DateTime created = DateTime.now();
    if (json['createdAt'] != null) {
      try {
        created = DateTime.parse(json['createdAt'].toString());
      } catch (_) {}
    }

    List<Map<String, dynamic>> msgs = [];
    if (json['messages'] is List) {
      for (final m in json['messages'] as List) {
        if (m is Map) {
          final sender = m['sender'] ?? m['senderRole'] ?? (m['isUser'] == true ? 'User' : 'Support');
          final text = m['text'] ?? m['message'] ?? m['content'] ?? '';
          msgs.add({
            'sender': sender.toString().toLowerCase().contains('user') ? 'User' : 'Support',
            'text': text.toString(),
            'timestamp': m['timestamp'] ?? m['createdAt'] ?? created.toIso8601String(),
          });
        }
      }
    }

    if (msgs.isEmpty && json['description'] != null && json['description'].toString().isNotEmpty) {
      msgs.add({
        'sender': 'User',
        'text': json['description'].toString(),
        'timestamp': created.toIso8601String(),
      });
    }

    return SupportTicketModel(
      id: id,
      ticketNumber: ticketNumber,
      subject: subject,
      issue: issue,
      category: category,
      status: status,
      orderId: orderId,
      createdAt: created,
      messages: msgs,
    );
  }

  SupportTicket toEntity() {
    return SupportTicket(
      id: id.isNotEmpty ? id : (ticketNumber.isNotEmpty ? ticketNumber : '#EAT-88902'),
      ticketNumber: ticketNumber.isNotEmpty ? ticketNumber : null,
      issue: issue,
      status: status,
      createdAt: createdAt,
      messages: messages.isNotEmpty
          ? messages
          : [
              {'sender': 'User', 'text': issue},
              {'sender': 'Support', 'text': 'Our customer happiness team has received your ticket and is looking into it.'}
            ],
    );
  }
}
