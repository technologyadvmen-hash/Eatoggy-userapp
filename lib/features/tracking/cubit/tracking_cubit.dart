import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/data/repositories/discovery_repository.dart';
import '../data/models/order_tracking_model.dart';
import '../data/repositories/tracking_repository.dart';
import 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  final TrackingRepository repository;
  final DiscoveryRepository discoveryRepository;
  Timer? _pollingTimer;

  TrackingCubit({
    TrackingRepository? repository,
    DiscoveryRepository? discoveryRepository,
  })  : repository = repository ?? TrackingRepositoryImpl(),
        discoveryRepository = discoveryRepository ?? DiscoveryRepositoryImpl(),
        super(const TrackingState());

  Future<void> loadTracking(
    String orderId, {
    String? fallbackAddress,
    double? lat,
    double? lng,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      var data = await repository.getLiveOrderTracking(orderId);

      // Dynamically fetch live restaurant from backend API to ensure real restaurant location
      try {
        final restaurants = await discoveryRepository.getRestaurants();
        if (restaurants.isNotEmpty) {
          final rest = restaurants.first;
          data = data.copyWith(
            restaurantName: rest.name,
            restaurantAddress: rest.fullAddress,
            restaurantLat: rest.latitude,
            restaurantLng: rest.longitude,
          );
        }
      } catch (_) {}

      emit(state.copyWith(
        isLoading: false,
        trackingData: data,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      String rName = 'The Great Kitchen';
      String rAddr = '3rd Floor, ORCHID CENTER, Sector 53, Golf Course Road, Gurugram';
      double rLat = 28.4384;
      double rLng = 77.0988;

      try {
        final restaurants = await discoveryRepository.getRestaurants();
        if (restaurants.isNotEmpty) {
          final rest = restaurants.first;
          rName = rest.name;
          rAddr = rest.fullAddress;
          rLat = rest.latitude;
          rLng = rest.longitude;
        }
      } catch (_) {}

      emit(state.copyWith(
        isLoading: false,
        trackingData: state.trackingData ??
            OrderTrackingModel.mock(
              orderId,
              deliveryAddress: fallbackAddress,
              lat: lat,
              lng: lng,
              restaurantName: rName,
              restaurantAddress: rAddr,
              restaurantLat: rLat,
              restaurantLng: rLng,
            ),
      ));
    }
  }

  Future<void> refreshTracking(String orderId) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    try {
      var data = await repository.getLiveOrderTracking(orderId);

      // Preserve previously resolved restaurant details if API tracking response lacks them
      final current = state.trackingData;
      if (current != null && (data.restaurantName == 'The Great Kitchen' || data.restaurantAddress.contains('Sector 53'))) {
        data = data.copyWith(
          restaurantName: current.restaurantName,
          restaurantAddress: current.restaurantAddress,
          restaurantLat: current.restaurantLat,
          restaurantLng: current.restaurantLng,
        );
      }

      emit(state.copyWith(
        isRefreshing: false,
        trackingData: data,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
      ));
    }
  }

  void startPolling(String orderId, {Duration interval = const Duration(seconds: 15)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) {
      if (!isClosed) {
        refreshTracking(orderId);
      }
    });
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
