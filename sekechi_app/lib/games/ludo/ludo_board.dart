import 'package:flutter/material.dart';
import 'ludo_engine.dart';
import 'ludo_piece.dart';

class LudoBoard extends StatelessWidget {
  final LudoEngine engine;
  const LudoBoard({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Simplified board grid for demo
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 15),
              itemCount: 225,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
                );
              },
            ),
            // Home areas
            _buildHomeArea(0, 0, Colors.red),
            _buildHomeArea(0, 9, Colors.green),
            _buildHomeArea(9, 0, Colors.blue),
            _buildHomeArea(9, 9, Colors.yellow),
            
            // Pieces
            ...engine.players.expand((player) => player.pieces.map((piece) => _buildPiece(piece, player.color))),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeArea(int row, int col, Color color) {
    return Positioned(
      top: row * (100 / 15 * 6.6), // rough calc
      left: col * (100 / 15 * 6.6),
      child: Container(
        width: 150, // rough
        height: 150,
        color: color.withValues(alpha: 0.3),
        child: Center(child: Icon(Icons.home, color: color, size: 40)),
      ),
    );
  }

  Widget _buildPiece(LudoPiece piece, Color color) {
    // Simplified piece positioning logic
    double top = 0;
    double left = 0;

    if (piece.status == PieceStatus.home) {
      // Position inside home base
      top = (piece.playerIndex < 2 ? 20 : 250).toDouble();
      left = (piece.playerIndex % 2 == 0 ? 20 : 250).toDouble();
      top += (piece.id * 30);
    } else {
      // Position on board path (simplified)
      top = 150;
      left = 20 + (piece.position * 20).toDouble();
    }

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: () => engine.movePiece(piece),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
          ),
        ),
      ),
    );
  }
}
