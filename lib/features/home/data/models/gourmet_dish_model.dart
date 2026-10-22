import '../../../../shared/models/models.dart';

class GourmetRestaurantRef {
  final String id;
  final String? restaurantName;
  final String? cuisine;
  final String? city;
  final String? restaurantType;
  final String? fullAddress;

  const GourmetRestaurantRef({
    required this.id,
    this.restaurantName,
    this.cuisine,
    this.city,
    this.restaurantType,
    this.fullAddress,
  });

  factory GourmetRestaurantRef.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return GourmetRestaurantRef(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        restaurantName: json['restaurantName'] as String? ?? json['name'] as String?,
        cuisine: json['cuisine'] as String?,
        city: json['city'] as String?,
        restaurantType: json['restaurantType'] as String?,
        fullAddress: json['fullAddress'] as String?,
      );
    } else if (json is Map) {
      return GourmetRestaurantRef(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        restaurantName: json['restaurantName']?.toString() ?? json['name']?.toString(),
        cuisine: json['cuisine']?.toString(),
        city: json['city']?.toString(),
        restaurantType: json['restaurantType']?.toString(),
        fullAddress: json['fullAddress']?.toString(),
      );
    } else if (json is String) {
      return GourmetRestaurantRef(id: json);
    }
    return const GourmetRestaurantRef(id: '');
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      if (restaurantName != null) 'restaurantName': restaurantName,
      if (cuisine != null) 'cuisine': cuisine,
      if (city != null) 'city': city,
      if (restaurantType != null) 'restaurantType': restaurantType,
      if (fullAddress != null) 'fullAddress': fullAddress,
    };
  }
}

class GourmetDishModel {
  final String id;
  final GourmetRestaurantRef? restaurantId;
  final String name;
  final String description;
  final String? image;
  final double price;
  final String foodType;
  final int? preparationTime;

  const GourmetDishModel({
    required this.id,
    this.restaurantId,
    required this.name,
    required this.description,
    this.image,
    required this.price,
    required this.foodType,
    this.preparationTime,
  });

  bool get isVeg => foodType.toUpperCase() != 'NON_VEG';

  factory GourmetDishModel.fromJson(Map<String, dynamic> json) {
    return GourmetDishModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      restaurantId: json['restaurantId'] != null
          ? GourmetRestaurantRef.fromJson(json['restaurantId'])
          : null,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      image: json['image'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      foodType: json['foodType'] as String? ?? 'VEG',
      preparationTime: (json['preparationTime'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'restaurantId': restaurantId?.toJson(),
      'name': name,
      'description': description,
      'image': image,
      'price': price,
      'foodType': foodType,
      if (preparationTime != null) 'preparationTime': preparationTime,
    };
  }
  String get fallbackImageForDish {
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

  FoodItem toFoodItem() {
    String effectiveImageUrl = fallbackImageForDish;
    if (image != null && image!.trim().isNotEmpty) {
      final img = image!.trim();
      // If image URL is not pointing to unauthorized/broken R2 cloudflare storage, use it
      if (img.startsWith('http') && !img.contains('pub-advmenngo.r2.dev')) {
        effectiveImageUrl = img;
      } else if (img.startsWith('assets/')) {
        effectiveImageUrl = img;
      }
    }

    return FoodItem(
      id: id,
      name: name,
      description: description.isNotEmpty
          ? description
          : (isVeg
              ? 'Exquisite chef crafted vegetarian preparation'
              : 'Slow cooked aromatic Mughlai gourmet delicacy'),
      price: price,
      imageUrl: effectiveImageUrl,
      category: 'Gourmet Creations',
      rating: 4.9,
      isVeg: isVeg,
      nutrition: preparationTime != null
          ? 'Prep: ${preparationTime}m | Chef Curated'
          : 'Chef Special Curated Dish',
      ingredients: isVeg
          ? const ['Fresh Cottage Cheese', 'Cashew Paste', 'Gourmet Spices', 'Herbs']
          : const ['Tender Chicken/Mutton', 'Aromatic Gravy', 'Exotic Spices'],
      isAvailable: true,
      restaurantId: restaurantId?.id,
      restaurantName: restaurantId?.restaurantName,
      restaurantCuisine: restaurantId?.cuisine,
      restaurantCity: restaurantId?.city,
      restaurantType: restaurantId?.restaurantType,
    );
  }
}

class GetGourmetDishesResponse {
  final bool success;
  final String? message;
  final List<GourmetDishModel> data;

  const GetGourmetDishesResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory GetGourmetDishesResponse.fromJson(dynamic json) {
    List<GourmetDishModel> parsedList = [];
    bool success = false;
    String? message;

    if (json is List) {
      parsedList = json
          .map((item) {
            if (item is Map<String, dynamic>) {
              return GourmetDishModel.fromJson(item);
            } else if (item is Map) {
              return GourmetDishModel.fromJson(Map<String, dynamic>.from(item));
            }
            return null;
          })
          .whereType<GourmetDishModel>()
          .toList();
      success = parsedList.isNotEmpty;
    } else if (json is Map) {
      message = json['message']?.toString();
      success = json['success'] as bool? ?? (json['status'] == 'success' || json['status'] == 200 || true);

      dynamic rawData = json['data'] ?? json['dishes'] ?? json['items'] ?? json['gourmet'] ?? json['results'];
      if (rawData is Map) {
        rawData = rawData['dishes'] ?? rawData['items'] ?? rawData['menuItems'] ?? rawData['data'];
      }

      if (rawData is List) {
        parsedList = rawData
            .map((item) {
              if (item is Map<String, dynamic>) {
                return GourmetDishModel.fromJson(item);
              } else if (item is Map) {
                return GourmetDishModel.fromJson(Map<String, dynamic>.from(item));
              }
              return null;
            })
            .whereType<GourmetDishModel>()
            .toList();
      }
    }

    return GetGourmetDishesResponse(
      success: success || parsedList.isNotEmpty,
      message: message,
      data: parsedList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((d) => d.toJson()).toList(),
    };
  }
}
