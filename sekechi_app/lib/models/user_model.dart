class UserModel {
  final String id;
  final String username;
  final String email;
  final String? avatar;
  final int coins;
  final String role;
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatar,
    required this.coins,
    required this.role,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.gamesLost,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] ?? json['display_name'] ?? 'کاربر',
      email: json['email'] ?? '',
      avatar: json['avatar_url'],
      coins: (json['points'] as num?)?.toInt() ?? 0,
      role: json['role'] ?? 'user',
      gamesPlayed: (json['games_played'] as num?)?.toInt() ?? 0,
      gamesWon: (json['games_won'] as num?)?.toInt() ?? 0,
      gamesLost: (json['games_lost'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatar,
      'points': coins,
      'role': role,
      'games_played': gamesPlayed,
      'games_won': gamesWon,
      'games_lost': gamesLost,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
