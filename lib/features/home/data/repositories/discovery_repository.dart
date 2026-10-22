import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../models/banner_model.dart';
import '../models/collection_model.dart';
import '../models/restaurant_model.dart';

abstract class DiscoveryRepository {
  Future<List<BannerModel>> getBanners();
  Future<List<CollectionModel>> getCollections();
  Future<List<RestaurantModel>> getRestaurants();
  Future<String?> getPrimaryRestaurantId();
}

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  @override
  Future<List<BannerModel>> getBanners() async {
    try {
      Response response;
      try {
        response = await ApiService.dio.get(ApiConstants.discoveryBanners);
      } catch (_) {
        // Fallback to direct /banners route
        response = await ApiService.dio.get(ApiConstants.banners);
      }

      final data = response.data;
      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'] as List;
        } else if (data['banners'] is List) {
          list = data['banners'] as List;
        }
      } else if (data is List) {
        list = data;
      }

      if (list.isNotEmpty) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((b) => BannerModel.fromJson(b))
            .toList();
      }
      return [BannerModel.defaultHero()];
    } catch (e) {
      appLog("⚠️ Discovery banners note: $e - using default hero banner");
      return [BannerModel.defaultHero()];
    }
  }

  @override
  Future<List<CollectionModel>> getCollections() async {
    try {
      Response response;
      try {
        response = await ApiService.dio.get(ApiConstants.discoveryCollections);
      } catch (_) {
        // Fallback to direct /collections route
        response = await ApiService.dio.get(ApiConstants.collections);
      }

      final data = response.data;
      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'] as List;
        } else if (data['collections'] is List) {
          list = data['collections'] as List;
        }
      } else if (data is List) {
        list = data;
      }

      if (list.isNotEmpty) {
        final parsed = list
            .map((c) => CollectionModel.fromJson(c))
            .where((c) {
              final n = c.name.toLowerCase();
              return n.isNotEmpty &&
                  !n.contains('cat 17') &&
                  !n.contains('test') &&
                  !n.contains('verif') &&
                  !RegExp(r'\d{5,}').hasMatch(n);
            })
            .toList();

        final uniqueNames = <String>{};
        final result = <CollectionModel>[];

        for (final staple in CollectionModel.defaultCollections()) {
          if (uniqueNames.add(staple.name.toLowerCase().trim())) {
            result.add(staple);
          }
        }

        for (final item in parsed) {
          if (uniqueNames.add(item.name.toLowerCase().trim())) {
            result.add(item);
          }
        }

        return result;
      }
      return CollectionModel.defaultCollections();
    } catch (e) {
      appLog("⚠️ Discovery collections note: $e - using default collections");
      return CollectionModel.defaultCollections();
    }
  }

  @override
  Future<List<RestaurantModel>> getRestaurants() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.discoveryRestaurants);
      final data = response.data;
      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'] as List;
        } else if (data['restaurants'] is List) {
          list = data['restaurants'] as List;
        }
      } else if (data is List) {
        list = data;
      }

      if (list.isNotEmpty) {
        final parsed = list
            .whereType<Map<String, dynamic>>()
            .map((r) => RestaurantModel.fromJson(r))
            .where((r) => r.name.isNotEmpty && !r.name.toLowerCase().contains('test') && !r.name.toLowerCase().contains('jshmf'))
            .toList();

        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
      return RestaurantModel.defaultRestaurants();
    } catch (e) {
      appLog("⚠️ Discovery restaurants note: $e - using default restaurants");
      return RestaurantModel.defaultRestaurants();
    }
  }

  @override
  Future<String?> getPrimaryRestaurantId() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.discoveryRestaurants);
      final data = response.data;
      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'] as List;
        } else if (data['restaurants'] is List) {
          list = data['restaurants'] as List;
        }
      } else if (data is List) {
        list = data;
      }

      if (list.isNotEmpty) {
        final first = list.first;
        if (first is Map<String, dynamic>) {
          return (first['id'] ?? first['_id'])?.toString();
        }
      }
    } catch (e) {
      appLog("⚠️ getPrimaryRestaurantId note: $e");
    }
    return '6ab2a1e0497ff8fed6393e24'; // Default restaurant ID from Postman docs
  }
}
