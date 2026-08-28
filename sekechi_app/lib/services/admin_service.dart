import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/news_model.dart';
import '../models/shop_item_model.dart';
import '../models/coin_transaction_model.dart';

class AdminService {
  static SupabaseClient get _client => SupabaseService.client;

  /// بررسی نقش ادمین کاربر فعلی از دیتابیس
  static Future<bool> isAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    
    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      
      return response?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// دریافت آمار داشبورد مدیریت
  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _client.rpc('get_admin_stats');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('خطا در دریافت آمار: $e');
    }
  }

  /// دریافت لیست کامل کاربران
  static Future<List<UserModel>> getUsers() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('خطا در دریافت کاربران: $e');
    }
  }

  /// جستجوی کاربران بر اساس نام کاربری یا ایمیل
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,email.ilike.%$query%')
          .limit(20);
      
      return (response as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('خطا در جستجوی کاربران: $e');
    }
  }

  /// دریافت تاریخچه تراکنش‌های یک کاربر
  static Future<List<CoinTransactionModel>> getUserTransactions(String userId) async {
    try {
      final response = await _client
          .from('coin_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List).map((e) => CoinTransactionModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('خطا در دریافت تراکنش‌ها: $e');
    }
  }

  /// تغییر سکه کاربر فقط از طریق RPC امن
  static Future<void> adjustUserCoins({
    required String userId,
    required int amount,
    required String reason,
  }) async {
    try {
      await _client.rpc('admin_adjust_coins', params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_reason': reason,
      });
    } catch (e) {
      throw Exception('خطا در تغییر سکه: $e');
    }
  }

  /// دریافت لیست سفارشات
  static Future<List<OrderModel>> getOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('خطا در دریافت سفارشات: $e');
    }
  }

  /// تغییر وضعیت سفارش فقط از طریق RPC امن
  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    required String reason,
  }) async {
    try {
      await _client.rpc('admin_update_order_status', params: {
        'p_order_id': orderId,
        'p_new_status': status,
        'p_reason': reason,
      });
    } catch (e) {
      throw Exception('خطا در تغییر وضعیت سفارش: $e');
    }
  }

  /// دریافت محصولات فروشگاه
  static Future<List<ShopItemModel>> getShopItems() async {
    try {
      final response = await _client
          .from('shop_items')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((e) => ShopItemModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('خطا در دریافت محصولات: $e');
    }
  }

  /// ایجاد محصول جدید در فروشگاه
  static Future<void> createShopItem(Map<String, dynamic> data) async {
    try {
      await _client.from('shop_items').insert(data);
    } catch (e) {
      throw Exception('خطا در ایجاد محصول: $e');
    }
  }

  /// ویرایش محصول فروشگاه
  static Future<void> updateShopItem(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('shop_items').update(data).eq('id', id);
    } catch (e) {
      throw Exception('خطا در ویرایش محصول: $e');
    }
  }

  /// حذف محصول فروشگاه
  static Future<void> deleteShopItem(String id) async {
    try {
      await _client.from('shop_items').delete().eq('id', id);
    } catch (e) {
      throw Exception('خطا در حذف محصول: $e');
    }
  }

  /// دریافت لیست اخبار
  static Future<List<NewsModel>> getNews() async {
    try {
      final response = await _client
          .from('news')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((e) => NewsModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('خطا در دریافت اخبار: $e');
    }
  }

  /// ایجاد خبر جدید
  static Future<void> createNews(Map<String, dynamic> data) async {
    try {
      await _client.from('news').insert(data);
    } catch (e) {
      throw Exception('خطا در ایجاد خبر: $e');
    }
  }

  /// ویرایش خبر
  static Future<void> updateNews(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('news').update(data).eq('id', id);
    } catch (e) {
      throw Exception('خطا در ویرایش خبر: $e');
    }
  }

  /// حذف خبر
  static Future<void> deleteNews(String id) async {
    try {
      await _client.from('news').delete().eq('id', id);
    } catch (e) {
      throw Exception('خطا در حذف خبر: $e');
    }
  }

  // --- Lottery Management ---

  static Future<void> addLottery(Map<String, dynamic> data) async {
    try {
      await _client.from('lotteries').insert(data);
    } catch (e) {
      throw Exception('خطا در ایجاد قرعه‌کشی: $e');
    }
  }

  static Future<void> setLotteryWinner(String lotteryId, String userId, String userName) async {
    try {
      await _client.from('lotteries').update({
        'winner_id': userId,
        'winner_name': userName,
        'status': 'finished',
        'draw_date': DateTime.now().toIso8601String(),
      }).eq('id', lotteryId);
    } catch (e) {
      throw Exception('خطا در ثبت برنده: $e');
    }
  }
}
