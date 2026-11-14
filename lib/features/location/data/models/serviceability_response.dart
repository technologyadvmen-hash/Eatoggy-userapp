class ServiceabilityResponse {
  final bool isServiceable;
  final String? kitchenId;
  final String? kitchenName;
  final int? estimatedDeliveryMinutes;
  final double? deliveryFee;
  final double? distanceInKm;
  final String? message;

  ServiceabilityResponse({
    required this.isServiceable,
    this.kitchenId,
    this.kitchenName,
    this.estimatedDeliveryMinutes,
    this.deliveryFee,
    this.distanceInKm,
    this.message,
  });

  factory ServiceabilityResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final bool serviceable = data['isServiceable'] == true ||
        data['serviceable'] == true ||
        data['is_serviceable'] == true ||
        json['isServiceable'] == true ||
        json['serviceable'] == true ||
        json['success'] == true;

    int? parseMinutes(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return ServiceabilityResponse(
      isServiceable: serviceable,
      kitchenId: (data['kitchenId'] ?? data['kitchen_id'] ?? data['kitchen']?['_id'])?.toString(),
      kitchenName: (data['kitchenName'] ?? data['kitchen_name'] ?? data['kitchen']?['name'])?.toString(),
      estimatedDeliveryMinutes: parseMinutes(
        data['estimatedDeliveryMinutes'] ?? data['deliveryTime'] ?? data['delivery_time'],
      ) ?? 35,
      deliveryFee: parseDouble(data['deliveryFee'] ?? data['delivery_fee'] ?? json['deliveryFee']) ?? 0.0,
      distanceInKm: parseDouble(data['distanceInKm'] ?? data['distance_km'] ?? data['distance']),
      message: (data['message'] ?? json['message'])?.toString() ??
          (serviceable ? 'Delivery is available in your area.' : 'We do not service this location yet.'),
    );
  }

  Map<String, dynamic> toJson() => {
        'isServiceable': isServiceable,
        'kitchenId': kitchenId,
        'kitchenName': kitchenName,
        'estimatedDeliveryMinutes': estimatedDeliveryMinutes,
        'deliveryFee': deliveryFee,
        'distanceInKm': distanceInKm,
        'message': message,
      };
}
