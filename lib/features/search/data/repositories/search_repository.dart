import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/models/dummy_data.dart';
import '../../../../shared/models/models.dart';
import '../../../home/data/models/gourmet_dish_model.dart';
import '../../../menu/data/models/restaurant_menu_model.dart';
import '../../../menu/data/repositories/menu_repository.dart';

abstract class SearchRepository {
  Future<List<FoodItem>> search(String query);
}

class SearchRepositoryImpl implements SearchRepository {
  @override
  Future<List<FoodItem>> search(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    List<FoodItem> results = [];
    final seenIds = <String>{};

    // 1. Live Backend Discovery Search API
    try {
      final response = await ApiService.dio.get(
        ApiConstants.discoverySearch,
        queryParameters: {'q': cleanQuery},
      );

      final data = response.data;
      List<dynamic> itemsList = [];

      if (data is Map<String, dynamic>) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          if (innerData['menuItems'] is List) {
            itemsList.addAll(innerData['menuItems'] as List);
          }
          if (innerData['items'] is List) {
            itemsList.addAll(innerData['items'] as List);
          }
          if (innerData['dishes'] is List) {
            itemsList.addAll(innerData['dishes'] as List);
          }
        } else if (innerData is List) {
          itemsList.addAll(innerData);
        }

        if (data['menuItems'] is List) {
          itemsList.addAll(data['menuItems'] as List);
        }
        if (data['items'] is List) {
          itemsList.addAll(data['items'] as List);
        }
        if (data['results'] is List) {
          itemsList.addAll(data['results'] as List);
        }
      } else if (data is List) {
        itemsList = data;
      }

      for (final item in itemsList) {
        if (item is Map) {
          final itemMap = Map<String, dynamic>.from(item);
          try {
            final parsed = RestaurantMenuItemModel.fromJson(itemMap).toFoodItem();
            if (seenIds.add(parsed.id)) {
              results.add(parsed);
            }
          } catch (_) {
            try {
              final parsed = GourmetDishModel.fromJson(itemMap).toFoodItem();
              if (seenIds.add(parsed.id)) {
                results.add(parsed);
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      appLog("ℹ️ Live search API note: $e - expanding to menu catalog");
    }

    // 2. Also search curated Royal Menu Catalog (from MenuRepository and DummyData)
    // to guarantee comprehensive results for dishes like Paneer, Thali, Paratha, etc.
    final catalog = [
      ...MenuRepositoryImpl.defaultRoyalMenuItems(),
      ...DummyData.foodItems,
    ];

    for (final food in catalog) {
      if (!seenIds.contains(food.id)) {
        final matchesName = food.name.toLowerCase().contains(cleanQuery);
        final matchesDesc = food.description.toLowerCase().contains(cleanQuery);
        final matchesCat = food.category.toLowerCase().contains(cleanQuery);
        final matchesRest = (food.restaurantName ?? '').toLowerCase().contains(cleanQuery);
        final matchesCuisine = (food.restaurantCuisine ?? '').toLowerCase().contains(cleanQuery);

        if (matchesName || matchesDesc || matchesCat || matchesRest || matchesCuisine) {
          seenIds.add(food.id);
          results.add(food);
        }
      }
    }

    return results;
  }
}
