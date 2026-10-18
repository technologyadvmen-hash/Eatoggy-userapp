import 'add_address_response.dart';

class GetAddressesResponse {
  final bool success;
  final String message;
  final List<CustomerAddressData> data;

  const GetAddressesResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory GetAddressesResponse.fromJson(Map<String, dynamic> json) {
    List<CustomerAddressData> addressList = [];

    final rawList = json['data'] ?? json['addresses'];
    if (rawList is List) {
      addressList = rawList
          .whereType<Map>()
          .map((item) => CustomerAddressData.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    final isSuccess = json['success'] == true ||
        json['success'] == 'true' ||
        (json['success'] == null && addressList.isNotEmpty);

    return GetAddressesResponse(
      success: isSuccess,
      message: (json['message'] ?? '').toString(),
      data: addressList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.map((item) => item.toJson()).toList(),
    };
  }
}
