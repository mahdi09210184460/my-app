import 'package:flutter/material.dart';
import 'snake_ladder_engine.dart';

class SnakeLadderBoard extends StatelessWidget {
  final SnakeLadderEngine engine;
  const SnakeLadderBoard({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black54, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
          itemCount: 100,
          itemBuilder: (context, index) {
            // Snake board logic: Boustrophedon (S-pattern)
            int row = 9 - (index ~/ 10);
            int col = index % 10;
            if (row % 2 == 0) col = 9 - col;
            int cellNumber = (row * 10) + col + 1;

            final playersHere = engine.players.where((p) => p.position == cellNumber).toList();
            final isLadder = engine.ladders.containsKey(cellNumber);
            final isSnake = engine.snakes.containsKey(cellNumber);

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200, width: 0.5),
                color: (index % 2 == 0) ? Colors.blue.shade50 : Colors.white,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '$cellNumber',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ),
                  if (isLadder)
                    const Center(child: Icon(Icons.keyboard_double_arrow_up, color: Colors.green, size: 18)),
                  if (isSnake)
                    const Center(child: Icon(Icons.keyboard_double_arrow_down, color: Colors.red, size: 18)),
                  if (playersHere.isNotEmpty)
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: playersHere.map((p) => Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.color,
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)],
                          ),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
