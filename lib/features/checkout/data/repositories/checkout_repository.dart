import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';
import '../models/checkout_summary_model.dart';
import '../models/initiate_checkout_model.dart';
import '../models/verify_payment_request.dart';
import '../models/verify_payment_response.dart';

abstract class CheckoutRepository {
  Future<CheckoutSummaryModel> getCheckoutSummary(String addressId);
  Future<InitiateCheckoutResponse> initiateCheckout(InitiateCheckoutRequest request);
  Future<VerifyPaymentResponse> verifyPayment(VerifyPaymentRequest request);
}

class CheckoutRepositoryImpl implements CheckoutRepository {
  @override
  Future<CheckoutSummaryModel> getCheckoutSummary(String addressId) async {
    try {
      final response = await ApiService.dio.get(
        ApiConstants.checkoutSummary(addressId),
      );

      if (response.data is Map<String, dynamic>) {
        return CheckoutSummaryModel.fromJson(response.data as Map<String, dynamic>);
      }
      return CheckoutSummaryModel.fallback(0.0);
    } on DioException catch (e) {
      appLog("⚠️ getCheckoutSummary API Error: ${e.response?.statusCode} - ${e.message}");
      if (e.response?.data is Map<String, dynamic>) {
        return CheckoutSummaryModel.fromJson(e.response!.data as Map<String, dynamic>);
      }
      rethrow;
    } catch (e) {
      appLog("⚠️ Unexpected error in getCheckoutSummary: $e");
      rethrow;
    }
  }

  @override
  Future<InitiateCheckoutResponse> initiateCheckout(InitiateCheckoutRequest request) async {
    try {
      final response = await ApiService.dio.post(
        ApiConstants.checkoutInitiate,
        data: request.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        return InitiateCheckoutResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Invalid initiate checkout response format');
    } on DioException catch (e) {
      appLog("❌ initiateCheckout API Error: ${e.response?.statusCode} - ${e.message}");
      if (e.response?.data is Map<String, dynamic>) {
        return InitiateCheckoutResponse.fromJson(e.response!.data as Map<String, dynamic>);
      }
      rethrow;
    } catch (e) {
      appLog("❌ Unexpected error in initiateCheckout: $e");
      rethrow;
    }
  }

  @override
  Future<VerifyPaymentResponse> verifyPayment(VerifyPaymentRequest request) async {
    try {
      final response = await ApiService.dio.post(
        ApiConstants.verifyPayment,
        data: request.toJson(),
      );

      if (response.data is Map<String, dynamic>) {
        return VerifyPaymentResponse.fromJson(response.data as Map<String, dynamic>);
      }
      return VerifyPaymentResponse(
        success: response.statusCode == 200,
        message: 'Payment verified successfully',
      );
    } on DioException catch (e) {
      appLog("❌ verifyPayment API Error: ${e.response?.statusCode} - ${e.message}");
      if (e.response?.data is Map<String, dynamic>) {
        return VerifyPaymentResponse.fromJson(e.response!.data as Map<String, dynamic>);
      }
      rethrow;
    } catch (e) {
      appLog("❌ Unexpected error in verifyPayment: $e");
      rethrow;
    }
  }
}
