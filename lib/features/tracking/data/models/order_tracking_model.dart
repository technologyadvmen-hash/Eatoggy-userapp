class TrackingRider {
  final String name;
  final String phone;
  final double rating;
  final String avatar;
  final String vehicleNumber;
  final double? latitude;
  final double? longitude;

  const TrackingRider({
    this.name = 'Ramesh Kumar',
    this.phone = '+91 9876543210',
    this.rating = 4.9,
    this.avatar = 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=60',
    this.vehicleNumber = 'DL 1S AB 1234',
    this.latitude,
    this.longitude,
  });

  factory TrackingRider.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    final coords = (json['coordinates'] is Map<String, dynamic>)
        ? json['coordinates'] as Map<String, dynamic>
        : (json['location'] is Map<String, dynamic>)
            ? json['location'] as Map<String, dynamic>
            : null;

    double? lat;
    double? lng;
    if (coords != null) {
      final cLat = coords['latitude'] ?? coords['lat'];
      final cLng = coords['longitude'] ?? coords['lng'];
      if (cLat != null) lat = toDouble(cLat);
      if (cLng != null) lng = toDouble(cLng);
    }
    if (lat == null && (json['latitude'] ?? json['lat']) != null) {
      lat = toDouble(json['latitude'] ?? json['lat']);
    }
    if (lng == null && (json['longitude'] ?? json['lng']) != null) {
      lng = toDouble(json['longitude'] ?? json['lng']);
    }

    return TrackingRider(
      name: json['name'] as String? ?? 'Valet Delivery Partner',
      phone: json['phone'] as String? ?? json['mobile'] as String? ?? '+91 9876543210',
      rating: toDouble(json['rating'], 4.9),
      avatar: json['avatar'] as String? ??
          json['photo'] as String? ??
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=60',
      vehicleNumber: json['vehicleNumber'] as String? ??
          json['vehicle'] as String? ??
          'DL 1S AB 1234',
      latitude: lat,
      longitude: lng,
    );
  }
}

class TrackingTimelineStep {
  final String title;
  final String? time;
  final bool isCompleted;
  final bool isCurrent;

  const TrackingTimelineStep({
    required this.title,
    this.time,
    required this.isCompleted,
    this.isCurrent = false,
  });

