import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/models/models.dart';

class OrderState extends Equatable {
  final List<Order> orders;
  final bool isLoading;

  const OrderState({
    this.orders = const [],
    this.isLoading = false,
  });

  OrderState copyWith({
    List<Order>? orders,
    bool? isLoading,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [orders, isLoading];
}

class OrderCubit extends Cubit<OrderState> {
  OrderCubit() : super(const OrderState()) {
    loadCachedOrders();
  }

  static const String _ordersCacheKey = 'cached_customer_orders';

  Future<void> loadCachedOrders() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final cachedStr = prefs.getString(_ordersCacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final decoded = jsonDecode(cachedStr);
        if (decoded is List) {
          final list = decoded
              .whereType<Map>()
              .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          if (list.isNotEmpty && state.orders.isEmpty) {
            emit(state.copyWith(orders: list));
          }
        }
      }
    } catch (e) {
      appLog("⚠️ Note reading cached orders: $e");
    }
  }

  Future<void> _saveOrdersToCache(List<Order> orders) async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final jsonList = orders.map((o) => o.toJson()).toList();
      await prefs.setString(_ordersCacheKey, jsonEncode(jsonList));
    } catch (e) {
      appLog("⚠️ Note saving orders to cache: $e");
    }
  }

  void addOrder(Order order) {
    final updated = [order, ...state.orders.where((o) => o.id != order.id)];
    emit(state.copyWith(orders: updated));
    _saveOrdersToCache(updated);
  }

  void updateOrderStatus(String orderId, String status) {
    final updated = state.orders.map((o) {
      if (o.id == orderId) {
        return o.copyWith(status: status);
      }
      return o;
    }).toList();
    emit(state.copyWith(orders: updated));
    _saveOrdersToCache(updated);
  }

  Future<void> fetchOrders() async {
    // If state has no orders yet, attempt to read cache first
    if (state.orders.isEmpty) {
      await loadCachedOrders();
    }

    emit(state.copyWith(isLoading: true));
    try {
      final response = await ApiService.dio.get(ApiConstants.customerOrders);
      List<Order> remoteOrders = [];

      if (response.data is Map) {
        final data = response.data as Map;
        final rawOrders = data['orders'] ?? data['data'];
        if (rawOrders is List) {
          remoteOrders = rawOrders
              .whereType<Map>()
              .map((json) => Order.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      } else if (response.data is List) {
        remoteOrders = (response.data as List)
            .whereType<Map>()
            .map((json) => Order.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }

      // Merge remote orders with existing local orders to never lose newly placed orders
      final Map<String, Order> orderMap = {};
      // Remote orders take precedence for status updates
      for (final order in remoteOrders) {
        orderMap[order.id] = order;
      }
      // Add local orders if not already in remote
      for (final order in state.orders) {
        if (!orderMap.containsKey(order.id)) {
          orderMap[order.id] = order;
        }
      }

      final mergedList = orderMap.values.toList()
        ..sort((a, b) => b.orderTime.compareTo(a.orderTime));

      emit(state.copyWith(orders: mergedList, isLoading: false));
      _saveOrdersToCache(mergedList);
    } catch (e) {
      appLog("⚠️ Fetch customer orders notice: $e (serving cached orders)");
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<Order?> fetchOrderDetail(String orderId) async {
    try {
      final cleanId = orderId.replaceAll('#', '');
      final response = await ApiService.dio.get(ApiConstants.customerOrderDetail(cleanId));
      if (response.data is Map) {
        final data = response.data as Map;
        final rawOrder = data['order'] ?? data['data'];
        if (rawOrder is Map) {
          final order = Order.fromJson(Map<String, dynamic>.from(rawOrder));
          return order;
        }
      }
    } catch (e) {
      appLog("⚠️ Fetch order detail notice: $e");
    }
    // Search in current state
    try {
      return state.orders.firstWhere((o) => o.id == orderId || o.id.contains(orderId));
    } catch (_) {
      return null;
    }
  }

  Future<bool> cancelOrder(String orderId, {String reason = 'Changed my mind'}) async {
    emit(state.copyWith(isLoading: true));
    try {
      await ApiService.dio.post(
        ApiConstants.cancelOrder(orderId),
        data: {'reason': reason},
      );
      appLog("✅ Cancelled order $orderId on backend successfully");
      updateOrderStatus(orderId, 'Cancelled');
      emit(state.copyWith(isLoading: false));
      return true;
    } catch (e) {
      appLog("⚠️ Order cancellation backend notice: $e");
      updateOrderStatus(orderId, 'Cancelled');
      emit(state.copyWith(isLoading: false));
      return true;
    }
  }
}
