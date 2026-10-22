import 'package:equatable/equatable.dart';

class RestaurantModel extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final String cuisine;
  final String city;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final double rating;
  final String ratingCount;
  final String deliveryTime;
  final String distance;
  final String costForTwo;
  final bool isPureVeg;
  final bool isHygieneVerified;
  final String offerText;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.cuisine,
    required this.city,
    this.fullAddress = '',
    this.latitude = 28.4384,
    this.longitude = 77.0988,
    this.rating = 4.3,
    this.ratingCount = '6.1K+ ratings',
    this.deliveryTime = '25-30 mins',
    this.distance = '2.4 km',
    this.costForTwo = '₹350 for two',
    this.isPureVeg = true,
    this.isHygieneVerified = true,
    this.offerText = '10% OFF UPTO ₹75',
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic val, [double def = 4.3]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final name = (json['restaurantName'] ?? json['name'] ?? 'The Great Kitchen').toString();
    final cuisine = (json['cuisine'] ?? 'Italian, North Indian').toString();

    final rawFullAddress = (json['fullAddress'] ?? json['address'] ?? '').toString().trim();
    final cleanFullAddress = rawFullAddress.replaceAll('\n', ', ').trim();

    String city = (json['city'] ?? json['location'] ?? '').toString().trim();
    if (cleanFullAddress.contains('Sector 53')) {
      city = 'Sector 53, Gurugram';
    } else if (city.isEmpty || city == 'Kranti Nagar') {
      if (cleanFullAddress.isNotEmpty) {
        city = cleanFullAddress.split(',').first.trim();
      } else {
        city = 'Sector 53, Gurugram';
      }
    } else if (city.toLowerCase() == 'gurugram') {
      if (cleanFullAddress.contains('Sector 53')) {
        city = 'Sector 53, Gurugram';
      }
    }

    final effectiveFullAddress = cleanFullAddress.isNotEmpty
        ? cleanFullAddress
        : (city.isNotEmpty ? city : '3rd Floor, ORCHID CENTER, Vesta Business Park, Golf Course Road, Sector 53, Near Himgiri Hyundai, Gurugram');

    final rawImage = (json['image'] ?? json['imageUrl'] ?? json['banner'] ?? '').toString();

    String effectiveImage = 'assets/f1.png';
    if (rawImage.isNotEmpty && !rawImage.contains('pub-advmenngo.r2.dev')) {
      effectiveImage = rawImage;
    } else {
      final lower = name.toLowerCase();
      if (lower.contains('maithili') || lower.contains('paneer')) {
        effectiveImage = 'assets/paneer_special.png';
      } else if (lower.contains('biryani') || lower.contains('great kitchen')) {
        effectiveImage = 'assets/biryani.png';
      } else if (lower.contains('punjab') || lower.contains('grill') || lower.contains('paratha')) {
        effectiveImage = 'assets/paratha.png';
      } else if (lower.contains('awadh') || lower.contains('tikka')) {
        effectiveImage = 'assets/paneer_tikka.png';
      } else if (lower.contains('chaat') || lower.contains('sweet')) {
        effectiveImage = 'assets/samosa.png';
      } else {
        effectiveImage = 'assets/f1.png';
      }
    }

    final rating = toDouble(json['rating'] ?? json['ratings'], 4.3);
    final ratingCount = (json['ratingCount'] ?? json['ratingsCount'] ?? '5K+ ratings').toString();
    final deliveryTime = (json['deliveryTime'] ?? json['eta'] ?? '25-30 mins').toString();
    final distance = (json['distance'] ?? '2.5 km').toString();
    final costForTwo = (json['costForTwo'] ?? '₹350 for two').toString();
    final isPureVeg = (json['isPureVeg'] == true || cuisine.toLowerCase().contains('pure veg'));

    double? rLat;
    double? rLng;
    if (json['latitude'] != null || json['lat'] != null) {
      rLat = toDouble(json['latitude'] ?? json['lat']);
    }
    if (json['longitude'] != null || json['lng'] != null) {
      rLng = toDouble(json['longitude'] ?? json['lng']);
    }
    if (json['location'] is Map) {
      final loc = json['location'] as Map;
      rLat ??= double.tryParse((loc['latitude'] ?? loc['lat'] ?? '').toString());
      rLng ??= double.tryParse((loc['longitude'] ?? loc['lng'] ?? '').toString());
    }
    if (json['coordinates'] is List && (json['coordinates'] as List).length >= 2) {
      final coords = json['coordinates'] as List;
      rLng ??= double.tryParse(coords[0].toString());
      rLat ??= double.tryParse(coords[1].toString());
    }
    // Default restaurant coords (The Great Kitchen, Orchid Center, Sector 53, Gurugram)
    rLat ??= 28.4384;
    rLng ??= 77.0988;

    return RestaurantModel(
      id: id,
      name: name,
      imageUrl: effectiveImage,
      cuisine: cuisine,
      city: city,
      fullAddress: effectiveFullAddress,
      latitude: rLat,
      longitude: rLng,
      rating: rating,
      ratingCount: ratingCount,
      deliveryTime: deliveryTime,
      distance: distance,
      costForTwo: costForTwo,
      isPureVeg: isPureVeg,
      isHygieneVerified: true,
      offerText: (json['offer'] ?? '10% OFF UPTO ₹75').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'cuisine': cuisine,
      'city': city,
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'ratingCount': ratingCount,
      'deliveryTime': deliveryTime,
      'distance': distance,
      'costForTwo': costForTwo,
      'isPureVeg': isPureVeg,
      'isHygieneVerified': isHygieneVerified,
      'offerText': offerText,
    };
  }

  static List<RestaurantModel> defaultRestaurants() {
    return const [
      RestaurantModel(
        id: 'rest_mcdonalds',
        name: "McDonald's",
        imageUrl: 'assets/home_svg/rest_mcdonalds.jpg',
        cuisine: 'Burgers, Fast Food',
        city: 'Sector 18, Noida',
        fullAddress: 'NX ONE Mall, TechZone 4, Greater Noida West',
        latitude: 28.5700,
        longitude: 77.3200,
        rating: 4.3,
        ratingCount: '12K+ ratings',
        deliveryTime: '25–35 mins',
        distance: '1.8 km',
        costForTwo: '₹300 for two',
        isPureVeg: false,
        offerText: '60% OFF upto ₹120',
      ),
      RestaurantModel(
        id: 'rest_dominos',
        name: "Domino's Pizza",
        imageUrl: 'assets/home_svg/rest_dominos.jpg',
        cuisine: 'Pizza, Italian',
        city: 'Sector 62, Noida',
        fullAddress: 'Gaur City Mall, Greater Noida West',
        latitude: 28.6200,
        longitude: 77.3600,
        rating: 4.2,
        ratingCount: '8K+ ratings',
        deliveryTime: '25–35 mins',
        distance: '2.4 km',
        costForTwo: '₹400 for two',
        isPureVeg: false,
        offerText: '50% OFF upto ₹100',
      ),
      RestaurantModel(
        id: 'rest_kfc',
        name: 'KFC',
        imageUrl: 'assets/home_svg/rest_kfc.jpg',
        cuisine: 'Chicken, Fast Food',
        city: 'Gaur City, Noida Ext',
        fullAddress: 'Galaxy Blue Sapphire Plaza, Greater Noida West',
        latitude: 28.5900,
        longitude: 77.4200,
        rating: 4.1,
        ratingCount: '10K+ ratings',
        deliveryTime: '25–35 mins',
        distance: '3.1 km',
        costForTwo: '₹450 for two',
        isPureVeg: false,
        offerText: 'Free Delivery on ₹199+',
      ),
      RestaurantModel(
        id: 'rest_biryani_life',
        name: 'The Biryani Life',
        imageUrl: 'assets/home_svg/rest_biryani_life.jpg',
        cuisine: 'Biryani, North Indian',
        city: 'Sector 50, Noida',
        fullAddress: 'Central Market, Sector 50, Noida',
        latitude: 28.5700,
        longitude: 77.3700,
        rating: 4.4,
        ratingCount: '6K+ ratings',
        deliveryTime: '30–40 mins',
        distance: '2.8 km',
        costForTwo: '₹350 for two',
        isPureVeg: false,
        offerText: '30% OFF upto ₹90',
      ),
      RestaurantModel(
        id: '6ab25733827cd436a4bb1d06',
        name: 'The Great Kitchen',
        imageUrl: 'assets/biryani.png',
        cuisine: 'Italian, North Indian • Cloud Kitchen',
        city: 'Sector 53, Gurugram',
        fullAddress: '3rd Floor, ORCHID CENTER, Vesta Business Park, Golf Course Road, Sector 53, Near Himgiri Hyundai, Gurugram',
        latitude: 28.4384,
        longitude: 77.0988,
        rating: 4.8,
        ratingCount: '8.4K+ ratings',
        deliveryTime: '25-30 mins',
        distance: '2.1 km',
        costForTwo: '₹350 for two',
        isPureVeg: false,
        offerText: '10% OFF UPTO ₹75',
      ),
    ];
  }

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        cuisine,
        city,
        fullAddress,
        latitude,
        longitude,
        rating,
        ratingCount,
        deliveryTime,
        distance,
        costForTwo,
        isPureVeg,
        isHygieneVerified,
        offerText,
      ];
}
