import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class LudoOnlineScreen extends StatefulWidget {
  final String roomId;
  const LudoOnlineScreen({super.key, required this.roomId});

  @override
  State<LudoOnlineScreen> createState() => _LudoOnlineScreenState();
}

class _LudoOnlineScreenState extends State<LudoOnlineScreen> {
  StreamSubscription<List<Map<String, dynamic>>>? _roomSubscription;
  bool _loading = true;
  String _myUserId = '';
  int _currentPlayer = 0;
  String _roomStatus = 'waiting';
  int? _winnerIndex;
  List<Map<String, dynamic>> _players = [];
  final List<List<int>> _positions = [[-1, -1, -1, -1], [-1, -1, -1, -1], [-1, -1, -1, -1], [-1, -1, -1, -1]];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeGame() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('ابتدا وارد حساب خود شوید.');
      return;
    }
    _myUserId = user.id;
    await _loadGame();
    if (!mounted) return;
    _listenToGame();
  }

  Future<void> _loadGame() async {
    try {
      final supabase = SupabaseService.client;
      final room = await supabase.from('ludo_rooms').select('id, status, current_player, dice, game_state, winner').eq('id', widget.roomId).maybeSingle();
      if (room == null) throw Exception('اتاق بازی پیدا نشد.');
      final players = await supabase.from('ludo_players').select('id, user_id, player_index, player_name, color, is_connected').eq('room_id', widget.roomId).order('player_index');
      if (!mounted) return;
      _readGameState(room, players);
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('دریافت اطلاعات بازی انجام نشد.');
    }
  }

  void _listenToGame() {
    _roomSubscription = SupabaseService.client.from('ludo_rooms').stream(primaryKey: ['id']).eq('id', widget.roomId).listen((rows) {
      if (!mounted || rows.isEmpty) return;
      final room = rows.first;
      _readGameState(room, _players);
      setState(() {});
    }, onError: (_) {});
  }

  void _readGameState(Map<String, dynamic> room, List<Map<String, dynamic>> players) {
    _roomStatus = room['status']?.toString() ?? 'waiting';
    _currentPlayer = (room['current_player'] as num?)?.toInt() ?? 0;
    _winnerIndex = (room['winner'] as num?)?.toInt();
    _players = List<Map<String, dynamic>>.from(players);
    _findMyPlayer();
    final state = room['game_state'];
    if (state is Map && state['positions'] is Map) {
      final pos = state['positions'] as Map;
      for (int p = 0; p < 4; p++) {
        final val = pos[p.toString()];
        if (val is List) {
          for (int piece = 0; piece < 4; piece++) {
            if (piece < val.length) _positions[p][piece] = (val[piece] as num).toInt();
          }
        }
      }
    }
  }

  void _findMyPlayer() {
    for (final p in _players) {
      if (p['user_id']?.toString() == _myUserId) {
        break;
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('منچ آنلاین', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: _loading 
            ? const Center(child: CircularProgressIndicator()) 
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('وضعیت بازی: $_roomStatus'),
                    Text('نوبت بازیکن: $_currentPlayer'),
                    if (_winnerIndex != null) Text('برنده: $_winnerIndex'),
                    const SizedBox(height: 20),
                    const Text('این بخش در حال توسعه است.'),
                  ],
                ),
              ),
      ),
    );
  }
}
