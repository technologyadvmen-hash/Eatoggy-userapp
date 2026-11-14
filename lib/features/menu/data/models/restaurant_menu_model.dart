import '../../../../shared/models/models.dart';

class RestaurantMenuItemModel {
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

  const RestaurantMenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.rating = 4.8,
    this.isVeg = true,
    this.nutrition = 'Chef Special Curated Dish',
    this.ingredients = const [],
    this.isAvailable = true,
    this.restaurantId,
    this.restaurantName,
    this.restaurantCuisine,
    this.restaurantCity,
    this.restaurantType,
  });

  factory RestaurantMenuItemModel.fromJson(
    Map<String, dynamic> json, {
    String defaultCategory = '',
    String? parentRestaurantId,
    String? parentRestaurantName,
    String? parentRestaurantCuisine,
    String? parentRestaurantCity,
    String? parentRestaurantType,
  }) {
    double toDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    final rawFoodType = (json['foodType'] ?? json['type'] ?? (json['isVeg'] == true ? 'VEG' : 'NON_VEG')).toString();
    final isVeg = rawFoodType.toUpperCase() != 'NON_VEG';

    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final name = (json['name'] ?? json['title'] ?? 'Gourmet Dish').toString();
    final description = (json['description'] ?? 'Delicious royal gourmet preparation').toString();
    final price = toDouble(json['price']);
    final rawImage = (json['image'] ?? json['imageUrl'] ?? '').toString();
    String effectiveImage = '';
    if (rawImage.isNotEmpty &&
        rawImage.toLowerCase() != 'null' &&
        !rawImage.contains('pub-advmenngo.r2.dev')) {
      effectiveImage = rawImage;
    } else {
      final lowerName = name.toLowerCase().trim();
      if (lowerName.contains('biryani') || lowerName.contains('rice') || lowerName.contains('pulao')) {
        effectiveImage = 'assets/biryani.png';
      } else if (lowerName.contains('tikka') || lowerName.contains('kebab') || lowerName.contains('starter')) {
        effectiveImage = 'assets/paneer_tikka.png';
      } else if (lowerName.contains('curry') && (lowerName.contains('chicken') || lowerName.contains('mutton') || !isVeg)) {
        effectiveImage = 'assets/chicken_curry.png';
      } else if (lowerName.contains('paneer') || lowerName.contains('shahi') || lowerName.contains('makhani')) {
        effectiveImage = 'assets/paneer_special.png';
      } else if (lowerName.contains('paratha') || lowerName.contains('roti') || lowerName.contains('naan')) {
        effectiveImage = 'assets/paratha.png';
      } else if (lowerName.contains('samosa') || lowerName.contains('chaat')) {
        effectiveImage = 'assets/samosa.png';
      } else {
        effectiveImage = isVeg ? 'assets/f1.png' : 'assets/f2.png';
      }
    }

    // Extract raw category or restaurant cuisine
    String rawCategory = defaultCategory;
    if (rawCategory.isEmpty && json['category'] != null) {
      rawCategory = json['category'].toString();
    } else if (rawCategory.isEmpty && json['categoryName'] != null) {
      rawCategory = json['categoryName'].toString();
    } else if (rawCategory.isEmpty && json['restaurantId'] is Map && json['restaurantId']['cuisine'] != null) {
      rawCategory = json['restaurantId']['cuisine'].toString();
    }

    // Extract restaurant metadata if present (Map, String, or passed fallback)
    String? restaurantId = parentRestaurantId;
    String? restaurantName = parentRestaurantName;
    String? restaurantCuisine = parentRestaurantCuisine;
    String? restaurantCity = parentRestaurantCity;
    String? restaurantType = parentRestaurantType;

    if (json['restaurantId'] is Map) {
      final rMap = json['restaurantId'];
      restaurantId = (rMap['_id'] ?? rMap['id'])?.toString() ?? restaurantId;
      restaurantName = (rMap['restaurantName'] ?? rMap['name'])?.toString() ?? restaurantName;
      restaurantCuisine = rMap['cuisine']?.toString() ?? restaurantCuisine;
      restaurantCity = rMap['city']?.toString() ?? restaurantCity;
      restaurantType = rMap['restaurantType']?.toString() ?? restaurantType;
    } else if (json['restaurantId'] != null) {
      final idStr = json['restaurantId'].toString();
      if (idStr.isNotEmpty && idStr != 'null') {
        restaurantId = idStr;
      }
    }

    if (json['restaurant'] is Map) {
      final rMap = json['restaurant'];
      restaurantId = (rMap['_id'] ?? rMap['id'])?.toString() ?? restaurantId;
      restaurantName = (rMap['restaurantName'] ?? rMap['name'])?.toString() ?? restaurantName;
      restaurantCuisine = rMap['cuisine']?.toString() ?? restaurantCuisine;
      restaurantCity = rMap['city']?.toString() ?? restaurantCity;
      restaurantType = rMap['restaurantType']?.toString() ?? restaurantType;
    } else if (json['restaurant'] != null && restaurantId == null) {
      final idStr = json['restaurant'].toString();
      if (idStr.isNotEmpty && idStr != 'null') {
        restaurantId = idStr;
      }
    }

    if (json['restaurantName'] != null && json['restaurantName'].toString().isNotEmpty) {
      restaurantName = json['restaurantName'].toString();
    }
    if (json['restaurantCuisine'] != null && json['restaurantCuisine'].toString().isNotEmpty) {
      restaurantCuisine = json['restaurantCuisine'].toString();
    }
    if (json['restaurantCity'] != null && json['restaurantCity'].toString().isNotEmpty) {
      restaurantCity = json['restaurantCity'].toString();
    }
    if (json['restaurantType'] != null && json['restaurantType'].toString().isNotEmpty) {
      restaurantType = json['restaurantType'].toString();
    }

    // Clean up category into gourmet sections

    // Clean up category into gourmet sections
    String cleanCategory(String cat, String itemName, bool isVegDish) {
      final lowerName = itemName.toLowerCase().trim();
      final lowerCat = cat.toLowerCase().trim();

      if (lowerName.contains('biryani') || lowerName.contains('pulao') || lowerName.contains('rice')) {
        return 'Biryani & Rice';
      }
      if (lowerName.contains('thali') || lowerName.contains('special thali')) {
        return 'Royal Thali';
      }
      if (lowerName.contains('curry') || lowerName.contains('masala') || lowerName.contains('paneer') || lowerName.contains('chicken') || lowerName.contains('dal')) {
        return 'Luxe Curries';
      }
      if (lowerName.contains('tikka') || lowerName.contains('kebab') || lowerName.contains('starter')) {
        return 'Starters';
      }
      if (lowerName.contains('roti') || lowerName.contains('naan') || lowerName.contains('paratha') || lowerName.contains('bread') || lowerName.contains('kulcha')) {
        return 'Heritage Breads';
      }
      if (lowerName.contains('sweet') || lowerName.contains('halwa') || lowerName.contains('dessert') || lowerName.contains('kheer') || lowerName.contains('jamun')) {
        return 'Desserts';
      }

      if (lowerCat.isNotEmpty && !lowerCat.contains('main') && lowerCat.length > 3 && !RegExp(r'^[0-9a-f]{6,}$').hasMatch(lowerCat)) {
        return cat[0].toUpperCase() + cat.substring(1);
      }

      return isVegDish ? 'Gourmet Veg' : 'Gourmet Non-Veg';
    }

    final finalCategory = cleanCategory(rawCategory, name, isVeg);
    final rating = toDouble(json['rating'], 4.8);

    List<String> ingredients = [];
    if (json['ingredients'] is List) {
      ingredients = (json['ingredients'] as List).map((e) => e.toString()).toList();
    }

    return RestaurantMenuItemModel(
      id: id,
      name: name,
      description: description,
      price: price,
      imageUrl: effectiveImage,
      category: finalCategory,
      rating: rating,
      isVeg: isVeg,
      nutrition: (json['nutrition'] ?? 'Prep: 25m • Chef Special Curated').toString(),
      ingredients: ingredients,
      isAvailable: json['isAvailable'] as bool? ?? true,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantCuisine: restaurantCuisine,
      restaurantCity: restaurantCity,
      restaurantType: restaurantType,
    );
  }

  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantCuisine;
  final String? restaurantCity;
  final String? restaurantType;

  FoodItem toFoodItem() {
    return FoodItem(
      id: id,
      name: name,
      description: description.isNotEmpty ? description : 'Delicious royal gourmet preparation',
      price: price,
      imageUrl: imageUrl,
      category: category,
      rating: rating,
      isVeg: isVeg,
      nutrition: nutrition,
      ingredients: ingredients.isNotEmpty ? ingredients : (isVeg ? ['Organic Spices', 'Pure Ghee'] : ['Royal Spices', 'Tender Meat']),
      isAvailable: isAvailable,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantCuisine: restaurantCuisine,
      restaurantCity: restaurantCity,
      restaurantType: restaurantType,
    );
  }
}

