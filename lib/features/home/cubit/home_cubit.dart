import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/models/models.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/app_repository.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/logger.dart';
import '../data/models/banner_model.dart';
import '../data/models/collection_model.dart';
import '../data/models/gourmet_dish_model.dart';
import '../data/models/restaurant_model.dart';
import '../data/repositories/discovery_repository.dart';
import '../data/repositories/home_repository.dart';

class HomeState extends Equatable {
  final bool isLoading;
  final bool isGourmetLoading;
  final bool isBannersLoading;
  final bool isRestaurantsLoading;
  final List<FoodItem> featuredMeals;
  final List<Category> categories;
  final List<GourmetDishModel> gourmetCreations;
  final List<RestaurantModel> restaurants;
  final List<BannerModel> banners;
  final List<CollectionModel> collections;
  final String selectedCollection;
  final String? error;
  final Address? deliveryAddress;

  const HomeState({
    this.isLoading = false,
    this.isGourmetLoading = false,
    this.isBannersLoading = false,
    this.isRestaurantsLoading = false,
    this.featuredMeals = const [],
    this.categories = const [],
    this.gourmetCreations = const [],
    this.restaurants = const [],
    this.banners = const [],
    this.collections = const [],
    this.selectedCollection = 'All Meals',
    this.error,
    this.deliveryAddress,
  });

  HomeState copyWith({
    bool? isLoading,
    bool? isGourmetLoading,
    bool? isBannersLoading,
    bool? isRestaurantsLoading,
    List<FoodItem>? featuredMeals,
    List<Category>? categories,
    List<GourmetDishModel>? gourmetCreations,
    List<RestaurantModel>? restaurants,
    List<BannerModel>? banners,
    List<CollectionModel>? collections,
    String? selectedCollection,
    String? error,
    Address? deliveryAddress,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isGourmetLoading: isGourmetLoading ?? this.isGourmetLoading,
      isBannersLoading: isBannersLoading ?? this.isBannersLoading,
      isRestaurantsLoading: isRestaurantsLoading ?? this.isRestaurantsLoading,
      featuredMeals: featuredMeals ?? this.featuredMeals,
      categories: categories ?? this.categories,
      gourmetCreations: gourmetCreations ?? this.gourmetCreations,
      restaurants: restaurants ?? this.restaurants,
      banners: banners ?? this.banners,
      collections: collections ?? this.collections,
      selectedCollection: selectedCollection ?? this.selectedCollection,
      error: error ?? this.error,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isGourmetLoading,
        isBannersLoading,
        isRestaurantsLoading,
        featuredMeals,
        categories,
        gourmetCreations,
        restaurants,
        banners,
        collections,
        selectedCollection,
        error,
        deliveryAddress,
      ];
}

class HomeCubit extends Cubit<HomeState> {
  final AppRepository repository;
  final HomeRepository homeRepository;
  final DiscoveryRepository discoveryRepository;

  HomeCubit(
    this.repository, {
    HomeRepository? homeRepository,
    DiscoveryRepository? discoveryRepository,
  })  : homeRepository = homeRepository ?? HomeRepositoryImpl(),
        discoveryRepository = discoveryRepository ?? DiscoveryRepositoryImpl(),
        super(const HomeState());

