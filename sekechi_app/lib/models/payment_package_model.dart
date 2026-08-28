class PaymentPackageModel {
  final String id;
  final String title;
  final int coinsAmount;
  final int priceIrr;
  final bool isActive;

  PaymentPackageModel({
    required this.id,
    required this.title,
    required this.coinsAmount,
    required this.priceIrr,
    required this.isActive,
  });

  factory PaymentPackageModel.fromJson(Map<String, dynamic> json) {
    return PaymentPackageModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      coinsAmount: (json['coins_amount'] as num?)?.toInt() ?? 0,
      priceIrr: (json['price_irr'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coins_amount': coinsAmount,
      'price_irr': priceIrr,
      'is_active': isActive,
    };
  }
}
