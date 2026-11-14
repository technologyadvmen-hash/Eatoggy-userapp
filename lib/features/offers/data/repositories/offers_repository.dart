import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/models/models.dart';

abstract class OffersRepository {
  Future<List<Coupon>> getOffers();
  Future<Map<String, dynamic>?> applyCoupon(String couponCode);
}

class OffersRepositoryImpl implements OffersRepository {
  @override
  Future<List<Coupon>> getOffers() async {
    try {
      final response = await ApiService.dio.get(ApiConstants.offers);
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final offersList = data['offers'] ?? data['coupons'] ?? data['data'];
        if (offersList is List) {
          return offersList
              .whereType<Map<String, dynamic>>()
              .map((e) => Coupon.fromJson(e))
              .toList();
        }
      } else if (response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => Coupon.fromJson(e))
            .toList();
      }
    } catch (e) {
      appLog("⚠️ getOffers error: $e");
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>?> applyCoupon(String couponCode) async {
    try {
      final response = await ApiService.dio.post(
        ApiConstants.applyCoupon,
        data: {'couponCode': couponCode},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      appLog("⚠️ applyCoupon error: ${e.response?.data ?? e.message}");
      if (e.response?.data is Map<String, dynamic>) {
        return e.response!.data as Map<String, dynamic>;
      }
      rethrow;
    } catch (e) {
      appLog("⚠️ Unexpected error in applyCoupon: $e");
      rethrow;
    }
  }
}
