import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coin_transaction_model.dart';
import '../models/payment_model.dart';
import 'supabase_service.dart';
import 'payment_service.dart';
import '../core/constants.dart';

class WalletService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Retrieves current user's coin balance
  static Future<int> getBalance() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    // We select without cache to ensure we get the latest balance after payment
    final response = await _client
        .from('profiles')
        .select('points')
        .eq('id', userId)
        .maybeSingle();
    
    return (response?['points'] as num?)?.toInt() ?? 0;
  }

  /// Retrieves transaction history for the current user
  static Future<List<CoinTransactionModel>> getTransactions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('coin_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => CoinTransactionModel.fromJson(e)).toList();
  }

  /// دریافت تاریخچه خریدهای نقدی کاربر
  static Future<List<PaymentModel>> getPaymentHistory() async {
    return await PaymentService.getMyPayments();
  }

  /// Internal method to record a transaction and update balance
  /// This should ideally be an RPC to ensure atomicity and security
  static Future<void> addTransaction({
    required int amount,
    required String type,
    required String description,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // We use RPC for security as per user request to ensure only WalletService (via backend logic) 
      // can safely update coins and transactions together.
      await _client.rpc('handle_coin_transaction', params: {
        'p_user_id': user.id,
        'p_amount': amount,
        'p_type': type,
        'p_description': description,
      });
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Special method for signup bonus to ensure it's only given once
  static Future<void> claimSignupBonus() async {
    try {
      await _client.rpc('claim_signup_bonus', params: {
        'p_bonus_amount': AppConstants.signupBonus,
      });
    } catch (e) {
      // If already claimed, the RPC should handle it or we ignore the error if it's a constraint violation
      rethrow;
    }
  }
}
