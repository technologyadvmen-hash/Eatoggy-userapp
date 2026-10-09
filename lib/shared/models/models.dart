import 'package:equatable/equatable.dart';

class FoodItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final bool isVeg;
  final String nutrition;
  final List<String> ingredients;
  final bool isAvailable;
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantCuisine;
  final String? restaurantCity;
  final String? restaurantType;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.isVeg,
    required this.nutrition,
    required this.ingredients,
    this.isAvailable = true,
    this.restaurantId,
    this.restaurantName,
    this.restaurantCuisine,
    this.restaurantCity,
    this.restaurantType,
  });

  String get formattedRestaurantName {
    if (restaurantName != null &&
        restaurantName!.trim().isNotEmpty &&
        !RegExp(r'^[a-z0-9]{15,}$').hasMatch(restaurantName!.toLowerCase()) &&
        !restaurantName!.toLowerCase().contains('jshmf')) {
      return restaurantName!.trim();
    }
    return 'The Great Kitchen';
  }

  String get formattedRestaurantDetails {
    final parts = <String>[];
    if (restaurantCuisine != null &&
        restaurantCuisine!.trim().isNotEmpty &&
        !RegExp(r'^[a-z0-9]{10,}$').hasMatch(restaurantCuisine!.toLowerCase()) &&
        !restaurantCuisine!.toLowerCase().contains('jdghf')) {
      parts.add(restaurantCuisine!.trim());
    } else {
      parts.add('North Indian, Mughlai');
    }
    if (restaurantCity != null && restaurantCity!.trim().isNotEmpty) {
      parts.add(restaurantCity!.trim());
    }
    return parts.join(' • ');
  }

  String get fallbackImageAsset {
    final n = name.toLowerCase().trim();
    if (n.contains('biryani') || n.contains('rice') || n.contains('pulao')) {
      return 'assets/biryani.png';
    }
    if (n.contains('tikka') || n.contains('kebab') || n.contains('starter')) {
      return 'assets/paneer_tikka.png';
    }
    if (n.contains('curry') && (n.contains('chicken') || n.contains('mutton') || !isVeg)) {
      return 'assets/chicken_curry.png';
    }
    if (n.contains('paneer') || n.contains('shahi') || n.contains('makhani')) {
      return 'assets/paneer_special.png';
    }
    if (n.contains('thali') || n.contains('meal')) {
      return 'assets/f1.png';
    }
    if (n.contains('paratha') || n.contains('roti') || n.contains('naan')) {
      return 'assets/paratha.png';
    }
    if (n.contains('samosa') || n.contains('snack')) {
      return 'assets/samosa.png';
    }
    return isVeg ? 'assets/f1.png' : 'assets/f2.png';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'isVeg': isVeg,
      'nutrition': nutrition,
      'ingredients': ingredients,
      'isAvailable': isAvailable,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantCuisine': restaurantCuisine,
      'restaurantCity': restaurantCity,
      'restaurantType': restaurantType,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    String? rId;
    String? rName;
    String? rCuisine;
    String? rCity;
    String? rType;

    if (json['restaurantId'] is Map) {
      final rMap = json['restaurantId'] as Map;
      rId = (rMap['_id'] ?? rMap['id'])?.toString();
      rName = (rMap['restaurantName'] ?? rMap['name'])?.toString();
      rCuisine = rMap['cuisine']?.toString();
      rCity = rMap['city']?.toString();
      rType = rMap['restaurantType']?.toString();
    } else if (json['restaurantId'] != null) {
      final idStr = json['restaurantId'].toString();
      if (idStr.isNotEmpty && idStr != 'null') {
        rId = idStr;
      }
    }

    if (json['restaurant'] is Map) {
      final rMap = json['restaurant'] as Map;
      rId ??= (rMap['_id'] ?? rMap['id'])?.toString();
      rName ??= (rMap['restaurantName'] ?? rMap['name'])?.toString();
      rCuisine ??= rMap['cuisine']?.toString();
      rCity ??= rMap['city']?.toString();
      rType ??= rMap['restaurantType']?.toString();
    }

    rName ??= json['restaurantName']?.toString();
    rCuisine ??= json['restaurantCuisine']?.toString();
    rCity ??= json['restaurantCity']?.toString();
    rType ??= json['restaurantType']?.toString();

    if (rCity == null || rCity.isEmpty || rCity == 'Kranti Nagar') {
      rCity = 'Sector 53, Gurugram';
    }

    return FoodItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: (json['imageUrl'] ?? json['image'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      isVeg: json['isVeg'] == true || json['isVeg'] == 'true' || json['foodType'] == 'VEG',
      nutrition: (json['nutrition'] ?? '').toString(),
      ingredients: (json['ingredients'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      isAvailable: json['isAvailable'] != false,
      restaurantId: rId,
      restaurantName: rName,
      restaurantCuisine: rCuisine,
      restaurantCity: rCity,
      restaurantType: rType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        imageUrl,
        category,
        rating,
        isVeg,
        nutrition,
        ingredients,
        isAvailable,
        restaurantId,
        restaurantName,
        restaurantCuisine,
        restaurantCity,
        restaurantType,
      ];
}

class Category extends Equatable {
  final String id;
  final String name;
  final String icon;

  const Category({required this.id, required this.name, required this.icon});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['imageUrl']?.toString() ?? json['icon']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, icon];
}

class Address extends Equatable {
  final String id;
  final String name;
  final String flatHouse;
  final String street;
  final String landmark;
  final String city;
  final String pincode;
  final String type; // Home, Work, Other

  const Address({
    required this.id,
    required this.name,
    required this.flatHouse,
    required this.street,
    required this.landmark,
    required this.city,
    required this.pincode,
    required this.type,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    final rawCity = (json['city'] ?? '').toString().trim();
    final rawPincode = (json['pincode'] ?? '').toString().trim();
    final line1 = (json['flatHouse'] ?? json['addressLine1'] ?? '').toString();
    final line2 = (json['street'] ?? json['addressLine2'] ?? '').toString();
    final full = '$line1 $line2'.trim();

    final effectivePin = rawPincode.isNotEmpty && rawPincode != '122002'
        ? rawPincode
        : (RegExp(r'\b\d{6}\b').firstMatch(full)?.group(0) ?? '');

    String effectiveCity = (rawCity.isNotEmpty && rawCity.toLowerCase() != 'gurugram')
        ? rawCity
        : '';
    if (effectiveCity.isEmpty && line2.isNotEmpty) {
      final parts = line2.split(',');
      final candidate = parts.first.replaceAll(RegExp(r'\b\d{6}\b'), '').trim();
      if (candidate.isNotEmpty) effectiveCity = candidate;
    }

    return Address(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Delivery Address').toString(),
      flatHouse: line1.isNotEmpty ? line1 : 'Delivery Address',
      street: line2,
      landmark: (json['landmark'] ?? '').toString(),
      city: effectiveCity,
      pincode: effectivePin,
      type: (json['type'] ?? json['label'] ?? 'Home').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'flatHouse': flatHouse,
      'street': street,
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [id, name, flatHouse, street, landmark, city, pincode, type];
}

class CartItem extends Equatable {
  final String? cartItemId;
  final FoodItem food;
  final int quantity;
  final List<String> addOns;

  const CartItem({
    this.cartItemId,
    required this.food,
    this.quantity = 1,
    this.addOns = const [],
  });

  CartItem copyWith({String? cartItemId, FoodItem? food, int? quantity, List<String>? addOns}) {
    return CartItem(
      cartItemId: cartItemId ?? this.cartItemId,
      food: food ?? this.food,
      quantity: quantity ?? this.quantity,
      addOns: addOns ?? this.addOns,
    );
  }

  double get totalPrice => food.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'cartItemId': cartItemId,
      'food': food.toJson(),
      'quantity': quantity,
      'addOns': addOns,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cartItemId']?.toString(),
      food: FoodItem.fromJson(Map<String, dynamic>.from(json['food'] as Map)),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      addOns: (json['addOns'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  @override
  List<Object?> get props => [cartItemId, food, quantity, addOns];
}

class Coupon extends Equatable {
  final String code;
  final double discountPercent;
  final double maxDiscount;
  final double minOrderValue;
  final String description;
  final String expiryDate;

  const Coupon({
    required this.code,
    required this.discountPercent,
    required this.maxDiscount,
    required this.minOrderValue,
    required this.description,
    required this.expiryDate,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    final discountType = json['discountType']?.toString().toUpperCase();
    final parsedTitle = double.tryParse(json['title']?.toString() ?? '');
    final discountAmount = (json['discountAmount'] as num?)?.toDouble() ??
        (json['discount'] as num?)?.toDouble() ??
        parsedTitle ??
        0.0;
    final discountPercent = (json['discountPercent'] as num?)?.toDouble() ??
        (discountType == 'PERCENTAGE' ? discountAmount : 0.0);
    final maxDiscount = (json['maxDiscount'] as num?)?.toDouble() ??
        (discountAmount > 0 ? discountAmount : 100.0);

    return Coupon(
      code: json['code']?.toString() ?? json['couponCode']?.toString() ?? '',
      discountPercent: discountPercent > 0
          ? discountPercent
          : (discountType == 'FLAT' ? 100.0 : (discountAmount > 0 ? 100.0 : 0.0)),
      maxDiscount: maxDiscount,
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? json['title']?.toString() ?? '',
      expiryDate: json['expiresAt']?.toString() ?? 'Valid for limited time',
    );
  }

  @override
  List<Object?> get props => [code, discountPercent, maxDiscount, minOrderValue, description, expiryDate];
}

class SubscriptionPlan extends Equatable {
  final String id;
  final String name;
  final double pricePerMeal;
  final int totalMeals;
  final int durationDays;
  final List<String> deliveryDays;
  final List<String> benefits;
  final bool isRecommended;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.pricePerMeal,
    required this.totalMeals,
    required this.durationDays,
    required this.deliveryDays,
    required this.benefits,
    this.isRecommended = false,
  });

  double get totalPlanPrice => pricePerMeal * totalMeals;

  @override
  List<Object?> get props => [id, name, pricePerMeal, totalMeals, durationDays, deliveryDays, benefits, isRecommended];
}

class SubscriptionCalendarDay extends Equatable {
  final DateTime date;
  final String status; // Upcoming, Delivered, Skipped, Paused
  final FoodItem? meal;
  final String? occurrenceId;

  const SubscriptionCalendarDay({
    required this.date,
    required this.status,
    this.meal,
    this.occurrenceId,
  });

  SubscriptionCalendarDay copyWith({
    DateTime? date,
    String? status,
    FoodItem? meal,
    String? occurrenceId,
  }) {
    return SubscriptionCalendarDay(
      date: date ?? this.date,
      status: status ?? this.status,
      meal: meal ?? this.meal,
      occurrenceId: occurrenceId ?? this.occurrenceId,
    );
  }

  @override
  List<Object?> get props => [date, status, meal, occurrenceId];
}

class Subscription extends Equatable {
  final String id;
  final SubscriptionPlan plan;
  final String status; // Active, Paused, Expired, Cancelled
  final int remainingMeals;
  final DateTime nextDelivery;
  final List<SubscriptionCalendarDay> schedule;

  const Subscription({
    required this.id,
    required this.plan,
    required this.status,
    required this.remainingMeals,
    required this.nextDelivery,
    required this.schedule,
  });

  Subscription copyWith({
    String? id,
    SubscriptionPlan? plan,
    String? status,
    int? remainingMeals,
    DateTime? nextDelivery,
    List<SubscriptionCalendarDay>? schedule,
  }) {
    return Subscription(
      id: id ?? this.id,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      remainingMeals: remainingMeals ?? this.remainingMeals,
      nextDelivery: nextDelivery ?? this.nextDelivery,
      schedule: schedule ?? this.schedule,
    );
  }

  @override
  List<Object?> get props => [id, plan, status, remainingMeals, nextDelivery, schedule];
}

class OrderItem extends Equatable {
  final FoodItem food;
  final int quantity;
  final double price;

  const OrderItem({required this.food, required this.quantity, required this.price});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    FoodItem foodObj;
    if (json['food'] is Map) {
      foodObj = FoodItem(
        id: (json['food']['id'] ?? json['food']['_id'] ?? '').toString(),
        name: (json['food']['name'] ?? 'Meal Item').toString(),
        price: (json['food']['price'] is num) ? (json['food']['price'] as num).toDouble() : 0.0,
        description: (json['food']['description'] ?? '').toString(),
        imageUrl: (json['food']['imageUrl'] ?? json['food']['image'] ?? 'assets/f1.png').toString(),
        category: (json['food']['category'] ?? 'Main').toString(),
        rating: (json['food']['rating'] is num) ? (json['food']['rating'] as num).toDouble() : 4.8,
        isVeg: json['food']['isVeg'] == true || json['food']['isVeg'] == 'true',
        nutrition: (json['food']['nutrition'] ?? '').toString(),
        ingredients: (json['food']['ingredients'] is List)
            ? (json['food']['ingredients'] as List).map((e) => e.toString()).toList()
            : const [],
      );
    } else {
      foodObj = FoodItem(
        id: (json['menuItemId'] ?? json['foodId'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Meal Item').toString(),
        price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
        description: (json['description'] ?? 'Delicious meal preparation').toString(),
        imageUrl: (json['imageUrl'] ?? json['image'] ?? 'assets/f1.png').toString(),
        category: (json['category'] ?? 'Main').toString(),
        rating: 4.8,
        isVeg: json['isVeg'] == true || json['isVeg'] == 'true',
        nutrition: (json['nutrition'] ?? 'Chef Curated Special').toString(),
        ingredients: const [],
      );
    }

    final double priceVal = (json['price'] is num)
        ? (json['price'] as num).toDouble()
        : double.tryParse(json['price']?.toString() ?? '') ?? foodObj.price;

    final int qty = (json['quantity'] is num)
        ? (json['quantity'] as num).toInt()
        : int.tryParse(json['quantity']?.toString() ?? '') ?? 1;

    return OrderItem(
      food: foodObj,
      quantity: qty,
      price: priceVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food': {
        'id': food.id,
        'name': food.name,
        'price': food.price,
        'description': food.description,
        'imageUrl': food.imageUrl,
        'category': food.category,
        'rating': food.rating,
        'isVeg': food.isVeg,
        'nutrition': food.nutrition,
        'ingredients': food.ingredients,
      },
      'quantity': quantity,
      'price': price,
    };
  }

  @override
  List<Object?> get props => [food, quantity, price];
}

class Order extends Equatable {
  final String id;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final Address address;
  final String status; // Active, Delivered, Cancelled
  final DateTime orderTime;
  final String eta;

  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.address,
    required this.status,
    required this.orderTime,
    required this.eta,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    String normalizeStatus(dynamic raw) {
      final s = (raw ?? 'Active').toString().toLowerCase().trim();
      if (s.contains('deliver') || s.contains('complete') || s == 'past') return 'Delivered';
      if (s.contains('cancel') || s.contains('fail') || s.contains('refund')) return 'Cancelled';
      return 'Active';
    }

    final rawItems = json['items'] as List<dynamic>?;
    final parsedItems = rawItems != null
        ? rawItems
            .whereType<Map>()
            .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <OrderItem>[];

    final rawStatus = (json['status'] ?? 'Active').toString();
    final normalizedStatus = normalizeStatus(rawStatus);

    final rawAddr = json['address'] ?? json['deliveryAddress'];
    Address addrObj;
    if (rawAddr is Map) {
      final line1 = (rawAddr['addressLine1'] ?? rawAddr['flatHouse'] ?? '').toString().trim();
      final line2 = (rawAddr['addressLine2'] ?? rawAddr['street'] ?? '').toString().trim();
      final fullCombo = '$line1 $line2'.trim();
      final parsedCity = (rawAddr['city'] ?? '').toString().trim();
      final parsedPin = (rawAddr['pincode'] ?? '').toString().trim();

      final effectivePin = (parsedPin.isNotEmpty && parsedPin != '122002')
          ? parsedPin
          : (RegExp(r'\b\d{6}\b').firstMatch(fullCombo)?.group(0) ?? '');

      String effectiveCity = (parsedCity.isNotEmpty && parsedCity.toLowerCase() != 'gurugram')
          ? parsedCity
          : '';
      if (effectiveCity.isEmpty && line2.isNotEmpty) {
        final parts = line2.split(',');
        final candidate = parts.first.replaceAll(RegExp(r'\b\d{6}\b'), '').trim();
        if (candidate.isNotEmpty) effectiveCity = candidate;
      }

      addrObj = Address(
        id: (rawAddr['id'] ?? rawAddr['_id'] ?? 'addr_order').toString(),
        name: (rawAddr['name'] ?? 'Delivery Address').toString(),
        flatHouse: line1.isNotEmpty ? line1 : 'Delivery Address',
        street: line2,
        landmark: (rawAddr['landmark'] ?? '').toString(),
        city: effectiveCity,
        pincode: effectivePin,
        type: (rawAddr['label'] ?? rawAddr['type'] ?? 'Home').toString(),
      );
    } else if (rawAddr is String && rawAddr.trim().isNotEmpty) {
      final addrStr = rawAddr.trim();
      final parts = addrStr.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      final pinMatch = RegExp(r'\b\d{6}\b').firstMatch(addrStr)?.group(0) ?? '';

      String cName = '';
      if (parts.length > 2) {
        cName = parts[parts.length - 2].replaceAll(RegExp(r'\b\d{6}\b'), '').trim();
      } else if (parts.length > 1) {
        cName = parts[1].replaceAll(RegExp(r'\b\d{6}\b'), '').trim();
      }

      addrObj = Address(
        id: 'addr_order',
        name: 'Delivery Address',
        flatHouse: parts.isNotEmpty ? parts.first : 'Delivery Address',
        street: parts.length > 1 ? parts.sublist(1).join(', ') : '',
        landmark: '',
        city: cName.toLowerCase() != 'gurugram' ? cName : '',
        pincode: pinMatch != '122002' ? pinMatch : '',
        type: 'Home',
      );
    } else {
      addrObj = const Address(
        id: 'addr_order',
        name: 'Delivery Address',
        flatHouse: 'Delivery Address',
        street: '',
        landmark: '',
        city: '',
        pincode: '',
        type: 'Home',
      );
    }

    return Order(
      id: (json['id'] ?? json['_id'] ?? json['orderNumber'] ?? '').toString(),
      items: parsedItems,
      subtotal: toDouble(json['subtotal'] ?? json['pricing']?['subtotal'] ?? json['total']),
      discount: toDouble(json['discount'] ?? json['pricing']?['couponDiscount'] ?? json['discountAmount']),
      deliveryFee: toDouble(json['deliveryFee'] ?? json['pricing']?['deliveryFee'], 30.0),
      total: toDouble(json['total'] ?? json['totalAmount'] ?? json['pricing']?['totalAmount'] ?? json['grandTotal']),
      address: addrObj,
      status: normalizedStatus,
      orderTime: json['orderTime'] != null
          ? DateTime.tryParse(json['orderTime'].toString()) ?? DateTime.now()
          : (json['placedAt'] != null
              ? DateTime.tryParse(json['placedAt'].toString()) ?? DateTime.now()
              : (json['createdAt'] != null
                  ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
                  : DateTime.now())),
      eta: (json['eta'] ?? json['estimatedDelivery'] ?? '${json['estimatedDeliveryMinutes'] ?? 35} mins').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'deliveryFee': deliveryFee,
      'total': total,
      'address': address.toJson(),
      'status': status,
      'orderTime': orderTime.toIso8601String(),
      'eta': eta,
    };
  }

  Order copyWith({String? status}) {
    return Order(
      id: id,
      items: items,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      total: total,
      address: address,
      status: status ?? this.status,
      orderTime: orderTime,
      eta: eta,
    );
  }

  @override
  List<Object?> get props => [id, items, subtotal, discount, deliveryFee, total, address, status, orderTime, eta];
}

class SupportTicket extends Equatable {
  final String id;
  final String? ticketNumber;
  final String issue;
  final String status; // Open, Pending, Resolved
  final DateTime createdAt;
  final List<Map<String, dynamic>> messages;

  const SupportTicket({
    required this.id,
    this.ticketNumber,
    required this.issue,
    required this.status,
    required this.createdAt,
    required this.messages,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      ticketNumber: json['ticketNumber']?.toString(),
      issue: (json['subject'] ?? json['issue'] ?? 'Support Inquiry').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map))
              .toList() ??
          [],
    );
  }

  String get displayId => (ticketNumber != null && ticketNumber!.isNotEmpty) ? ticketNumber! : id;

  @override
  List<Object?> get props => [id, ticketNumber, issue, status, createdAt, messages];
}

class NotificationItem extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category; // Orders, Subscription, Offers, System
  final DateTime timestamp;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      description: description,
      category: category,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, title, description, category, timestamp, isRead];
}
