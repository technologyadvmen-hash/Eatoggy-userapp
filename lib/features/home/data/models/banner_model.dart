class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String tag;
  final String? actionUrl;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.tag = 'FESTIVE OFFER',
    this.actionUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? 'Royal Feast Thali',
      subtitle: json['subtitle'] as String? ??
          json['description'] as String? ??
          'Subscribe today & get 20% off your first luxury weekly pack',
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String? ?? 'assets/b1.png',
      tag: json['tag'] as String? ?? json['badge'] as String? ?? 'FESTIVE OFFER',
      actionUrl: json['actionUrl'] as String? ?? json['link'] as String?,
    );
  }

  factory BannerModel.defaultHero() {
    return const BannerModel(
      id: 'hero_1',
      title: 'Royal Feast Thali',
      subtitle: 'Subscribe today & get 20% off your first luxury weekly pack',
      imageUrl: 'assets/b1.png',
      tag: 'FESTIVE OFFER',
    );
  }
}
