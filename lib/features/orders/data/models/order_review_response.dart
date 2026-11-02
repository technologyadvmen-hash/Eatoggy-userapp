class OrderReviewResponse {
  final bool success;
  final String message;
  final String? reviewId;
  final Map<String, dynamic>? data;

  const OrderReviewResponse({
    required this.success,
    required this.message,
    this.reviewId,
    this.data,
  });

  factory OrderReviewResponse.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] as bool? ?? true;
    final String message = json['message'] as String? ?? 'Review submitted successfully';

    String? id;
    if (json['data'] is Map<String, dynamic>) {
      id = json['data']['_id'] as String? ?? json['data']['id'] as String?;
    } else if (json['review'] is Map<String, dynamic>) {
      id = json['review']['_id'] as String? ?? json['review']['id'] as String?;
    } else {
      id = json['_id'] as String? ?? json['id'] as String?;
    }

    return OrderReviewResponse(
      success: success,
      message: message,
      reviewId: id,
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json,
    );
  }
}
