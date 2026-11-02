class CustomerReviewModel {
  final String id;
  final String orderId;
  final int rating;
  final int foodRating;
  final int deliveryRating;
  final String comment;
  final List<String> images;
  final DateTime? createdAt;

  const CustomerReviewModel({
    required this.id,
    required this.orderId,
    required this.rating,
    required this.foodRating,
    required this.deliveryRating,
    required this.comment,
    this.images = const [],
    this.createdAt,
  });

  factory CustomerReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    if (json['createdAt'] != null) {
      try {
        created = DateTime.parse(json['createdAt'].toString());
      } catch (_) {}
    }

    return CustomerReviewModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      orderId: json['orderId'] as String? ?? json['order'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      foodRating: (json['foodRating'] as num?)?.toInt() ?? 5,
      deliveryRating: (json['deliveryRating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String? ?? '',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: created,
    );
  }
}
