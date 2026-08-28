import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'snake_ladder_engine.dart';
import 'snake_ladder_board.dart';
import 'snake_ladder_player.dart';

class SnakeLadderGameScreen extends StatelessWidget {
  const SnakeLadderGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SnakeLadderEngine(),
      child: const _SnakeLadderView(),
    );
  }
}

class _SnakeLadderView extends StatelessWidget {
  const _SnakeLadderView();

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<SnakeLadderEngine>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مار و پله سکه‌چی'),
          centerTitle: true,
        ),
        body: engine.players.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildPlayersInfo(engine),
                  const Divider(),
                  _buildTurnIndicator(engine),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SnakeLadderBoard(engine: engine),
                      ),
                    ),
                  ),
                  _buildControls(context, engine),
                ],
              ),
      ),
    );
  }

  Widget _buildPlayersInfo(SnakeLadderEngine engine) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: engine.players.map((p) {
          final isActive = engine.players[engine.currentPlayerIndex] == p;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: p.color),
              ),
              const SizedBox(height: 4),
              Text(
                p.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                'خانه ${p.position}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTurnIndicator(SnakeLadderEngine engine) {
    final currentPlayer = engine.players[engine.currentPlayerIndex];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: currentPlayer.color.withValues(alpha: 0.1),
      width: double.infinity,
      child: Text(
        currentPlayer.type == PlayerType.human
            ? 'نوبت شماست! تاس بریزید.'
            : 'نوبت ${currentPlayer.name} است...',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, color: currentPlayer.color),
      ),
    );
  }

  Widget _buildControls(BuildContext context, SnakeLadderEngine engine) {
    if (engine.isGameOver) {
      return _buildGameOverView(context, engine);
    }

    final isHumanTurn = engine.players[engine.currentPlayerIndex].type == PlayerType.human;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: (isHumanTurn && !engine.isRolling && !engine.isMoving)
                ? engine.rollDice
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)
                ],
                border: Border.all(
                  color: isHumanTurn ? engine.players[0].color : Colors.grey.shade300,
                  width: 3,
                ),
              ),
              child: Center(
                child: engine.isRolling
                    ? const CircularProgressIndicator()
                    : Text(
                        engine.diceValue == 0 ? '🎲' : engine.diceValue.toString(),
                        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (engine.isMoving)
            const Text('در حال حرکت...')
          else if (isHumanTurn)
            const Text('برای انداختن تاس روی آن ضربه بزنید')
          else
            const Text('منتظر حرکت حریف باشید'),
        ],
      ),
    );
  }

  Widget _buildGameOverView(BuildContext context, SnakeLadderEngine engine) {
    final winner = engine.players[engine.winnerIndex!];
    final isMe = engine.winnerIndex == 0;

    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMe ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 64,
            color: isMe ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isMe ? 'تبریک! شما برنده شدید 🏆' : '${winner.name} برنده شد!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('بازگشت'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => engine.start(),
                  child: const Text('بازی مجدد'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
