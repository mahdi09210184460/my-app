import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/payment_package_model.dart';
import '../models/payment_model.dart';

class PaymentService {
  static SupabaseClient get _client => SupabaseService.client;

  /// دریافت لیست بسته‌های خرید سکه فعال
  static Future<List<PaymentPackageModel>> getActivePackages() async {
    try {
      final response = await _client
          .from('payment_packages')
          .select()
          .eq('is_active', true)
          .order('coins_amount');
      
      return (response as List).map((e) => PaymentPackageModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('خطا در دریافت بسته‌ها: $e');
    }
  }

  /// مرحله اول: ایجاد رکورد پرداخت در دیتابیس (قبل از هدایت به درگاه)
  static Future<PaymentModel> initiatePayment(PaymentPackageModel package) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('کاربر وارد نشده است');

    try {
      final response = await _client.from('payments').insert({
        'user_id': userId,
        'package_id': package.id,
        'package_title_snapshot': package.title,
        'coins_amount_snapshot': package.coinsAmount,
        'price_at_purchase': package.priceIrr,
        'status': 'pending',
      }).select().single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      throw Exception('خطا در ایجاد درخواست پرداخت: $e');
    }
  }

  /// مرحله نهایی: تایید پرداخت و شارژ کیف پول (فقط از طریق RPC امن)
  /// این متد بعد از بازگشت از درگاه (Callback) فراخوانی می‌شود.
  static Future<bool> verifyPayment({
    required String paymentId,
    required String authority,
    required String status, // 'OK' or 'NOK'
  }) async {
    try {
      // فراخوانی RPC اختصاصی برای تایید و شارژ همزمان
      // این RPC در دیتابیس چک می‌کند که پرداخت قبلاً تایید نشده باشد
      final result = await _client.rpc('verify_payment_and_charge_wallet', params: {
        'p_payment_id': paymentId,
        'p_authority': authority,
        'p_bank_status': status,
      });

      return result as bool;
    } catch (e) {
      throw Exception('خطا در تایید پرداخت: $e');
    }
  }

  /// دریافت تاریخچه پرداخت‌های کاربر
  static Future<List<PaymentModel>> getMyPayments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => PaymentModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('خطا در دریافت تاریخچه پرداخت: $e');
    }
  }
}
