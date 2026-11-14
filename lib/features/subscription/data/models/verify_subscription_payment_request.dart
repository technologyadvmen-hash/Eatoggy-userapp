class VerifySubscriptionPaymentRequest {
  final String subscriptionId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const VerifySubscriptionPaymentRequest({
    required this.subscriptionId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    };
  }

  factory VerifySubscriptionPaymentRequest.fromJson(Map<String, dynamic> json) {
    return VerifySubscriptionPaymentRequest(
      subscriptionId: json['subscriptionId'] as String? ?? '',
      razorpayOrderId: json['razorpay_order_id'] as String? ?? json['razorpayOrderId'] as String? ?? '',
      razorpayPaymentId: json['razorpay_payment_id'] as String? ?? json['razorpayPaymentId'] as String? ?? '',
      razorpaySignature: json['razorpay_signature'] as String? ?? json['razorpaySignature'] as String? ?? '',
    );
  }
}