  Future<void> loadDashboard() async {
    final futures = Future.wait([
      loadRestaurants(),
      loadGourmetCreations(),
      loadBannersAndCollections(),
    ]);

    if (state.featuredMeals.isNotEmpty && state.categories.isNotEmpty) {
      try {
        final results = await Future.wait([
          repository.getFoodItems(),
          repository.getCategories(),
        ]);
        emit(state.copyWith(
          featuredMeals: results[0] as List<FoodItem>,
          categories: results[1] as List<Category>,
        ));
      } catch (_) {}
      await futures;
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      final results = await Future.wait([
        repository.getFoodItems(),
        repository.getCategories(),
      ]);

      emit(state.copyWith(
        isLoading: false,
        featuredMeals: results[0] as List<FoodItem>,
        categories: results[1] as List<Category>,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to load Dashboard data.'));
    }
    await futures;
  }

  Future<void> loadRestaurants() async {
    emit(state.copyWith(isRestaurantsLoading: true));
    try {
      final list = await discoveryRepository.getRestaurants();
      emit(state.copyWith(
        isRestaurantsLoading: false,
        restaurants: list.isNotEmpty ? list : RestaurantModel.defaultRestaurants(),
      ));
    } catch (_) {
      emit(state.copyWith(
        isRestaurantsLoading: false,
        restaurants: RestaurantModel.defaultRestaurants(),
      ));
    }
  }

  Future<void> loadBannersAndCollections() async {
    emit(state.copyWith(isBannersLoading: true));
    try {
      final results = await Future.wait([
        discoveryRepository.getBanners(),
        discoveryRepository.getCollections(),
      ]);

      final bannersList = results[0] as List<BannerModel>;
      final collectionsList = results[1] as List<CollectionModel>;

      emit(state.copyWith(
        isBannersLoading: false,
        banners: bannersList.isNotEmpty ? bannersList : [BannerModel.defaultHero()],
        collections: collectionsList.isNotEmpty ? collectionsList : CollectionModel.defaultCollections(),
      ));
    } catch (_) {
      emit(state.copyWith(
        isBannersLoading: false,
        banners: [BannerModel.defaultHero()],
        collections: CollectionModel.defaultCollections(),
      ));
    }
  }

  Future<void> loadGourmetCreations() async {
    emit(state.copyWith(isGourmetLoading: true));
    try {
      final response = await homeRepository.getGourmetDishes();
      final gourmetResponse = GetGourmetDishesResponse.fromJson(response.data);

      final List<GourmetDishModel> dishes = [...gourmetResponse.data];

      // If discovery/gourmet returned empty or sparse, also load dishes directly from live backend restaurant menus
      if (dishes.isEmpty) {
        try {
          final restaurants = await discoveryRepository.getRestaurants();
          for (final rest in restaurants) {
            if (rest.id.isNotEmpty && !rest.id.startsWith('dummy_')) {
              try {
                final menuResp = await ApiService.dio.get(ApiConstants.restaurantMenu(rest.id));
                final menuData = menuResp.data;
                dynamic items;
                if (menuData is Map) {
                  items = menuData['data'] ?? menuData['menu'] ?? menuData['items'] ?? menuData['dishes'];
                } else if (menuData is List) {
                  items = menuData;
                }

                if (items is List) {
                  for (final it in items) {
                    if (it is Map) {
                      final itemMap = Map<String, dynamic>.from(it);
                      if (itemMap.containsKey('items') && itemMap['items'] is List) {
                        for (final sub in itemMap['items']) {
                          if (sub is Map) {
                            final subMap = Map<String, dynamic>.from(sub);
                            subMap['restaurantId'] ??= {
                              '_id': rest.id,
                              'restaurantName': rest.name,
                              'cuisine': rest.cuisine,
                              'city': rest.city,
                            };
                            dishes.add(GourmetDishModel.fromJson(subMap));
                          }
                        }
                      } else {
                        itemMap['restaurantId'] ??= {
                          '_id': rest.id,
                          'restaurantName': rest.name,
                          'cuisine': rest.cuisine,
                          'city': rest.city,
                        };
                        dishes.add(GourmetDishModel.fromJson(itemMap));
                      }
                    }
                  }
                }
              } catch (_) {}
            }
          }
        } catch (_) {}
      }

      emit(state.copyWith(
        isGourmetLoading: false,
        gourmetCreations: dishes,
      ));
    } catch (e) {
      appLog("⚠️ loadGourmetCreations note: $e");
      emit(state.copyWith(isGourmetLoading: false));
    }
  }

  void selectCollection(String collectionName) {
    emit(state.copyWith(selectedCollection: collectionName));
  }

  void updateAddress(Address address) {
    emit(state.copyWith(deliveryAddress: address));
  }
}
