import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/models.dart';
import '../data/repositories/menu_repository.dart';
import 'menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  final MenuRepository repository;
  List<FoodItem> _allLoadedMeals = [];

  MenuCubit({MenuRepository? repository})
      : repository = repository ?? MenuRepositoryImpl(),
        super(const MenuState()) {
    loadMenu();
  }

  Future<void> loadMenu({
    String? restaurantId,
    String? initialRestaurantName,
    String? initialLocation,
    String? initialCuisine,
    bool? initialIsPureVeg,
    double? initialRating,
    String? initialDeliveryTime,
    String? initialRatingCount,
  }) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      restaurantName: initialRestaurantName ?? state.restaurantName,
      restaurantLocation: initialLocation ?? state.restaurantLocation,
      restaurantCuisine: initialCuisine ?? state.restaurantCuisine,
      isPureVegRestaurant: initialIsPureVeg ?? state.isPureVegRestaurant,
      restaurantRating: initialRating ?? state.restaurantRating,
      deliveryTime: initialDeliveryTime ?? state.deliveryTime,
      ratingCount: initialRatingCount ?? state.ratingCount,
    ));
    try {
      final meals = await repository.getRestaurantMenu(
        restaurantId: restaurantId,
        restaurantName: initialRestaurantName ?? state.restaurantName,
        restaurantCuisine: initialCuisine ?? state.restaurantCuisine,
        restaurantCity: initialLocation ?? state.restaurantLocation,
      );
      _allLoadedMeals = meals;

      // Extract distinct categories
      final Set<String> categoriesSet = meals
          .map((m) => m.category)
          .where((c) => c.trim().isNotEmpty)
          .toSet();

      final categoriesList = ['All', ...categoriesSet];

      // Derive top picks (highest rated or signature dishes)
      List<FoodItem> topPicks = meals.where((m) {
        final n = m.name.toLowerCase();
        return n.contains('shahi') ||
            n.contains('butter') ||
            n.contains('biryani') ||
            n.contains('tikka') ||
            n.contains('dal') ||
            m.rating >= 4.8;
      }).toList();

      if (topPicks.isEmpty) {
        topPicks = meals.take(4).toList();
      } else if (topPicks.length > 6) {
        topPicks = topPicks.take(6).toList();
      }

      // Check restaurant metadata from meals or passed parameters
      String restaurantName = initialRestaurantName ?? state.restaurantName;
      String restaurantLocation = initialLocation ?? state.restaurantLocation;
      String restaurantCuisine = initialCuisine ?? state.restaurantCuisine;
      bool isPureVeg = state.isPureVegRestaurant;

      if (initialRestaurantName == null && meals.isNotEmpty) {
        final sample = meals.first;
        if (sample.restaurantName != null && sample.restaurantName!.isNotEmpty) {
          restaurantName = sample.formattedRestaurantName;
        }
        if (sample.restaurantCity != null && sample.restaurantCity!.isNotEmpty) {
          restaurantLocation = sample.restaurantCity!;
        }
        if (sample.restaurantCuisine != null && sample.restaurantCuisine!.isNotEmpty) {
          restaurantCuisine = sample.restaurantCuisine!;
        }
      }

      // Check if all meals are veg
      if (meals.isNotEmpty) {
        isPureVeg = meals.every((m) => m.isVeg);
      }

      final filtered = _computeFilteredMeals(
        allMeals: meals,
        category: state.selectedCategory,
        query: state.searchQuery,
        vegOnly: state.isVegOnly,
        eatRight: state.isEatRightOnly,
        ratings4Plus: state.isRatings4Plus,
        bestseller: state.isBestsellerOnly,
      );

      emit(state.copyWith(
        isLoading: false,
        allMeals: meals,
        meals: filtered,
        topPicks: topPicks,
        categories: categoriesList,
        restaurantName: restaurantName,
        restaurantLocation: restaurantLocation,
        restaurantCuisine: restaurantCuisine,
        isPureVegRestaurant: isPureVeg,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load menu: $e',
      ));
    }
  }

  void selectCategory(String category) {
    emit(state.copyWith(
      selectedCategory: category,
      meals: _computeFilteredMeals(
        allMeals: _allLoadedMeals,
        category: category,
        query: state.searchQuery,
        vegOnly: state.isVegOnly,
        eatRight: state.isEatRightOnly,
        ratings4Plus: state.isRatings4Plus,
        bestseller: state.isBestsellerOnly,
      ),
    ));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(
      searchQuery: query,
      meals: _computeFilteredMeals(
        allMeals: _allLoadedMeals,
        category: state.selectedCategory,
        query: query,
        vegOnly: state.isVegOnly,
        eatRight: state.isEatRightOnly,
        ratings4Plus: state.isRatings4Plus,
        bestseller: state.isBestsellerOnly,
      ),
    ));
  }

  void toggleVegOnly() {
    final next = !state.isVegOnly;
    emit(state.copyWith(
      isVegOnly: next,
      meals: _computeFilteredMeals(
        allMeals: _allLoadedMeals,
        category: state.selectedCategory,
        query: state.searchQuery,
        vegOnly: next,
        eatRight: state.isEatRightOnly,
        ratings4Plus: state.isRatings4Plus,
        bestseller: state.isBestsellerOnly,
      ),
    ));
  }

  void toggleEatRight() {
    final next = !state.isEatRightOnly;
    emit(state.copyWith(
      isEatRightOnly: next,
      meals: _computeFilteredMeals(
        allMeals: _allLoadedMeals,
        category: state.selectedCategory,
        query: state.searchQuery,
        vegOnly: state.isVegOnly,
        eatRight: next,
        ratings4Plus: state.isRatings4Plus,
        bestseller: state.isBestsellerOnly,
      ),
    ));
  }

  void toggleRatings4Plus() {
    final next = !state.isRatings4Plus;
    emit(state.copyWith(
      isRatings4Plus: next,
      meals: _computeFilteredMeals(
        allMeals: _allLoadedMeals,
        category: state.selectedCategory,
        query: state.searchQuery,
        vegOnly: state.isVegOnly,
        eatRight: state.isEatRightOnly,
        ratings4Plus: next,
        bestseller: state.isBestsellerOnly,
      ),
    ));
  }

  void toggleBestseller() {
    final next = !state.isBestsellerOnly;
    emit(state.copyWith(
      isBestsellerOnly: next,
      meals: _computeFilteredMeals(
        allMeals: _allLoadedMeals,
        category: state.selectedCategory,
        query: state.searchQuery,
        vegOnly: state.isVegOnly,
        eatRight: state.isEatRightOnly,
        ratings4Plus: state.isRatings4Plus,
        bestseller: next,
      ),
    ));
  }

  List<FoodItem> _computeFilteredMeals({
    required List<FoodItem> allMeals,
    required String category,
    required String query,
    required bool vegOnly,
    required bool eatRight,
    required bool ratings4Plus,
    required bool bestseller,
  }) {
    return allMeals.where((item) {
      // Category filter
      if (category != 'All' && item.category != category) {
        return false;
      }
      // Pure veg filter
      if (vegOnly && !item.isVeg) {
        return false;
      }
      // Ratings 4.0+
      if (ratings4Plus && item.rating < 4.0) {
        return false;
      }
      // EatRight filter (healthy, low oil, chef special)
      if (eatRight && !item.isVeg && item.rating < 4.8) {
        return false;
      }
      // Bestseller filter
      if (bestseller && item.rating < 4.8) {
        return false;
      }
      // Search query filter
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchName = item.name.toLowerCase().contains(q);
        final matchCategory = item.category.toLowerCase().contains(q);
        final matchDesc = item.description.toLowerCase().contains(q);
        if (!matchName && !matchCategory && !matchDesc) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
