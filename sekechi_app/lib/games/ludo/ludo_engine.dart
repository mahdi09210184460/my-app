import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../game_engine.dart';
import 'ludo_player.dart';
import 'ludo_piece.dart';

class LudoEngine extends ChangeNotifier {
  final GameEngine _baseEngine = GameEngine();
  final List<LudoPlayer> players = [];
  int currentPlayerIndex = 0;
  int diceValue = 0;
  bool isDiceRolling = false;
  bool canMove = false;
  String gameState = 'idle'; // idle, playing, finished

  LudoEngine() {
    _initGame();
  }

  void _initGame() async {
    gameState = 'preparing';
    notifyListeners();

    try {
      await _baseEngine.prepareGame();
      final playerNames = _baseEngine.players;
      final colors = [Colors.red, Colors.green, Colors.yellow, Colors.blue];

      for (int i = 0; i < 4; i++) {
        players.add(LudoPlayer(
          name: playerNames[i],
          color: colors[i],
          isBot: i != 0, // First player is human
          pieces: List.generate(4, (index) => LudoPiece(id: index, playerIndex: i)),
        ));
      }

      gameState = 'ready';
      notifyListeners();
    } catch (e) {
      gameState = 'error';
      notifyListeners();
    }
  }

  Future<void> startGame() async {
    try {
      await _baseEngine.start();
      gameState = 'playing';
      currentPlayerIndex = 0;
      notifyListeners();
      
      if (players[currentPlayerIndex].isBot) {
        _handleBotTurn();
      }
    } catch (e) {
      rethrow;
    }
  }

  void rollDice() async {
    if (isDiceRolling || gameState != 'playing' || players[currentPlayerIndex].isBot) return;

    isDiceRolling = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    diceValue = Random().nextInt(6) + 1;
    isDiceRolling = false;
    
    // Logic to check if any piece can move
    canMove = _checkCanMove();
    
    if (!canMove) {
      await Future.delayed(const Duration(seconds: 1));
      _nextTurn();
    }
    
    notifyListeners();
  }

  bool _checkCanMove() {
    final player = players[currentPlayerIndex];
    for (var piece in player.pieces) {
      if (piece.status == PieceStatus.home && diceValue == 6) return true;
      if (piece.status == PieceStatus.board) return true;
    }
    return false;
  }

  Future<void> movePiece(LudoPiece piece) async {
    if (!canMove || piece.playerIndex != currentPlayerIndex) return;

    if (piece.status == PieceStatus.home) {
      if (diceValue == 6) {
        piece.status = PieceStatus.board;
        piece.position = 0; // Starting position relative to player
      } else {
        return;
      }
    } else if (piece.status == PieceStatus.board) {
      piece.position += diceValue;
      if (piece.position >= 52) { // Logic for goal
        piece.status = PieceStatus.goal;
        players[currentPlayerIndex].goalCount++;
      }
    }

    canMove = false;
    
    if (_checkWin()) {
      _finishGame(true);
    } else {
      if (diceValue != 6) {
        _nextTurn();
      } else {
        notifyListeners(); // Roll again
      }
    }
  }

  void _nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % 4;
    canMove = false;
    diceValue = 0;
    notifyListeners();

    if (players[currentPlayerIndex].isBot) {
      _handleBotTurn();
    }
  }

  void _handleBotTurn() async {
    await Future.delayed(const Duration(seconds: 1));
    diceValue = Random().nextInt(6) + 1;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    
    // Bot simple AI: pick first movable piece
    LudoPiece? pieceToMove;
    final player = players[currentPlayerIndex];
    
    for (var p in player.pieces) {
      if (p.status == PieceStatus.home && diceValue == 6) {
        pieceToMove = p;
        break;
      }
      if (p.status == PieceStatus.board) {
        pieceToMove = p;
        break;
      }
    }

    if (pieceToMove != null) {
      canMove = true;
      await movePiece(pieceToMove);
    } else {
      _nextTurn();
    }
  }

  bool _checkWin() {
    return players[currentPlayerIndex].goalCount == 4;
  }

  void _finishGame(bool isHumanWin) async {
    gameState = 'finished';
    notifyListeners();
    await _baseEngine.finish(isHumanWin && currentPlayerIndex == 0);
  }
}
