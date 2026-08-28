class PaymentModel {
  final String id;
  final String userId;
  final String? packageId;
  final String packageTitleSnapshot;
  final int coinsAmountSnapshot;
  final int priceAtPurchase;
  final String status; // pending, success, failed
  final String? transactionId;
  final String? authorityCode;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.userId,
    this.packageId,
    required this.packageTitleSnapshot,
    required this.coinsAmountSnapshot,
    required this.priceAtPurchase,
    required this.status,
    this.transactionId,
    this.authorityCode,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'].toString(),
      userId: json['user_id'] as String,
      packageId: json['package_id']?.toString(),
      packageTitleSnapshot: json['package_title_snapshot'] ?? '',
      coinsAmountSnapshot: (json['coins_amount_snapshot'] as num?)?.toInt() ?? 0,
      priceAtPurchase: (json['price_at_purchase'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'pending',
      transactionId: json['transaction_id'],
      authorityCode: json['authority_code'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'package_id': packageId,
      'package_title_snapshot': packageTitleSnapshot,
      'coins_amount_snapshot': coinsAmountSnapshot,
      'price_at_purchase': priceAtPurchase,
      'status': status,
      'transaction_id': transactionId,
      'authority_code': authorityCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
