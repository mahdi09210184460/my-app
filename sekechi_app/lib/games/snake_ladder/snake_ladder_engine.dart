import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../game_engine.dart';
import 'snake_ladder_player.dart';

class SnakeLadderEngine extends ChangeNotifier {
  final GameEngine _baseEngine = GameEngine();
  final List<SnakeLadderPlayer> players = [];
  int currentPlayerIndex = 0;
  int diceValue = 0;
  bool isRolling = false;
  bool isMoving = false;
  bool isGameOver = false;
  int? winnerIndex;

  // Snakes: Head -> Tail
  final Map<int, int> snakes = {
    17: 7,
    54: 34,
    62: 19,
    64: 60,
    87: 24,
    93: 73,
    95: 75,
    98: 79,
  };

  // Ladders: Bottom -> Top
  final Map<int, int> ladders = {
    1: 38,
    4: 14,
    9: 31,
    21: 42,
    28: 84,
    36: 44,
    51: 67,
    71: 91,
    80: 100,
  };

  SnakeLadderEngine() {
    _initGame();
  }

  void _initGame() async {
    try {
      await _baseEngine.prepareGame();
      final playerNames = _baseEngine.players;
      final colors = [
        Colors.blue.shade700,
        Colors.red.shade700,
        Colors.green.shade700,
        Colors.amber.shade700,
      ];

      players.clear();
      for (int i = 0; i < 4; i++) {
        players.add(SnakeLadderPlayer(
          name: playerNames[i],
          color: colors[i],
          type: i == 0 ? PlayerType.human : PlayerType.bot,
        ));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing Snake & Ladder: $e');
    }
  }

  Future<void> start() async {
    await _baseEngine.start();
    isGameOver = false;
    winnerIndex = null;
    currentPlayerIndex = 0;
    notifyListeners();
  }

  Future<void> rollDice() async {
    if (isRolling || isMoving || isGameOver || players[currentPlayerIndex].type == PlayerType.bot) return;

    isRolling = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    diceValue = Random().nextInt(6) + 1;
    isRolling = false;
    
    await _moveCurrentPlayer(diceValue);
  }

  Future<void> _moveCurrentPlayer(int steps) async {
    isMoving = true;
    notifyListeners();

    final player = players[currentPlayerIndex];
    int targetPos = player.position + steps;

    // Rule: If target > 100, don't move
    if (targetPos <= 100) {
      // Step by step move animation logic (simulated by UI, but we update state)
      while (player.position < targetPos) {
        player.position++;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Check for Snake or Ladder
      if (snakes.containsKey(player.position)) {
        player.position = snakes[player.position]!;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 400));
      } else if (ladders.containsKey(player.position)) {
        player.position = ladders[player.position]!;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    isMoving = false;

    if (player.position == 100) {
      _finishGame();
    } else {
      _nextTurn();
    }
  }

  void _nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    diceValue = 0;
    notifyListeners();

    if (players[currentPlayerIndex].type == PlayerType.bot && !isGameOver) {
      _handleBotTurn();
    }
  }

  Future<void> _handleBotTurn() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    isRolling = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    diceValue = Random().nextInt(6) + 1;
    isRolling = false;

    await _moveCurrentPlayer(diceValue);
  }

  void _finishGame() async {
    isGameOver = true;
    winnerIndex = currentPlayerIndex;
    notifyListeners();

    final isHumanWin = currentPlayerIndex == 0;
    await _baseEngine.finish(isHumanWin);
  }
}
