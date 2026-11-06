class InitiateSubscriptionRequest {
  final String planId;
  final String addressId;
  final String startDate; // ISO date string: YYYY-MM-DD

  const InitiateSubscriptionRequest({
    required this.planId,
    required this.addressId,
    required this.startDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'addressId': addressId,
      'startDate': startDate,
    };
  }

  factory InitiateSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return InitiateSubscriptionRequest(
      planId: json['planId'] as String? ?? '',
      addressId: json['addressId'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
    );
  }
}
