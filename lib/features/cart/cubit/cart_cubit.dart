import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/models.dart';
import '../data/models/add_to_cart_request.dart';
import '../data/models/add_to_cart_response.dart';
import '../data/models/get_cart_response.dart';
import '../data/models/update_cart_item_request.dart';
import '../data/models/update_cart_item_response.dart';
import '../data/models/remove_cart_item_response.dart';
import '../data/repositories/cart_repository.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final Coupon? appliedCoupon;
  final bool isLoading;
  final bool isAdding;
  final String? restaurantId;
  final String? error;

  const CartState({
    this.items = const [],
    this.appliedCoupon,
    this.isLoading = false,
    this.isAdding = false,
    this.restaurantId,
    this.error,
  });

  double get subtotal => items.fold(0.0, (val, element) => val + element.totalPrice);
  double get discountAmount {
    if (appliedCoupon == null) return 0.0;
    double calc = subtotal * (appliedCoupon!.discountPercent / 100);
    return calc > appliedCoupon!.maxDiscount ? appliedCoupon!.maxDiscount : calc;
  }
  double get total => subtotal - discountAmount;

  CartState copyWith({
    List<CartItem>? items,
    Coupon? appliedCoupon,
    bool clearCoupon = false,
    bool? isLoading,
    bool? isAdding,
    String? restaurantId,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      isLoading: isLoading ?? this.isLoading,
      isAdding: isAdding ?? this.isAdding,
      restaurantId: restaurantId ?? this.restaurantId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [items, appliedCoupon, isLoading, isAdding, restaurantId, error];
}

class CartCubit extends Cubit<CartState> {
  final CartRepository cartRepository;

  CartCubit({CartRepository? cartRepository})
      : cartRepository = cartRepository ?? CartRepositoryImpl(),
        super(const CartState()) {
    loadCachedCart();
  }

  Future<void> loadCachedCart() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final cachedStr = prefs.getString('cached_customer_cart');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final decoded = jsonDecode(cachedStr);
        if (decoded is List && decoded.isNotEmpty) {
          final cachedItems = decoded
              .whereType<Map>()
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          if (cachedItems.isNotEmpty && state.items.isEmpty) {
            emit(state.copyWith(items: cachedItems));
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCartToCache(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
      await prefs.setString('cached_customer_cart', encoded);
    } catch (_) {}
  }

  List<CartItem> _mergeItems(List<CartItem> currentList, List<CartItem> serverList) {
    final result = List<CartItem>.from(currentList);
    for (final sItem in serverList) {
      final idx = result.indexWhere((c) =>
          (c.cartItemId != null && sItem.cartItemId != null && c.cartItemId == sItem.cartItemId) ||
          c.food.id == sItem.food.id ||
          c.food.name.toLowerCase().trim() == sItem.food.name.toLowerCase().trim());
      if (idx >= 0) {
        final existing = result[idx];
        result[idx] = existing.copyWith(
          cartItemId: sItem.cartItemId ?? existing.cartItemId,
          quantity: existing.quantity > 0 ? existing.quantity : sItem.quantity,
          food: existing.food.restaurantId != null ? existing.food : sItem.food,
        );
      } else {
        result.add(sItem);
      }
    }
    return result;
  }

  Future<GetCartResponse?> fetchCart() async {
    if (state.items.isEmpty) {
      await loadCachedCart();
    }
    emit(state.copyWith(isLoading: state.items.isEmpty, error: null));
    try {
      final response = await cartRepository.getCart();
      if (response.success && response.data != null) {
        final backendItems = response.data!.items.map((i) => i.toCartItem()).toList();
        final merged = _mergeItems(state.items, backendItems);
        emit(state.copyWith(
          isLoading: false,
          items: merged,
          restaurantId: response.data!.restaurantId ?? state.restaurantId,
        ));
        await _saveCartToCache(merged);
      } else {
        emit(state.copyWith(isLoading: false));
      }
      return response;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
      ));
      return null;
    }
  }

  Future<AddToCartResponse?> addToCart(FoodItem food, {int quantity = 1}) async {
    final validQuantity = quantity < 1 ? 1 : quantity;

    // 1. Optimistic update
    final index = state.items.indexWhere((e) =>
        e.food.id == food.id ||
        e.food.name.toLowerCase().trim() == food.name.toLowerCase().trim());
    List<CartItem> updatedList;
    if (index >= 0) {
      updatedList = List<CartItem>.from(state.items);
      updatedList[index] = updatedList[index].copyWith(
        quantity: updatedList[index].quantity + validQuantity,
      );
    } else {
      updatedList = [
        ...state.items,
        CartItem(food: food, quantity: validQuantity),
      ];
    }
    emit(state.copyWith(items: updatedList));
    await _saveCartToCache(updatedList);

    // 2. Sync with backend API
    try {
      emit(state.copyWith(isAdding: true));
      final request = AddToCartRequest(
        menuItemId: food.id,
        quantity: validQuantity,
      );
      final response = await cartRepository.addToCart(request);
      if (response.success && response.data != null && response.data!.items.isNotEmpty) {
        final syncedItems = response.data!.items.map((i) => i.toCartItem()).toList();
        final merged = _mergeItems(state.items, syncedItems);
        emit(state.copyWith(
          isAdding: false,
          items: merged,
          restaurantId: response.data!.restaurantId ?? state.restaurantId,
        ));
        await _saveCartToCache(merged);
      } else {
        emit(state.copyWith(isAdding: false));
      }
      return response;
    } catch (e) {
      // Retain optimistic item in cart! Do not discard!
      emit(state.copyWith(isAdding: false));
      return null;
    }
  }

  Future<AddToCartResponse?> addToCartByMenuItemId({
    required String menuItemId,
    int quantity = 1,
  }) async {
    final validQuantity = quantity < 1 ? 1 : quantity;

    try {
      emit(state.copyWith(isAdding: true));
      final request = AddToCartRequest(
        menuItemId: menuItemId,
        quantity: validQuantity,
      );
      final response = await cartRepository.addToCart(request);
      if (response.success && response.data != null && response.data!.items.isNotEmpty) {
        final syncedItems = response.data!.items.map((i) => i.toCartItem()).toList();
        final merged = _mergeItems(state.items, syncedItems);
        emit(state.copyWith(
          isAdding: false,
          items: merged,
          restaurantId: response.data!.restaurantId ?? state.restaurantId,
        ));
        await _saveCartToCache(merged);
      } else {
        emit(state.copyWith(isAdding: false));
      }
      return response;
    } catch (e) {
      emit(state.copyWith(isAdding: false));
      return null;
    }
  }

  Future<dynamic> updateQuantity(dynamic itemOrFood, int newQty) async {
    if (newQty <= 0) {
      return await removeFromCart(itemOrFood);
    }
    final validQty = newQty;

    CartItem? cartItem;
    FoodItem? food;

    if (itemOrFood is CartItem) {
      cartItem = itemOrFood;
      food = itemOrFood.food;
    } else if (itemOrFood is FoodItem) {
      food = itemOrFood;
      final idx = state.items.indexWhere((e) =>
          e.food.id == itemOrFood.id ||
          e.food.name.toLowerCase().trim() == itemOrFood.name.toLowerCase().trim());
      if (idx >= 0) {
        cartItem = state.items[idx];
      }
    }

    if (cartItem == null && food == null) return null;

    final String itemId = (cartItem?.cartItemId != null && cartItem!.cartItemId!.isNotEmpty)
        ? cartItem.cartItemId!
        : (food?.id ?? '');

    // 1. Optimistic update
    final updatedList = state.items.map((e) {
      final matchesCartItem = cartItem != null &&
          ((cartItem.cartItemId != null && cartItem.cartItemId == e.cartItemId) ||
              cartItem.food.id == e.food.id ||
              cartItem.food.name.toLowerCase().trim() == e.food.name.toLowerCase().trim());
      final matchesFood = food != null &&
          (e.food.id == food.id ||
              e.food.name.toLowerCase().trim() == food.name.toLowerCase().trim());

      if (matchesCartItem || matchesFood) {
        return e.copyWith(quantity: validQty);
      }
      return e;
    }).toList();

    emit(state.copyWith(items: updatedList));
    await _saveCartToCache(updatedList);

    // 2. Call backend API if possible
    if (itemId.isNotEmpty) {
      try {
        final request = UpdateCartItemRequest(quantity: validQty);
        UpdateCartItemResponse? response;
        try {
          response = await cartRepository.updateCartItem(itemId, request);
        } catch (_) {
          if (food != null && food.id.isNotEmpty && food.id != itemId) {
            response = await cartRepository.updateCartItem(food.id, request);
          }
        }

        if (response != null &&
            response.success &&
            response.data != null &&
            response.data!.items.isNotEmpty) {
          final syncedItems =
              response.data!.items.map((i) => i.toCartItem()).toList();
          final merged = _mergeItems(state.items, syncedItems);
          emit(state.copyWith(
            items: merged,
            restaurantId: response.data!.restaurantId ?? state.restaurantId,
          ));
          await _saveCartToCache(merged);
        }
        return response;
      } catch (_) {
        // Do NOT revert! Retain local state
      }
    }

    return null;
  }

  Future<RemoveCartItemResponse?> removeFromCart(dynamic itemOrFood) async {
    CartItem? cartItem;
    FoodItem? food;

    if (itemOrFood is CartItem) {
      cartItem = itemOrFood;
      food = itemOrFood.food;
    } else if (itemOrFood is FoodItem) {
      food = itemOrFood;
      final idx = state.items.indexWhere((e) =>
          e.food.id == itemOrFood.id ||
          e.food.name.toLowerCase().trim() == itemOrFood.name.toLowerCase().trim());
      if (idx >= 0) {
        cartItem = state.items[idx];
      }
    }

    if (cartItem == null && food == null) return null;

    final String itemId = (cartItem?.cartItemId != null && cartItem!.cartItemId!.isNotEmpty)
        ? cartItem.cartItemId!
        : (food?.id ?? '');

    // 1. Optimistic removal
    final updatedList = state.items.where((e) {
      final matchesCartItem = cartItem != null &&
          ((cartItem.cartItemId != null && cartItem.cartItemId == e.cartItemId) ||
              cartItem.food.id == e.food.id ||
              cartItem.food.name.toLowerCase().trim() == e.food.name.toLowerCase().trim());
      final matchesFood = food != null &&
          (e.food.id == food.id ||
              e.food.name.toLowerCase().trim() == food.name.toLowerCase().trim());
      return !(matchesCartItem || matchesFood);
    }).toList();

    emit(state.copyWith(
      items: updatedList,
      restaurantId: updatedList.isEmpty ? null : state.restaurantId,
    ));
    await _saveCartToCache(updatedList);

    // 2. Call backend API
    if (itemId.isNotEmpty) {
      try {
        RemoveCartItemResponse? response;
        try {
          response = await cartRepository.removeCartItem(itemId);
        } catch (_) {
          if (food != null && food.id.isNotEmpty && food.id != itemId) {
            response = await cartRepository.removeCartItem(food.id);
          }
        }

        if (response != null && response.success && response.data != null) {
          final syncedItems =
              response.data!.items.map((i) => i.toCartItem()).toList();
          final merged = _mergeItems(state.items, syncedItems);
          emit(state.copyWith(
            items: merged,
            restaurantId: response.data!.restaurantId ?? state.restaurantId,
          ));
          await _saveCartToCache(merged);
        }
        return response;
      } catch (_) {
        // Do NOT revert! Retain local state
      }
    }

    return null;
  }

  void applyCoupon(Coupon coupon) {
    if (state.subtotal >= coupon.minOrderValue) {
      emit(state.copyWith(appliedCoupon: coupon));
    }
  }

  void removeCoupon() {
    emit(state.copyWith(clearCoupon: true));
  }

  Future<void> clearCart() async {
    emit(const CartState());
    await _saveCartToCache([]);
    try {
      await cartRepository.clearCart();
    } catch (_) {
      // Best effort - local state is already cleared
    }
  }
}
