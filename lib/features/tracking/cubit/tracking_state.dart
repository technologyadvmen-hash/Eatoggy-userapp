import 'package:equatable/equatable.dart';
import '../data/models/order_tracking_model.dart';

class TrackingState extends Equatable {
  final bool isLoading;
  final bool isRefreshing;
  final OrderTrackingModel? trackingData;
  final String? error;
  final DateTime? lastUpdated;

  const TrackingState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.trackingData,
    this.error,
    this.lastUpdated,
  });

  TrackingState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    OrderTrackingModel? trackingData,
    String? error,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return TrackingState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      trackingData: trackingData ?? this.trackingData,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isRefreshing,
        trackingData,
        error,
        lastUpdated,
      ];
}
