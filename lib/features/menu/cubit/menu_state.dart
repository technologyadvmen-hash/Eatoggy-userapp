import 'package:equatable/equatable.dart';
import '../../../shared/models/models.dart';

class MenuState extends Equatable {
  final bool isLoading;
  final List<String> categories;
  final String selectedCategory;
  final List<FoodItem> allMeals;
  final List<FoodItem> meals;
  final List<FoodItem> topPicks;
  final String searchQuery;
  final bool isVegOnly;
  final bool isEatRightOnly;
  final bool isRatings4Plus;
  final bool isBestsellerOnly;

  // Restaurant details
  final String restaurantName;
  final String restaurantCuisine;
  final String restaurantLocation;
  final String deliveryTime;
  final double restaurantRating;
  final String ratingCount;
  final bool isPureVegRestaurant;
  final String offerTitle;
  final String offerSubtitle;
  final int offerCurrentPage;
  final int offerTotalPages;
  final int freeDeliveryAbove;

  final String? error;

  const MenuState({
    this.isLoading = false,
    this.categories = const [
      'All',
      'Royal Thali',
      'Luxe Curries',
      'Biryani & Rice',
      'Heritage Breads',
      'Starters',
      'Desserts',
    ],
    this.selectedCategory = 'All',
    this.allMeals = const [],
    this.meals = const [],
    this.topPicks = const [],
    this.searchQuery = '',
    this.isVegOnly = false,
    this.isEatRightOnly = false,
    this.isRatings4Plus = false,
    this.isBestsellerOnly = false,
    this.restaurantName = 'The Great Kitchen',
    this.restaurantCuisine = 'Italian, North Indian',
    this.restaurantLocation = 'Sector 53, Gurugram',
    this.deliveryTime = '25-30 mins',
    this.restaurantRating = 4.8,
    this.ratingCount = '8.4K+ ratings',
    this.isPureVegRestaurant = false,
    this.offerTitle = '10% off upto ₹75',
    this.offerSubtitle = 'USE VISAPLATINUMDC | ABOVE ₹399',
    this.offerCurrentPage = 5,
    this.offerTotalPages = 5,
    this.freeDeliveryAbove = 99,
    this.error,
  });

  MenuState copyWith({
    bool? isLoading,
    List<String>? categories,
    String? selectedCategory,
    List<FoodItem>? allMeals,
    List<FoodItem>? meals,
    List<FoodItem>? topPicks,
    String? searchQuery,
    bool? isVegOnly,
    bool? isEatRightOnly,
    bool? isRatings4Plus,
    bool? isBestsellerOnly,
    String? restaurantName,
    String? restaurantCuisine,
    String? restaurantLocation,
    String? deliveryTime,
    double? restaurantRating,
    String? ratingCount,
    bool? isPureVegRestaurant,
    String? offerTitle,
    String? offerSubtitle,
    int? offerCurrentPage,
    int? offerTotalPages,
    int? freeDeliveryAbove,
    String? error,
    bool clearError = false,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      allMeals: allMeals ?? this.allMeals,
      meals: meals ?? this.meals,
      topPicks: topPicks ?? this.topPicks,
      searchQuery: searchQuery ?? this.searchQuery,
      isVegOnly: isVegOnly ?? this.isVegOnly,
      isEatRightOnly: isEatRightOnly ?? this.isEatRightOnly,
      isRatings4Plus: isRatings4Plus ?? this.isRatings4Plus,
      isBestsellerOnly: isBestsellerOnly ?? this.isBestsellerOnly,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantCuisine: restaurantCuisine ?? this.restaurantCuisine,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      restaurantRating: restaurantRating ?? this.restaurantRating,
      ratingCount: ratingCount ?? this.ratingCount,
      isPureVegRestaurant: isPureVegRestaurant ?? this.isPureVegRestaurant,
      offerTitle: offerTitle ?? this.offerTitle,
      offerSubtitle: offerSubtitle ?? this.offerSubtitle,
      offerCurrentPage: offerCurrentPage ?? this.offerCurrentPage,
      offerTotalPages: offerTotalPages ?? this.offerTotalPages,
      freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        categories,
        selectedCategory,
        allMeals,
        meals,
        topPicks,
        searchQuery,
        isVegOnly,
        isEatRightOnly,
        isRatings4Plus,
        isBestsellerOnly,
        restaurantName,
        restaurantCuisine,
        restaurantLocation,
        deliveryTime,
        restaurantRating,
        ratingCount,
        isPureVegRestaurant,
        offerTitle,
        offerSubtitle,
        offerCurrentPage,
        offerTotalPages,
        freeDeliveryAbove,
        error,
      ];
}
