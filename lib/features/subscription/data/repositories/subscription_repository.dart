import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../models/customer_subscription_model.dart';
import '../models/get_tiffin_plans_request.dart';
import '../models/initiate_subscription_request.dart';
import '../models/initiate_subscription_response.dart';
import '../models/skip_occurrence_response.dart';
import '../models/verify_subscription_payment_request.dart';
import '../models/verify_subscription_payment_response.dart';

abstract class SubscriptionRepository {
  Future<Response> getTiffinPlans({GetTiffinPlansRequest? request});

  /// POST /api/customers/subscriptions - Initiate subscription checkout
  Future<InitiateSubscriptionResponse> initiateSubscription({
    required InitiateSubscriptionRequest request,
  });

  /// POST /api/customers/subscriptions/verify-payment - Verify Razorpay payment and activate
  Future<VerifySubscriptionPaymentResponse> verifyPayment({
    required VerifySubscriptionPaymentRequest request,
  });

  /// POST /api/customers/subscriptions/:id/occurrences/:occId/skip - Skip daily occurrence
  Future<SkipOccurrenceResponse> skipOccurrence({
    required String subscriptionId,
    required String occurrenceId,
  });

  /// PATCH /api/customers/subscriptions/:id/pause - Pause active subscription
  Future<Response> pauseSubscription(String subscriptionId);

  /// PATCH /api/customers/subscriptions/:id/resume - Resume paused subscription
  Future<Response> resumeSubscription(String subscriptionId);

  /// PATCH /api/customers/subscriptions/:id/cancel - Cancel active subscription
  Future<Response> cancelSubscription(String subscriptionId);

  /// GET /api/customers/subscriptions - Fetch customer active/past subscriptions
  Future<List<CustomerSubscriptionModel>> getMySubscriptions();

  /// GET /api/customers/subscriptions/:id - Fetch subscription detail with timeline
  Future<CustomerSubscriptionModel?> getSubscriptionDetail(String subscriptionId);
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  @override
  Future<Response> getTiffinPlans({GetTiffinPlansRequest? request}) {
    final queryParams = request?.toJson();
    return ApiService.dio.get(
      ApiConstants.tiffinPlans,
      queryParameters: (queryParams != null && queryParams.isNotEmpty)
          ? queryParams
          : null,
    );
  }

  @override
  Future<InitiateSubscriptionResponse> initiateSubscription({
    required InitiateSubscriptionRequest request,
  }) async {
    try {
      appLog("🚀 POST Initiating subscription checkout for plan: ${request.planId}");
      final response = await ApiService.dio.post(
        ApiConstants.customerSubscriptions,
        data: request.toJson(),
      );

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      return InitiateSubscriptionResponse.fromJson(data);
    } catch (e) {
      appLog("❌ Error initiating subscription: $e");
      rethrow;
    }
  }

  @override
  Future<VerifySubscriptionPaymentResponse> verifyPayment({
    required VerifySubscriptionPaymentRequest request,
  }) async {
    try {
      appLog("🔐 POST Verifying subscription payment for sub: ${request.subscriptionId}");
      final response = await ApiService.dio.post(
        ApiConstants.verifySubscriptionPayment,
        data: request.toJson(),
      );

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      return VerifySubscriptionPaymentResponse.fromJson(data);
    } catch (e) {
      appLog("❌ Error verifying subscription payment: $e");
      rethrow;
    }
  }

  @override
  Future<SkipOccurrenceResponse> skipOccurrence({
    required String subscriptionId,
    required String occurrenceId,
  }) async {
    try {
      final endpoint = ApiConstants.skipSubscriptionOccurrence(subscriptionId, occurrenceId);
      appLog("⏭️ POST Skipping occurrence $occurrenceId on sub $subscriptionId");
      final response = await ApiService.dio.post(
        endpoint,
        data: {},
      );

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      return SkipOccurrenceResponse.fromJson(data);
    } catch (e) {
      appLog("❌ Error skipping occurrence: $e");
      rethrow;
    }
  }

  @override
  Future<Response> pauseSubscription(String subscriptionId) {
    final endpoint = ApiConstants.pauseSubscription(subscriptionId);
    return ApiService.dio.patch(endpoint);
  }

  @override
  Future<Response> resumeSubscription(String subscriptionId) {
    final endpoint = ApiConstants.resumeSubscription(subscriptionId);
    return ApiService.dio.patch(endpoint);
  }

  @override
  Future<Response> cancelSubscription(String subscriptionId) {
    final endpoint = ApiConstants.cancelSubscription(subscriptionId);
    return ApiService.dio.patch(endpoint);
  }

  @override
  Future<List<CustomerSubscriptionModel>> getMySubscriptions() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.customerSubscriptions);
      final data = response.data;
      List<CustomerSubscriptionModel> results = [];

      dynamic listPayload;
      if (data is Map) {
        final innerData = data['data'];
        if (innerData is List) {
          listPayload = innerData;
        } else if (innerData is Map) {
          listPayload = innerData['subscriptions'] ??
              innerData['items'] ??
              innerData['data'] ??
              innerData['list'];
        }
        listPayload ??= data['subscriptions'] ?? data['items'] ?? data['data'];
      } else if (data is List) {
        listPayload = data;
      }

      if (listPayload is List) {
        for (final item in listPayload) {
          if (item is Map<String, dynamic>) {
            results.add(CustomerSubscriptionModel.fromJson(item));
          } else if (item is Map) {
            results.add(CustomerSubscriptionModel.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      appLog("📦 Parsed ${results.length} customer subscriptions from backend");
      return results;
    } catch (e) {
      appLog("⚠️ Note retrieving customer subscriptions: $e");
      return [];
    }
  }

  @override
  Future<CustomerSubscriptionModel?> getSubscriptionDetail(String subscriptionId) async {
    try {
      final endpoint = ApiConstants.customerSubscriptionDetail(subscriptionId);
      final response = await ApiService.dio.get(endpoint);
      final dynamic data = response.data;

      Map<String, dynamic> rawMap = {};
      if (data is Map<String, dynamic>) {
        rawMap = data;
      } else if (data is Map) {
        rawMap = Map<String, dynamic>.from(data);
      }

      return CustomerSubscriptionModel.fromJson(rawMap);
    } catch (e) {
      appLog("⚠️ Note retrieving subscription detail: $e");
      return null;
    }
  }
}
