class InitiateSubscriptionResponse {
  final bool success;
  final String message;
  final String subscriptionId;
  final String? razorpayOrderId;
  final double amount;
  final String currency;
  final String? razorpayKey;
  final Map<String, dynamic>? rawData;

  const InitiateSubscriptionResponse({
    required this.success,
    required this.message,
    required this.subscriptionId,
    this.razorpayOrderId,
    this.amount = 0.0,
    this.currency = 'INR',
    this.razorpayKey,
    this.rawData,
  });

  factory InitiateSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] as bool? ?? true;
    final String message = json['message'] as String? ?? '';

    // Handle nested 'data' or root level
    final dynamic data = json['data'] ?? json;
    String subId = '';
    String? rzpOrderId;
    double amt = 0.0;
    String curr = 'INR';
    String? rzpKey;

    if (data is Map<String, dynamic>) {
      subId = data['subscriptionId'] as String? ??
          data['_id'] as String? ??
          data['id'] as String? ??
          '';

      if (data['subscription'] is Map<String, dynamic>) {
        final subMap = data['subscription'] as Map<String, dynamic>;
        subId = subMap['_id'] as String? ?? subMap['id'] as String? ?? subId;
      }

      rzpOrderId = data['razorpay_order_id'] as String? ??
          data['razorpayOrderId'] as String? ??
          data['orderId'] as String?;

      if (rzpOrderId == null && data['razorpayOrder'] is Map<String, dynamic>) {
        final rzpMap = data['razorpayOrder'] as Map<String, dynamic>;
        rzpOrderId = rzpMap['id'] as String? ?? rzpMap['order_id'] as String?;
        if (rzpMap.containsKey('amount')) {
          final rawAmt = (rzpMap['amount'] as num?)?.toDouble() ?? 0.0;
          amt = rawAmt > 500 ? rawAmt / 100 : rawAmt;
        }
      }

      if (amt == 0.0 && data.containsKey('amount')) {
        final rawAmt = (data['amount'] as num?)?.toDouble() ?? 0.0;
        amt = rawAmt > 500 ? rawAmt / 100 : rawAmt;
      }

      curr = data['currency'] as String? ?? 'INR';
      rzpKey = data['razorpayKey'] as String? ?? data['key'] as String? ?? data['keyId'] as String?;
    }

    return InitiateSubscriptionResponse(
      success: success,
      message: message,
      subscriptionId: subId,
      razorpayOrderId: rzpOrderId,
      amount: amt,
      currency: curr,
      razorpayKey: rzpKey,
      rawData: data is Map<String, dynamic> ? data : null,
    );
  }
}
