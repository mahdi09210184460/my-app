class ShopItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int price; // Price in real currency (IRR)
  final int coinPrice; // Price in app coins
  final String? image;
  final bool active;
  final DateTime createdAt;

  ShopItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.coinPrice,
    this.image,
    required this.active,
    required this.createdAt,
  });

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      price: (json['price'] as num?)?.toInt() ?? 0,
      coinPrice: (json['coin_price'] as num?)?.toInt() ?? 0,
      image: json['image_url'],
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'coin_price': coinPrice,
      'image_url': image,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
