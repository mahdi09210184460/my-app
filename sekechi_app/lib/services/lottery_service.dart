import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/lottery_model.dart';

class LotteryService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Fetches all active and recent finished lotteries.
  static Future<List<LotteryModel>> getLotteries() async {
    try {
      final response = await _client
          .from('lotteries')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((e) => LotteryModel.fromJson(e)).toList();
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Fetches details of a single lottery.
  static Future<LotteryModel?> getLotteryDetail(String id) async {
    try {
      final response = await _client
          .from('lotteries')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return LotteryModel.fromJson(response);
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }
}
