class VerifyPaymentResponse {
  final bool success;
  final String message;
  final String? orderId;
  final String? status;
  final double? totalAmount;

  const VerifyPaymentResponse({
    required this.success,
    required this.message,
    this.orderId,
    this.status,
    this.totalAmount,
  });

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) {
    final orderObj = json['order'] is Map<String, dynamic>
        ? json['order'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null);

    return VerifyPaymentResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      orderId: orderObj?['id']?.toString() ?? orderObj?['_id']?.toString() ?? json['orderId']?.toString(),
      status: orderObj?['status']?.toString() ?? 'CONFIRMED',
      totalAmount: (orderObj?['totalAmount'] as num?)?.toDouble() ??
          (orderObj?['total'] as num?)?.toDouble(),
    );
  }
}
