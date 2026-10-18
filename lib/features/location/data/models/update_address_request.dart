class UpdateAddressRequest {
  final String? name;
  final String? mobile;
  final String? addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String? city;
  final String? pincode;
  final String? state;
  final String? label;
  final bool? isDefault;

  const UpdateAddressRequest({
    this.name,
    this.mobile,
    this.addressLine1,
    this.addressLine2,
    this.landmark,
    this.city,
    this.pincode,
    this.state,
    this.label,
    this.isDefault,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (mobile != null) data['mobile'] = mobile;
    if (addressLine1 != null) data['addressLine1'] = addressLine1;
    if (addressLine2 != null) data['addressLine2'] = addressLine2;
    if (landmark != null) data['landmark'] = landmark;
    if (city != null) data['city'] = city;
    if (pincode != null) data['pincode'] = pincode;
    if (state != null) data['state'] = state;
    if (label != null) data['label'] = label;
    if (isDefault != null) data['isDefault'] = isDefault;
    return data;
  }
}
