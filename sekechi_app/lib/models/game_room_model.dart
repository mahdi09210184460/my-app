enum GameStatus { waiting, playing, finished }

class GameRoomModel {
  final String id;
  final String gameType;
  final List<String> players;
  final int entryFee;
  final GameStatus status;

  GameRoomModel({
    required this.id,
    required this.gameType,
    required this.players,
    required this.entryFee,
    required this.status,
  });

  factory GameRoomModel.fromJson(Map<String, dynamic> json) {
    return GameRoomModel(
      id: json['id'] as String,
      gameType: json['game_type'] as String,
      players: List<String>.from(json['players'] ?? []),
      entryFee: (json['entry_fee'] as num?)?.toInt() ?? 0,
      status: GameStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'waiting'),
        orElse: () => GameStatus.waiting,
      ),
    );
  }
}
