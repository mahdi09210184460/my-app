class CoinTransactionModel {
  final String id;
  final String userId;
  final int amount;
  final int balanceAfter;
  final String type;
  final String description;
  final DateTime createdAt;

  CoinTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.balanceAfter,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory CoinTransactionModel.fromJson(Map<String, dynamic> json) {
    return CoinTransactionModel(
      id: json['id'].toString(),
      userId: json['user_id'] as String,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balance_after'] as num?)?.toInt() ?? 0,
      type: json['type'] as String,
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
