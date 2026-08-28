enum PieceStatus { home, board, goal }

class LudoPiece {
  final int id;
  final int playerIndex;
  int position; // 0-51 on board, or special indices for home/goal
  PieceStatus status;

  LudoPiece({
    required this.id,
    required this.playerIndex,
    this.position = -1,
    this.status = PieceStatus.home,
  });
}
