import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/models/models.dart';
import '../../../core/network/app_repository.dart';
import '../../../core/services/app_config_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/logger.dart';
import '../data/models/customer_subscription_model.dart';
import '../data/models/get_tiffin_plans_request.dart';
import '../data/models/get_tiffin_plans_response.dart';
import '../data/models/initiate_subscription_request.dart';
import '../data/models/initiate_subscription_response.dart';
import '../data/models/verify_subscription_payment_request.dart';
import '../data/repositories/subscription_repository.dart';

class SubscriptionState extends Equatable {
  final bool isLoading;
  final bool isInitiating;
  final bool isVerifying;
  final bool isSkipping;
  final bool isMutating;
  final List<SubscriptionPlan> plans;
  final List<Subscription> mySubscriptions;
  final Subscription? activeSubscription;
  final InitiateSubscriptionResponse? initiatedCheckout;
  final String? error;
  final String? actionMessage;

  const SubscriptionState({
    this.isLoading = false,
    this.isInitiating = false,
    this.isVerifying = false,
    this.isSkipping = false,
    this.isMutating = false,
    this.plans = const [],
    this.mySubscriptions = const [],
    this.activeSubscription,
    this.initiatedCheckout,
    this.error,
    this.actionMessage,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    bool? isInitiating,
    bool? isVerifying,
    bool? isSkipping,
    bool? isMutating,
    List<SubscriptionPlan>? plans,
    List<Subscription>? mySubscriptions,
    Subscription? activeSubscription,
    InitiateSubscriptionResponse? initiatedCheckout,
    String? error,
    bool clearError = false,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isInitiating: isInitiating ?? this.isInitiating,
      isVerifying: isVerifying ?? this.isVerifying,
      isSkipping: isSkipping ?? this.isSkipping,
      isMutating: isMutating ?? this.isMutating,
      plans: plans ?? this.plans,
      mySubscriptions: mySubscriptions ?? this.mySubscriptions,
      activeSubscription: activeSubscription ?? this.activeSubscription,
      initiatedCheckout: initiatedCheckout ?? this.initiatedCheckout,
      error: clearError ? null : (error ?? this.error),
      actionMessage: clearActionMessage ? null : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isInitiating,
        isVerifying,
        isSkipping,
        isMutating,
        plans,
        mySubscriptions,
        activeSubscription,
        initiatedCheckout,
        error,
        actionMessage,
      ];
}

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final AppRepository? appRepository;
  final SubscriptionRepository subscriptionRepository;
  static const String _subscriptionsCacheKey = 'cached_customer_subscriptions';

  SubscriptionCubit([
    AppRepository? appRepository,
    SubscriptionRepository? subscriptionRepository,
  ])  : appRepository = appRepository ?? MockAppRepository(),
        subscriptionRepository = subscriptionRepository ?? SubscriptionRepositoryImpl(),
        super(const SubscriptionState()) {
    loadCachedSubscriptions();
    loadPlans();
    loadMySubscriptions();
  }

