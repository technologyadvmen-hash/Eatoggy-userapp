class CustomerAddressData {
  final String id;
  final String customerId;
  final String name;
  final String mobile;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final String label;
  final bool isDefault;
  final String? createdAt;
  final String? updatedAt;
  final int? v;

  const CustomerAddressData({
    required this.id,
    required this.customerId,
    required this.name,
    required this.mobile,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    required this.label,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory CustomerAddressData.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val, [bool def = false]) {
      if (val == null) return def;
      if (val is bool) return val;
      if (val is num) return val == 1;
      final s = val.toString().toLowerCase().trim();
      return s == 'true' || s == '1';
    }

    String parseString(dynamic val, [String def = '']) {
      if (val == null) return def;
      return val.toString();
    }

    return CustomerAddressData(
      id: parseString(json['id'] ?? json['_id']),
      customerId: parseString(json['customerId']),
      name: parseString(json['name']),
      mobile: parseString(json['mobile']),
      addressLine1: parseString(json['addressLine1']),
      addressLine2: parseString(json['addressLine2']),
      city: parseString(json['city']),
      state: parseString(json['state']),
      pincode: parseString(json['pincode']),
      landmark: json['landmark'] != null ? parseString(json['landmark']) : null,
      label: parseString(json['label'], 'Home'),
      isDefault: parseBool(json['isDefault']),
      createdAt: json['createdAt'] != null ? parseString(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? parseString(json['updatedAt']) : null,
      v: json['__v'] is int ? json['__v'] as int : int.tryParse(json['__v']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'name': name,
      'mobile': mobile,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'label': label,
      'isDefault': isDefault,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
    };
  }
}

class AddAddressResponse {
  final bool success;
  final String message;
  final CustomerAddressData? data;

  const AddAddressResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AddAddressResponse.fromJson(Map<String, dynamic> json) {
    return AddAddressResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] is Map<String, dynamic>
          ? CustomerAddressData.fromJson(json['data'] as Map<String, dynamic>)
          : (json['data'] is Map
              ? CustomerAddressData.fromJson(
                  Map<String, dynamic>.from(json['data'] as Map),
                )
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}
