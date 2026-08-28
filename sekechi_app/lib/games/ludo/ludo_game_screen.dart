import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ludo_engine.dart';
import 'ludo_board.dart';

class LudoGameScreen extends StatelessWidget {
  const LudoGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LudoEngine(),
      child: const _LudoGameView(),
    );
  }
}

class _LudoGameView extends StatelessWidget {
  const _LudoGameView();

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<LudoEngine>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('منچ سکه‌چی'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'نوبت: ${engine.players.isEmpty ? "..." : engine.players[engine.currentPlayerIndex].name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: engine.gameState == 'preparing' || engine.gameState == 'ready'
            ? _buildStartScreen(context, engine)
            : Column(
                children: [
                  Expanded(child: LudoBoard(engine: engine)),
                  _buildControls(context, engine),
                ],
              ),
      ),
    );
  }

  Widget _buildStartScreen(BuildContext context, LudoEngine engine) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.casino, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text('آماده بازی منچ هستید؟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('هزینه ورود: ۱۰۰ سکه', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: engine.gameState == 'ready' ? () => engine.startGame() : null,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
            child: const Text('شروع بازی'),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, LudoEngine engine) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPlayerInfo(engine.players[0]),
          Column(
            children: [
              GestureDetector(
                onTap: engine.rollDice,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withValues(alpha: 0.1))],
                  ),
                  child: Center(
                    child: engine.isDiceRolling
                        ? const CircularProgressIndicator()
                        : Text(
                            engine.diceValue == 0 ? '🎲' : engine.diceValue.toString(),
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(engine.canMove ? 'یک مهره را حرکت دهید' : 'تاس بریزید'),
            ],
          ),
          _buildPlayerInfo(engine.players[1]), // Just show one bot for brevity
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(dynamic player) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: player.color, child: Text(player.name[0])),
        const SizedBox(height: 4),
        Text(player.name, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
