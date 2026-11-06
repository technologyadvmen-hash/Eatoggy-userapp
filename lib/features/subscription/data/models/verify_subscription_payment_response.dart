import 'customer_subscription_model.dart';

class VerifySubscriptionPaymentResponse {
  final bool success;
  final String message;
  final CustomerSubscriptionModel? subscription;
  final Map<String, dynamic>? rawData;

  const VerifySubscriptionPaymentResponse({
    required this.success,
    required this.message,
    this.subscription,
    this.rawData,
  });

  factory VerifySubscriptionPaymentResponse.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] as bool? ?? true;
    final String message = json['message'] as String? ?? '';

    CustomerSubscriptionModel? sub;
    if (json.containsKey('data') && json['data'] != null) {
      if (json['data'] is Map<String, dynamic>) {
        sub = CustomerSubscriptionModel.fromJson(json['data'] as Map<String, dynamic>);
      }
    } else if (json.containsKey('subscription') && json['subscription'] != null) {
      sub = CustomerSubscriptionModel.fromJson(json['subscription'] as Map<String, dynamic>);
    } else {
      sub = CustomerSubscriptionModel.fromJson(json);
    }

    return VerifySubscriptionPaymentResponse(
      success: success,
      message: message,
      subscription: sub,
      rawData: json,
    );
  }
}
