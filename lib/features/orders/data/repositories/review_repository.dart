import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../models/customer_review_model.dart';
import '../models/order_review_request.dart';
import '../models/order_review_response.dart';

abstract class ReviewRepository {
  /// POST /api/customers/orders/:orderId/review - Submit order review
  Future<OrderReviewResponse> submitOrderReview({
    required String orderId,
    required OrderReviewRequest request,
  });

  /// GET /api/customers/reviews - Fetch customer review history
  Future<List<CustomerReviewModel>> getMyReviews();
}

class ReviewRepositoryImpl implements ReviewRepository {
  @override
  Future<OrderReviewResponse> submitOrderReview({
    required String orderId,
    required OrderReviewRequest request,
  }) async {
    try {
      final endpoint = ApiConstants.orderReview(orderId);
      appLog("🌟 POST Submitting review for order $orderId to $endpoint");
      final response = await ApiService.dio.post(
        endpoint,
        data: request.toJson(),
      );

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      return OrderReviewResponse.fromJson(data);
    } catch (e) {
      appLog("❌ Error submitting order review: $e");
      rethrow;
    }
  }

  @override
  Future<List<CustomerReviewModel>> getMyReviews() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.customerReviews);
      final data = response.data;
      List<CustomerReviewModel> results = [];

      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        final payload = data['data'] ?? data['reviews'] ?? data['items'];
        if (payload is List) list = payload;
      } else if (data is List) {
        list = data;
      }

      for (final item in list) {
        if (item is Map<String, dynamic>) {
          results.add(CustomerReviewModel.fromJson(item));
        } else if (item is Map) {
          results.add(CustomerReviewModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }

      return results;
    } catch (e) {
      appLog("⚠️ Note fetching customer reviews: $e");
      return [];
    }
  }
}
