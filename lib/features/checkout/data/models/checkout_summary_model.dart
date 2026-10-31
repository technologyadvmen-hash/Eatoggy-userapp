class CheckoutSummaryModel {
  final bool success;
  final String message;
  final double subtotal;
  final double gst;
  final double packagingFee;
  final double deliveryFee;
  final double platformFee;
  final double discount;
  final double grandTotal;
  final String currency;
  final Map<String, dynamic>? rawBreakdown;

  const CheckoutSummaryModel({
    this.success = true,
    this.message = '',
    required this.subtotal,
    required this.gst,
    required this.packagingFee,
    required this.deliveryFee,
    required this.platformFee,
    required this.discount,
    required this.grandTotal,
    this.currency = 'INR',
    this.rawBreakdown,
  });

  factory CheckoutSummaryModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final breakdown = (data['breakdown'] is Map<String, dynamic>)
        ? data['breakdown'] as Map<String, dynamic>
        : (data['pricing'] is Map<String, dynamic>)
            ? data['pricing'] as Map<String, dynamic>
            : data;

    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final subtotal = toDouble(breakdown['subtotal'] ?? breakdown['subTotal'] ?? breakdown['itemsTotal']);
    final gst = toDouble(breakdown['gst'] ?? breakdown['tax'] ?? breakdown['taxes'] ?? (subtotal * 0.05));
    final packagingFee = toDouble(breakdown['packagingFee'] ?? breakdown['packaging'] ?? breakdown['packingFee'] ?? 25.0);
    final deliveryFee = toDouble(breakdown['deliveryFee'] ?? breakdown['delivery'] ?? breakdown['deliveryCharges'] ?? 30.0);
    final platformFee = toDouble(breakdown['platformFee'] ?? breakdown['platform'] ?? 10.0);
    final discount = toDouble(breakdown['discount'] ?? breakdown['discountAmount'] ?? 0.0);

    final rawGrandTotal = breakdown['grandTotal'] ?? breakdown['total'] ?? breakdown['finalAmount'];
    final grandTotal = (rawGrandTotal != null)
        ? toDouble(rawGrandTotal)
        : ((subtotal + gst + packagingFee + deliveryFee + platformFee) - discount);

    return CheckoutSummaryModel(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      subtotal: subtotal,
      gst: gst,
      packagingFee: packagingFee,
      deliveryFee: deliveryFee,
      platformFee: platformFee,
      discount: discount,
      grandTotal: grandTotal > 0 ? grandTotal : 0.0,
      currency: (data['currency'] ?? breakdown['currency'] ?? 'INR').toString(),
      rawBreakdown: breakdown,
    );
  }

  factory CheckoutSummaryModel.fallback(double cartSubtotal, {double discount = 0.0}) {
    final gst = cartSubtotal * 0.05;
    const packagingFee = 25.0;
    const deliveryFee = 30.0;
    const platformFee = 10.0;
    final total = (cartSubtotal + gst + packagingFee + deliveryFee + platformFee) - discount;

    return CheckoutSummaryModel(
      subtotal: cartSubtotal,
      gst: gst,
      packagingFee: packagingFee,
      deliveryFee: deliveryFee,
      platformFee: platformFee,
      discount: discount,
      grandTotal: total > 0 ? total : 0.0,
    );
  }
}
