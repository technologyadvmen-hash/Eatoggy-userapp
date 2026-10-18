import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/get_addresses_request.dart';
import '../models/update_address_request.dart';

abstract class GetAddressesRepository {
  Future<Response> getAddresses({GetAddressesRequest? request});
  Future<Response> updateAddress(String id, UpdateAddressRequest request);
  Future<Response> deleteAddress(String id);
}

class GetAddressesRepositoryImpl implements GetAddressesRepository {
  @override
  Future<Response> getAddresses({GetAddressesRequest? request}) {
    return ApiService.dio.get(
      ApiConstants.customerAddresses,
      queryParameters: request?.queryParameters,
    );
  }

  @override
  Future<Response> updateAddress(String id, UpdateAddressRequest request) {
    return ApiService.dio.patch(
      ApiConstants.customerAddress(id),
      data: request.toJson(),
    );
  }

  @override
  Future<Response> deleteAddress(String id) {
    return ApiService.dio.delete(
      '${ApiConstants.customerAddresses}/$id',
    );
  }
}