class RestaurantMenuCategory {
  final String categoryName;
  final List<RestaurantMenuItemModel> items;

  const RestaurantMenuCategory({
    required this.categoryName,
    required this.items,
  });

  factory RestaurantMenuCategory.fromJson(
    Map<String, dynamic> json, {
    String? parentRestaurantId,
    String? parentRestaurantName,
    String? parentRestaurantCuisine,
    String? parentRestaurantCity,
    String? parentRestaurantType,
  }) {
    final name = (json['category'] ?? json['categoryName'] ?? json['name'] ?? 'Royal Menu').toString();
    List<RestaurantMenuItemModel> itemList = [];

    void parseItems(List rawList, String catName) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          itemList.add(RestaurantMenuItemModel.fromJson(
            item,
            defaultCategory: catName,
            parentRestaurantId: parentRestaurantId,
            parentRestaurantName: parentRestaurantName,
            parentRestaurantCuisine: parentRestaurantCuisine,
            parentRestaurantCity: parentRestaurantCity,
            parentRestaurantType: parentRestaurantType,
          ));
        } else if (item is Map) {
          itemList.add(RestaurantMenuItemModel.fromJson(
            Map<String, dynamic>.from(item),
            defaultCategory: catName,
            parentRestaurantId: parentRestaurantId,
            parentRestaurantName: parentRestaurantName,
            parentRestaurantCuisine: parentRestaurantCuisine,
            parentRestaurantCity: parentRestaurantCity,
            parentRestaurantType: parentRestaurantType,
          ));
        }
      }
    }

    if (json['items'] is List) {
      parseItems(json['items'] as List, name);
    }
    if (json['menuItems'] is List) {
      parseItems(json['menuItems'] as List, name);
    }
    if (json['subcategories'] is List) {
      for (final sub in json['subcategories']) {
        if (sub is Map) {
          final subName = (sub['name'] ?? sub['title'] ?? name).toString();
          if (sub['items'] is List) {
            parseItems(sub['items'] as List, name.isNotEmpty ? name : subName);
          }
          if (sub['menuItems'] is List) {
            parseItems(sub['menuItems'] as List, name.isNotEmpty ? name : subName);
          }
        }
      }
    }

    return RestaurantMenuCategory(
      categoryName: name,
      items: itemList,
    );
  }
}
