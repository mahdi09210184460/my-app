class LotteryModel {
  final String id;
  final String title;
  final String description;
  final String prizeTitle;
  final String? prizeImage;
  final String status; // active, finished
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? drawDate;
  final String? winnerId;
  final String? winnerName;
  final DateTime createdAt;

  LotteryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.prizeTitle,
    this.prizeImage,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.drawDate,
    this.winnerId,
    this.winnerName,
    required this.createdAt,
  });

  factory LotteryModel.fromJson(Map<String, dynamic> json) {
    return LotteryModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      prizeTitle: json['prize_title'] ?? '',
      prizeImage: json['prize_image'],
      status: json['status'] ?? 'active',
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toIso8601String()),
      drawDate: json['draw_date'] != null ? DateTime.parse(json['draw_date']) : null,
      winnerId: json['winner_id'],
      winnerName: json['winner_name'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'prize_title': prizeTitle,
      'prize_image': prizeImage,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'draw_date': drawDate?.toIso8601String(),
      'winner_id': winnerId,
      'winner_name': winnerName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
