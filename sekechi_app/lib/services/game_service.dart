import 'package:supabase_flutter/supabase_flutter.dart';
import 'wallet_service.dart';
import '../core/constants.dart';
import 'supabase_service.dart';
import '../games/game_result_model.dart';

class GameService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Checks if the user has enough coins to start a game.
  static Future<bool> canJoinGame() async {
    try {
      final balance = await WalletService.getBalance();
      return balance >= AppConstants.gameEntryFee;
    } catch (e) {
      return false;
    }
  }

  /// Deducts the entry fee and records the transaction.
  static Future<void> startGame() async {
    try {
      final canJoin = await canJoinGame();
      if (!canJoin) {
        throw Exception('موجودی سکه کافی نیست.');
      }

      await WalletService.addTransaction(
        amount: -AppConstants.gameEntryFee,
        type: AppConstants.typeGameEntry,
        description: 'هزینه ورود به بازی',
      );
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Adds the win reward and records the transaction.
  static Future<void> recordWin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      await WalletService.addTransaction(
        amount: AppConstants.gameWinReward,
        type: AppConstants.typeGameReward,
        description: 'جایزه برد در بازی',
      );
      
      await _client.rpc('increment_game_stats', params: {
        'p_user_id': userId,
        'p_is_win': true,
      });
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Deducts the loss penalty and records the transaction.
  static Future<void> recordLoss() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await WalletService.addTransaction(
        amount: -AppConstants.gameLossPenalty,
        type: AppConstants.typeGamePenalty,
        description: 'جریمه باخت در بازی',
      );

      await _client.rpc('increment_game_stats', params: {
        'p_user_id': userId,
        'p_is_win': false,
      });
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// پرداخت جایزه یا ثبت جریمه باخت (نسخه قدیمی برای سازگاری)
  static Future<void> addReward(bool isWin) async {
    if (isWin) {
      await recordWin();
    } else {
      await recordLoss();
    }
  }

  /// ثبت نتیجه نهایی بازی در دیتابیس
  static Future<void> saveGameHistory(GameResultModel result) async {
    try {
      await _client.from('game_history').insert(result.toJson());
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }
}
