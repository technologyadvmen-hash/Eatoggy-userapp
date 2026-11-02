class OrderReviewRequest {
  final int rating;
  final int foodRating;
  final int deliveryRating;
  final String comment;
  final List<String> images;

  const OrderReviewRequest({
    required this.rating,
    required this.foodRating,
    required this.deliveryRating,
    required this.comment,
    this.images = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'foodRating': foodRating,
      'deliveryRating': deliveryRating,
      'comment': comment,
      'images': images,
    };
  }

  factory OrderReviewRequest.fromJson(Map<String, dynamic> json) {
    return OrderReviewRequest(
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      foodRating: (json['foodRating'] as num?)?.toInt() ?? 5,
      deliveryRating: (json['deliveryRating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String? ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
