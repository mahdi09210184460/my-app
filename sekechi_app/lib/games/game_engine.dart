import 'bot_player_model.dart';
import '../services/game_service.dart';
import 'game_result_model.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

class GameEngine {
  final List<String> _players = [];
  bool _isGameRunning = false;
  String? _currentUserId;

  bool get isGameRunning => _isGameRunning;
  List<String> get players => _players;

  /// آماده‌سازی بازی و انتخاب بازیکن‌ها
  Future<void> prepareGame() async {
    _currentUserId = SupabaseService.client.auth.currentUser?.id;
    if (_currentUserId == null) throw Exception('کاربر وارد نشده است');

    final userName = (await SupabaseService.client
        .from('profiles')
        .select('username')
        .eq('id', _currentUserId!)
        .single())['username'] as String;

    _players.clear();
    _players.add(userName); // بازیکن اصلی
    
    // اضافه کردن ۳ ربات تصادفی
    final bots = BotPlayerModel.getRandomBots(3);
    _players.addAll(bots.map((b) => b.name));
  }

  /// شروع رسمی بازی
  Future<void> start() async {
    if (_isGameRunning) return;
    
    await GameService.startGame();
    _isGameRunning = true;
  }

  /// پایان بازی و اعمال نتایج
  Future<void> finish(bool isWin) async {
    if (!_isGameRunning || _currentUserId == null) return;

    final reward = isWin ? AppConstants.gameWinReward : -AppConstants.gameLossPenalty;

    // ۱. پرداخت جایزه یا جریمه
    await GameService.addReward(isWin);

    // ۲. ثبت در تاریخچه
    final result = GameResultModel(
      id: '', // توسط دیتابیس تولید می‌شود
      userId: _currentUserId!,
      isWin: isWin,
      reward: reward,
      playerNames: _players,
      createdAt: DateTime.now(),
    );
    
    await GameService.saveGameHistory(result);

    _isGameRunning = false;
  }
}
