import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/delete_account_request.dart';
import '../models/get_profile_request.dart';
import '../models/update_profile_request.dart';

abstract class ProfileRepository {
  Future<Response> getProfile({GetProfileRequest? request});
  Future<Response> updateProfile(UpdateProfileRequest request);
  Future<Response> deleteAccount(DeleteAccountRequest request);
}

class ProfileRepositoryImpl implements ProfileRepository {
  @override
  Future<Response> getProfile({GetProfileRequest? request}) {
    return ApiService.dio.get(ApiConstants.customerProfile);
  }

  @override
  Future<Response> updateProfile(UpdateProfileRequest request) {
    return ApiService.dio.patch(
      ApiConstants.customerProfile,
      data: request.toJson(),
    );
  }

  @override
  Future<Response> deleteAccount(DeleteAccountRequest request) {
    return ApiService.dio.delete(
      ApiConstants.deleteAccount,
      data: request.toJson(),
    );
  }
}