  factory TrackingTimelineStep.fromJson(Map<String, dynamic> json) {
    return TrackingTimelineStep(
      title: json['title'] as String? ?? json['status'] as String? ?? '',
      time: json['time'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? json['completed'] as bool? ?? false,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }
}

class OrderTrackingModel {
  final String orderId;
  final String status;
  final String statusDisplay;
  final String eta;
  final String deliveryOtp;
  final TrackingRider rider;
  final String deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String restaurantName;
  final String restaurantAddress;
  final double? restaurantLat;
  final double? restaurantLng;
  final String instructions;
  final List<TrackingTimelineStep> timeline;

  const OrderTrackingModel({
    required this.orderId,
    required this.status,
    required this.statusDisplay,
    required this.eta,
    required this.deliveryOtp,
    required this.rider,
    required this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.restaurantName = 'The Great Kitchen',
    this.restaurantAddress = '3rd Floor, ORCHID CENTER, Sector 53, Golf Course Road, Gurugram',
    this.restaurantLat = 28.4384,
    this.restaurantLng = 77.0988,
    this.instructions = 'Ring bell and leave at door.',
    this.timeline = const [],
  });

  OrderTrackingModel copyWith({
    String? orderId,
    String? status,
    String? statusDisplay,
    String? eta,
    String? deliveryOtp,
    TrackingRider? rider,
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? restaurantName,
    String? restaurantAddress,
    double? restaurantLat,
    double? restaurantLng,
    String? instructions,
    List<TrackingTimelineStep>? timeline,
  }) {
    return OrderTrackingModel(
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      eta: eta ?? this.eta,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      rider: rider ?? this.rider,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantLat: restaurantLat ?? this.restaurantLat,
      restaurantLng: restaurantLng ?? this.restaurantLng,
      instructions: instructions ?? this.instructions,
      timeline: timeline ?? this.timeline,
    );
  }

  factory OrderTrackingModel.fromJson(Map<String, dynamic> json, {String? fallbackOrderId}) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final orderId = (data['orderId'] ?? data['id'] ?? fallbackOrderId ?? 'ORD-001').toString();
    final rawStatus = (data['status'] ?? 'OUT_FOR_DELIVERY').toString().toUpperCase();

    String friendlyStatus;
    if (rawStatus.contains('PREPAR')) {
      friendlyStatus = 'Chef is preparing your royal meal';
    } else if (rawStatus.contains('OUT') || rawStatus.contains('DISPATCH')) {
      friendlyStatus = 'Rider is on the way';
    } else if (rawStatus.contains('ARRIV')) {
      friendlyStatus = 'Rider has arrived at your location';
    } else if (rawStatus.contains('DELIVER')) {
      friendlyStatus = 'Order Delivered';
    } else {
      friendlyStatus = 'Order Confirmed & In Progress';
    }

    final eta = (data['eta'] ?? data['estimatedDelivery'] ?? '14 Mins').toString();
    final otp = (data['deliveryOtp'] ?? data['otp'] ?? '4821').toString();

    final riderJson = (data['rider'] is Map<String, dynamic>)
        ? data['rider'] as Map<String, dynamic>
        : (data['partner'] is Map<String, dynamic>)
            ? data['partner'] as Map<String, dynamic>
            : (data['valet'] is Map<String, dynamic>)
                ? data['valet'] as Map<String, dynamic>
                : <String, dynamic>{};

    final rider = TrackingRider.fromJson(riderJson);

    final rawDelivery = data['deliveryAddress'] ?? data['address'] ?? data['destination'];
    String addressStr = 'Delivery Location';
    double? destLat;
    double? destLng;

    if (rawDelivery is Map) {
      final l1 = (rawDelivery['addressLine1'] ?? rawDelivery['flatHouse'] ?? '').toString();
      final l2 = (rawDelivery['addressLine2'] ?? rawDelivery['street'] ?? '').toString();
      final city = (rawDelivery['city'] ?? '').toString();
      final pin = (rawDelivery['pincode'] ?? '').toString();
      final parts = [l1, l2, city, pin].where((s) => s.isNotEmpty).toList();
      addressStr = parts.isNotEmpty ? parts.join(', ') : (rawDelivery['label'] ?? 'Delivery Address').toString();

      if (rawDelivery['latitude'] != null || rawDelivery['lat'] != null) {
        destLat = double.tryParse((rawDelivery['latitude'] ?? rawDelivery['lat']).toString());
      }
      if (rawDelivery['longitude'] != null || rawDelivery['lng'] != null) {
        destLng = double.tryParse((rawDelivery['longitude'] ?? rawDelivery['lng']).toString());
      }
      if (rawDelivery['location'] is Map) {
        final loc = rawDelivery['location'] as Map;
        destLat ??= double.tryParse((loc['latitude'] ?? loc['lat']).toString());
        destLng ??= double.tryParse((loc['longitude'] ?? loc['lng']).toString());
      }
      if (rawDelivery['coordinates'] is List && (rawDelivery['coordinates'] as List).length >= 2) {
        final coords = rawDelivery['coordinates'] as List;
        destLng ??= double.tryParse(coords[0].toString());
        destLat ??= double.tryParse(coords[1].toString());
      }
    } else if (rawDelivery is String && rawDelivery.trim().isNotEmpty) {
      addressStr = rawDelivery.trim();
    }

    if (data['deliveryLat'] != null) destLat ??= double.tryParse(data['deliveryLat'].toString());
    if (data['deliveryLng'] != null) destLng ??= double.tryParse(data['deliveryLng'].toString());
    if (data['latitude'] != null) destLat ??= double.tryParse(data['latitude'].toString());
    if (data['longitude'] != null) destLng ??= double.tryParse(data['longitude'].toString());

    // Parse Restaurant / Kitchen Details
    String restName = 'The Great Kitchen';
    String restAddress = '3rd Floor, ORCHID CENTER, Sector 53, Golf Course Road, Gurugram';
    double? rLat;
    double? rLng;

    final rawRest = data['restaurant'] ?? data['kitchen'] ?? data['vendor'];
    if (rawRest is Map) {
      restName = (rawRest['restaurantName'] ?? rawRest['name'] ?? restName).toString();
      final rL1 = (rawRest['fullAddress'] ?? rawRest['address'] ?? rawRest['addressLine1'] ?? '').toString();
      final rCity = (rawRest['city'] ?? '').toString();
      if (rL1.isNotEmpty) {
        restAddress = rCity.isNotEmpty && !rL1.contains(rCity) ? '$rL1, $rCity' : rL1;
      }
      if (rawRest['latitude'] != null || rawRest['lat'] != null) {
        rLat = double.tryParse((rawRest['latitude'] ?? rawRest['lat']).toString());
      }
      if (rawRest['longitude'] != null || rawRest['lng'] != null) {
        rLng = double.tryParse((rawRest['longitude'] ?? rawRest['lng']).toString());
      }
      if (rawRest['location'] is Map) {
        final loc = rawRest['location'] as Map;
        rLat ??= double.tryParse((loc['latitude'] ?? loc['lat']).toString());
        rLng ??= double.tryParse((loc['longitude'] ?? loc['lng']).toString());
      }
    } else if (data['restaurantName'] != null) {
      restName = data['restaurantName'].toString();
      if (data['restaurantAddress'] != null) restAddress = data['restaurantAddress'].toString();
      if (data['restaurantLat'] != null) rLat = double.tryParse(data['restaurantLat'].toString());
      if (data['restaurantLng'] != null) rLng = double.tryParse(data['restaurantLng'].toString());
    }

    rLat ??= 28.4384;
    rLng ??= 77.0988;

    final instructions = (data['instructions'] ?? data['notes'] ?? 'Ring bell and leave at door.').toString();

    return OrderTrackingModel(
      orderId: orderId,
      status: rawStatus,
      statusDisplay: friendlyStatus,
      eta: eta,
      deliveryOtp: otp,
      rider: rider,
      deliveryAddress: addressStr,
      deliveryLat: destLat,
      deliveryLng: destLng,
      restaurantName: restName,
      restaurantAddress: restAddress,
      restaurantLat: rLat,
      restaurantLng: rLng,
      instructions: instructions,
    );
  }

  factory OrderTrackingModel.mock(
    String orderId, {
    String? deliveryAddress,
    double? lat,
    double? lng,
    String? restaurantName,
    String? restaurantAddress,
    double? restaurantLat,
    double? restaurantLng,
  }) {
    final rName = restaurantName ?? 'The Great Kitchen';
    final rAddr = restaurantAddress ?? '3rd Floor, ORCHID CENTER, Sector 53, Golf Course Road, Gurugram';
    final rLat = restaurantLat ?? 28.4384;
    final rLng = restaurantLng ?? 77.0988;

    // Rider position: dispatches from restaurant towards delivery location
    final double? riderLat;
    final double? riderLng;
    if (lat != null && lat > 28.0) {
      // Local NCR delivery
      riderLat = lat - 0.005;
      riderLng = lng != null ? lng - 0.004 : rLng;
    } else {
      // Cross-region or Beed testing: Rider starts from Gurugram restaurant
      riderLat = rLat + 0.005;
      riderLng = rLng + 0.004;
    }

    return OrderTrackingModel(
      orderId: orderId,
      status: 'OUT_FOR_DELIVERY',
      statusDisplay: 'Rider is on the way',
      eta: '14 Mins',
      deliveryOtp: '4821',
      restaurantName: rName,
      restaurantAddress: rAddr,
      restaurantLat: rLat,
      restaurantLng: rLng,
      rider: TrackingRider(
        name: 'Vikram Singh',
        phone: '+91 98765 43210',
        rating: 4.8,
        vehicleNumber: 'HR 26 DA 4291',
        latitude: riderLat,
        longitude: riderLng,
      ),
      deliveryAddress: deliveryAddress ?? 'Delivery Location',
      deliveryLat: lat,
      deliveryLng: lng,
      instructions: 'Ring bell and leave at door.',
    );
  }
}
