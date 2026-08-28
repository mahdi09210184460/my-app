class NewsModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
