import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'wallet_service.dart';
import '../models/shop_item_model.dart';
import '../models/order_model.dart';
import '../core/constants.dart';

class ShopService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Retrieves all active shop items.
  static Future<List<ShopItemModel>> getActiveItems({String? category}) async {
    try {
      var query = _client.from('shop_items').select().eq('active', true);
      
      if (category != null && category != 'همه') {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((e) => ShopItemModel.fromJson(e)).toList();
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Retrieves list of unique categories from active items.
  static Future<List<String>> getCategories() async {
    try {
      final response = await _client
          .from('shop_items')
          .select('category')
          .eq('active', true);
      
      final Set<String> categories = {'همه'};
      for (var item in (response as List)) {
        categories.add(item['category'] as String);
      }
      return categories.toList();
    } catch (e) {
      return ['همه'];
    }
  }

  /// Retrieves order history for the current user.
  static Future<List<OrderModel>> getMyOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Securely handles purchase using coins or creating a service order.
  static Future<void> purchaseItem(ShopItemModel item, {int quantity = 1}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('ابتدا وارد حساب خود شوید.');

    final totalCoinPrice = item.coinPrice * quantity;
    final isCoinPurchase = item.coinPrice > 0;

    try {
      if (isCoinPurchase) {
        // 1. Verify real balance from DB first
        final balance = await WalletService.getBalance();
        if (balance < totalCoinPrice) {
          throw Exception('موجودی سکه شما کافی نیست.');
        }

        // 2. Atomic-like operation: Deduct coins, then record order.
        await WalletService.addTransaction(
          amount: -totalCoinPrice,
          type: AppConstants.typeShopPurchase,
          description: 'خرید: ${item.title} (تعداد: $quantity)',
        );

        try {
          await _client.from('orders').insert({
            'user_id': user.id,
            'item_id': item.id,
            'item_title_snapshot': item.title,
            'amount': quantity,
            'price_at_purchase': item.price,
            'coin_amount': totalCoinPrice,
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Rollback deduction if order failed
          await WalletService.addTransaction(
            amount: totalCoinPrice,
            type: AppConstants.typeShopPurchase,
            description: 'استرداد وجه سیستمی: ${item.title}',
          );
          throw Exception('خطا در ثبت سفارش. مبلغ بازگردانده شد.');
        }
      } else {
        // Service purchase (needs manual delivery)
        await _client.from('orders').insert({
          'user_id': user.id,
          'item_id': item.id,
          'item_title_snapshot': item.title,
          'amount': quantity,
          'price_at_purchase': item.price,
          'coin_amount': 0,
          'status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }
}
