class InitiateCheckoutRequest {
  final String addressId;
  final Map<String, dynamic>? deliverySlot;
  final String? notes;

  const InitiateCheckoutRequest({
    required this.addressId,
    this.deliverySlot,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'addressId': addressId,
      if (deliverySlot != null) 'deliverySlot': deliverySlot,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class InitiateCheckoutResponse {
  final bool success;
  final String message;
  final String checkoutSessionId;
  final double amount;
  final String? paymentGatewayOrderId;
  final String? razorpayKey;
  final String currency;
  final String? orderId;
  final Map<String, dynamic>? data;

  const InitiateCheckoutResponse({
    required this.success,
    required this.message,
    required this.checkoutSessionId,
    required this.amount,
    this.paymentGatewayOrderId,
    this.razorpayKey,
    this.currency = 'INR',
    this.orderId,
    this.data,
  });

  factory InitiateCheckoutResponse.fromJson(Map<String, dynamic> json) {
    final payload = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final sessionId = (payload['checkoutSessionId'] ??
            payload['sessionId'] ??
            payload['_id'] ??
            payload['id'] ??
            '')
        .toString();

    final amount = toDouble(
      payload['amount'] ??
          payload['total'] ??
          payload['grandTotal'] ??
          payload['finalAmount'],
    );

    final pgOrderId = (payload['paymentGatewayOrderId'] ??
            payload['razorpayOrderId'] ??
            payload['razorpay_order_id'])
        ?.toString();

    final rzpKey = (payload['razorpayKey'] ??
            payload['key'] ??
            payload['keyId'])
        ?.toString();

    final orderId = (payload['orderId'] ?? payload['order_id'])?.toString();

    return InitiateCheckoutResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? 'Checkout session initiated',
      checkoutSessionId: sessionId,
      amount: amount,
      paymentGatewayOrderId: pgOrderId,
      razorpayKey: rzpKey,
      currency: (payload['currency'] ?? 'INR').toString(),
      orderId: orderId,
      data: payload,
    );
  }
}
