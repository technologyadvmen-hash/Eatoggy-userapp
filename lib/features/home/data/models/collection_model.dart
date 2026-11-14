class CollectionModel {
  final String id;
  final String name;
  final String? imageUrl;
  final int itemCount;

  const CollectionModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.itemCount = 0,
  });

  String get displayImageUrl {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final url = imageUrl!.trim();
      if (url.startsWith('assets/')) return url;
      if (url.startsWith('http') &&
          !url.contains('photo-1601050690597-df056fb4ce78') &&
          !url.contains('photo-1626074353765-517a681e40be') &&
          !url.contains('pub-advmenngo.r2.dev')) {
        return url;
      }
    }
    final n = name.toLowerCase().trim();
    if (n.contains('pizza')) {
      return 'assets/home_svg/cat_pizza.jpg';
    }
    if (n.contains('burger')) {
      return 'assets/home_svg/cat_burger.jpg';
    }
    if (n.contains('biryani') || n.contains('rice')) {
      return 'assets/home_svg/cat_biryani.jpg';
    }
    if (n.contains('chinese') || n.contains('noodle')) {
      return 'assets/home_svg/cat_chinese.jpg';
    }
    if (n.contains('south indian') || n.contains('dosa')) {
      return 'assets/home_svg/cat_south_indian.jpg';
    }
    if (n.contains('tea') || n.contains('chai')) {
      return 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?q=80&w=400&auto=format&fit=crop';
    }
    if (n.contains('cake') || n.contains('dessert') || n.contains('sweet')) {
      return 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=400&auto=format&fit=crop';
    }
    if (n.contains('samosa') || n.contains('snack')) {
      return 'assets/samosa.png';
    }
    if (n.contains('paratha')) {
      return 'assets/paratha.png';
    }
    if (n.contains('thali') || n.contains('meal')) {
      return 'assets/f1.png';
    }
    if (n.contains('tikka') || n.contains('starter')) {
      return 'assets/paneer_tikka.png';
    }
    if (n.contains('north indian') || n.contains('curry')) {
      return 'assets/paneer_special.png';
    }
    return 'assets/f1.png';
  }

  factory CollectionModel.fromJson(dynamic json) {
    if (json is String) {
      return CollectionModel(id: json, name: json);
    }
    if (json is Map<String, dynamic>) {
      return CollectionModel(
        id: json['id'] as String? ?? json['_id'] as String? ?? json['name'] as String? ?? '',
        name: json['name'] as String? ?? json['title'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      );
    }
    return const CollectionModel(id: 'all', name: 'All Meals');
  }

  static List<CollectionModel> defaultCollections() {
    return const [
      CollectionModel(
        id: 'pizza',
        name: 'Pizza',
        imageUrl: 'assets/home_svg/cat_pizza.jpg',
      ),
      CollectionModel(
        id: 'burgers',
        name: 'Burgers',
        imageUrl: 'assets/home_svg/cat_burger.jpg',
      ),
      CollectionModel(
        id: 'biryani',
        name: 'Biryani',
        imageUrl: 'assets/home_svg/cat_biryani.jpg',
      ),
      CollectionModel(
        id: 'chinese',
        name: 'Chinese',
        imageUrl: 'assets/home_svg/cat_chinese.jpg',
      ),
      CollectionModel(
        id: 'south_indian',
        name: 'South Indian',
        imageUrl: 'assets/home_svg/cat_south_indian.jpg',
      ),
      CollectionModel(
        id: 'all',
        name: 'All Meals',
        imageUrl: 'assets/f1.png',
      ),
    ];
  }
}
