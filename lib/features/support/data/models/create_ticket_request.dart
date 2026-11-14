class CreateTicketRequest {
  final String? orderId;
  final String category;
  final String subject;
  final String description;
  final String priority;
  final List<String> images;

  const CreateTicketRequest({
    this.orderId,
    required this.category,
    required this.subject,
    required this.description,
    this.priority = 'HIGH',
    this.images = const [],
  });

  static String normalizeCategory(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('order')) return 'ORDER_ISSUE';
    if (lower.contains('refund')) return 'REFUND';
    if (lower.contains('payment')) return 'PAYMENT';
    if (lower.contains('subscrip')) return 'SUBSCRIPTION';
    if (lower.contains('deliver')) return 'DELIVERY';
    if (lower.contains('account')) return 'ACCOUNT';
    return 'OTHER';
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'category': normalizeCategory(category),
      'subject': subject,
      'description': description,
      'priority': priority,
      'attachments': images,
    };
    if (orderId != null && orderId!.isNotEmpty) {
      map['orderId'] = orderId;
    }
    return map;
  }
}
