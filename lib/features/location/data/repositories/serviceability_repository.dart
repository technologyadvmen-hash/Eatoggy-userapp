import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/serviceability_response.dart';

abstract class ServiceabilityRepository {
  Future<ServiceabilityResponse> checkServiceability({
    required double latitude,
    required double longitude,
  });
}

class ServiceabilityRepositoryImpl implements ServiceabilityRepository {
  @override
  Future<ServiceabilityResponse> checkServiceability({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await ApiService.dio.get(
        ApiConstants.checkServiceability(latitude, longitude),
      );

      final Map<String, dynamic> data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      return ServiceabilityResponse.fromJson(data);
    } on DioException catch (e) {
      debugPrint('⚠️ Check serviceability API error: ${e.response?.data ?? e.message}');
      if (e.response?.data is Map<String, dynamic>) {
        return ServiceabilityResponse.fromJson(e.response!.data as Map<String, dynamic>);
      }
      return ServiceabilityResponse(
        isServiceable: false,
        message: 'Unable to check serviceability for this location.',
      );
    } catch (e) {
      debugPrint('❌ Unexpected error checking serviceability: $e');
      return ServiceabilityResponse(
        isServiceable: false,
        message: 'Error verifying serviceability: $e',
      );
    }
  }
}