  Future<void> loadCachedSubscriptions() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final cachedStr = prefs.getString(_subscriptionsCacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final decoded = jsonDecode(cachedStr);
        if (decoded is List) {
          final list = decoded
              .whereType<Map>()
              .map((e) => CustomerSubscriptionModel.fromJson(Map<String, dynamic>.from(e)).toSubscriptionEntity())
              .toList();
          if (list.isNotEmpty && state.mySubscriptions.isEmpty) {
            final firstActive = list.firstWhere(
              (s) => s.status.toUpperCase() == 'ACTIVE',
              orElse: () => list.first,
            );
            emit(state.copyWith(
              mySubscriptions: list,
              activeSubscription: firstActive,
            ));
          }
        }
      }
    } catch (e) {
      appLog("⚠️ Note reading cached subscriptions: $e");
    }
  }

  Future<void> _saveSubscriptionsToCache(List<CustomerSubscriptionModel> subs) async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      final jsonList = subs.map((s) => s.toJson()).toList();
      await prefs.setString(_subscriptionsCacheKey, jsonEncode(jsonList));
    } catch (e) {
      appLog("⚠️ Note saving subscriptions to cache: $e");
    }
  }

  /// GET /api/customers/tiffin-plans - Discover available royal tiffin plans
  Future<void> loadPlans({String? mealType, String? status}) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await subscriptionRepository.getTiffinPlans(
        request: GetTiffinPlansRequest(mealType: mealType, status: status),
      );

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      final tiffinResponse = GetTiffinPlansResponse.fromJson(data);

      if (tiffinResponse.data != null && tiffinResponse.data!.plans.isNotEmpty) {
        final convertedPlans = tiffinResponse.data!.plans.map((p) => p.toSubscriptionPlan()).toList();
        emit(state.copyWith(isLoading: false, plans: convertedPlans));
        return;
      }
    } catch (e) {
      appLog("⚠️ Note fetching tiffin plans from server: $e - loading fallback");
    }

    // Fallback if network is unavailable or returned empty
    try {
      final plans = await (appRepository ?? MockAppRepository()).getSubscriptionPlans();
      emit(state.copyWith(isLoading: false, plans: plans));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to retrieve plans.'));
    }
  }

  /// POST: Initiate subscription checkout session with server
  Future<InitiateSubscriptionResponse?> initiateSubscriptionCheckout({
    required String planId,
    required String addressId,
    String? startDate,
  }) async {
    emit(state.copyWith(isInitiating: true, clearError: true));
    try {
      final formattedDate = startDate ??
          DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);

      final request = InitiateSubscriptionRequest(
        planId: planId,
        addressId: addressId,
        startDate: formattedDate,
      );

      final response = await subscriptionRepository.initiateSubscription(request: request);
      if (response.razorpayKey != null && response.razorpayKey!.isNotEmpty) {
        AppConfigService.instance.setRazorpayKey(response.razorpayKey);
      }
      emit(state.copyWith(
        isInitiating: false,
        initiatedCheckout: response,
        actionMessage: response.message,
      ));
      return response;
    } catch (e) {
      appLog("⚠️ Error in initiateSubscriptionCheckout: $e");
      emit(state.copyWith(
        isInitiating: false,
        error: 'Failed to initiate subscription checkout. Please try again.',
      ));
      return null;
    }
  }

  /// POST: Verify Razorpay payment signature & activate subscription
  Future<bool> verifyPaymentAndActivate({
    required String subscriptionId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    SubscriptionPlan? fallbackPlan,
  }) async {
    emit(state.copyWith(isVerifying: true, clearError: true));
    try {
      final request = VerifySubscriptionPaymentRequest(
        subscriptionId: subscriptionId,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

      final response = await subscriptionRepository.verifyPayment(request: request);

      Subscription activeSub;
      if (response.subscription != null) {
        activeSub = response.subscription!.toSubscriptionEntity(fallbackPlan: fallbackPlan);
      } else {
        // Fallback with provided plan
        final p = fallbackPlan ?? (state.plans.isNotEmpty ? state.plans.first : null);
        activeSub = Subscription(
          id: subscriptionId,
          plan: p ??
              const SubscriptionPlan(
                id: 'plan_default',
                name: 'Royal Meal Pass',
                pricePerMeal: 250,
                totalMeals: 7,
                durationDays: 7,
                deliveryDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                benefits: ['Fresh gourmet meals'],
              ),
          status: 'Active',
          remainingMeals: p?.totalMeals ?? 7,
          nextDelivery: DateTime.now().add(const Duration(days: 1)),
          schedule: List.generate(
            p?.totalMeals ?? 7,
            (i) => SubscriptionCalendarDay(
              occurrenceId: 'occ_$i',
              date: DateTime.now().add(Duration(days: i + 1)),
              status: 'Upcoming',
            ),
          ),
        );
      }

      emit(state.copyWith(
        isVerifying: false,
        activeSubscription: activeSub,
        mySubscriptions: [activeSub, ...state.mySubscriptions.where((s) => s.id != activeSub.id)],
        actionMessage: response.message.isNotEmpty ? response.message : 'Subscription activated!',
      ));
      return true;
    } catch (e) {
      appLog("⚠️ Error in verifyPaymentAndActivate: $e");
      emit(state.copyWith(
        isVerifying: false,
        error: 'Payment verification failed. Please contact support.',
      ));
      return false;
    }
  }

  /// POST: Skip a specific daily meal occurrence
  Future<bool> skipOccurrence({
    required String subscriptionId,
    required String occurrenceId,
    DateTime? date,
  }) async {
    emit(state.copyWith(isSkipping: true, clearError: true));
    try {
      // Optimistic update of local schedule
      _markOccurrenceSkipped(occurrenceId, date);

      await subscriptionRepository.skipOccurrence(
        subscriptionId: subscriptionId,
        occurrenceId: occurrenceId,
      );

      emit(state.copyWith(
        isSkipping: false,
        actionMessage: 'Scheduled meal skipped successfully.',
      ));
      return true;
    } catch (e) {
      appLog("⚠️ Note skipping occurrence on server: $e");
      emit(state.copyWith(
        isSkipping: false,
        actionMessage: 'Occurrence marked as skipped.',
      ));
      return true;
    }
  }

  void _markOccurrenceSkipped(String occurrenceId, DateTime? date) {
    if (state.activeSubscription == null) return;
    final updatedSchedule = state.activeSubscription!.schedule.map((day) {
      final matchesId = day.occurrenceId == occurrenceId;
      final matchesDate = date != null &&
          day.date.year == date.year &&
          day.date.month == date.month &&
          day.date.day == date.day;

      if (matchesId || matchesDate) {
        return day.copyWith(status: 'Skipped');
      }
      return day;
    }).toList();

    emit(state.copyWith(
      activeSubscription: state.activeSubscription!.copyWith(schedule: updatedSchedule),
    ));
  }

  /// PATCH: Pause subscription deliveries
  Future<void> pauseSubscription() async {
    final sub = state.activeSubscription;
    if (sub == null) return;

    emit(state.copyWith(
      activeSubscription: sub.copyWith(status: 'Paused'),
      isMutating: true,
    ));

    try {
      await subscriptionRepository.pauseSubscription(sub.id);
    } catch (e) {
      appLog("⚠️ Server pause note: $e (optimistic state maintained)");
    } finally {
      emit(state.copyWith(isMutating: false));
    }
  }

  /// PATCH: Resume subscription deliveries
  Future<void> resumeSubscription() async {
    final sub = state.activeSubscription;
    if (sub == null) return;

    emit(state.copyWith(
      activeSubscription: sub.copyWith(status: 'Active'),
      isMutating: true,
    ));

    try {
      await subscriptionRepository.resumeSubscription(sub.id);
    } catch (e) {
      appLog("⚠️ Server resume note: $e (optimistic state maintained)");
    } finally {
      emit(state.copyWith(isMutating: false));
    }
  }

  /// PATCH: Cancel active subscription
  Future<void> cancelSubscription() async {
    final sub = state.activeSubscription;
    if (sub == null) return;

    emit(state.copyWith(
      activeSubscription: sub.copyWith(status: 'Cancelled'),
      isMutating: true,
    ));

    try {
      await subscriptionRepository.cancelSubscription(sub.id);
    } catch (e) {
      appLog("⚠️ Server cancel note: $e");
    } finally {
      emit(state.copyWith(isMutating: false));
    }
  }

  /// GET /api/customers/subscriptions - Load active and past subscriptions
  Future<void> loadMySubscriptions() async {
    if (state.mySubscriptions.isEmpty) {
      await loadCachedSubscriptions();
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final subs = await subscriptionRepository.getMySubscriptions();
      if (subs.isNotEmpty) {
        _saveSubscriptionsToCache(subs);
        final convertedList = subs.map((s) => s.toSubscriptionEntity()).toList();
        final firstActive = convertedList.firstWhere(
          (s) => s.status.toUpperCase() == 'ACTIVE',
          orElse: () => convertedList.first,
        );

        emit(state.copyWith(
          isLoading: false,
          mySubscriptions: convertedList,
          activeSubscription: firstActive,
        ));

        // Fetch detailed occurrence timeline for the active subscription
        await fetchSubscriptionTimeline(firstActive.id);
        return;
      }
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      appLog("⚠️ Error loading customer subscriptions: $e");
      emit(state.copyWith(isLoading: false));
    }
  }

  /// GET /api/customers/subscriptions/:id - Fetch detailed subscription timeline
  Future<void> fetchSubscriptionTimeline(String subscriptionId) async {
    try {
      final detail = await subscriptionRepository.getSubscriptionDetail(subscriptionId);
      if (detail != null) {
        final subEntity = detail.toSubscriptionEntity(
          fallbackPlan: state.activeSubscription?.plan,
        );
        emit(state.copyWith(activeSubscription: subEntity));
      }
    } catch (e) {
      appLog("⚠️ Note fetching subscription timeline: $e");
    }
  }

  void activateSubscription(Subscription sub) {
    emit(state.copyWith(
      activeSubscription: sub,
      mySubscriptions: [sub, ...state.mySubscriptions.where((s) => s.id != sub.id)],
    ));
  }

  void skipDay(DateTime date) {
    if (state.activeSubscription == null) return;
    skipOccurrence(
      subscriptionId: state.activeSubscription!.id,
      occurrenceId: 'occ_${date.millisecondsSinceEpoch}',
      date: date,
    );
  }
}
