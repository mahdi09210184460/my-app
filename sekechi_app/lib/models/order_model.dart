class OrderModel {
  final String id;
  final String userId;
  final String itemId;
  final String itemTitleSnapshot;
  final int quantity;
  final int priceAtPurchase; // Real currency
  final int coinAmount; // Coin currency
  final String status; // pending, processing, completed, cancelled
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemTitleSnapshot,
    required this.quantity,
    required this.priceAtPurchase,
    required this.coinAmount,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'].toString(),
      userId: json['user_id'] as String,
      itemId: json['item_id'].toString(),
      itemTitleSnapshot: json['item_title_snapshot'] ?? '',
      quantity: (json['amount'] as num?)?.toInt() ?? (json['quantity'] as num?)?.toInt() ?? 1,
      priceAtPurchase: (json['price_at_purchase'] as num?)?.toInt() ?? 0,
      coinAmount: (json['coin_amount'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_id': itemId,
      'item_title_snapshot': itemTitleSnapshot,
      'amount': quantity,
      'price_at_purchase': priceAtPurchase,
      'coin_amount': coinAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
