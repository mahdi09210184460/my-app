class GameResultModel {
  final String id;
  final String userId;
  final bool isWin;
  final int reward;
  final List<String> playerNames;
  final DateTime createdAt;

  GameResultModel({
    required this.id,
    required this.userId,
    required this.isWin,
    required this.reward,
    required this.playerNames,
    required this.createdAt,
  });

  factory GameResultModel.fromJson(Map<String, dynamic> json) {
    return GameResultModel(
      id: json['id'].toString(),
      userId: json['user_id'] as String,
      isWin: json['is_win'] as bool,
      reward: (json['reward'] as num).toInt(),
      playerNames: List<String>.from(json['player_names'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'is_win': isWin,
      'reward': reward,
      'player_names': playerNames,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
