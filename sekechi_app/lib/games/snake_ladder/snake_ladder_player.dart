import 'package:flutter/material.dart';

enum PlayerType { human, bot }

class SnakeLadderPlayer {
  final String name;
  final Color color;
  final PlayerType type;
  int position; // 1 to 100

  SnakeLadderPlayer({
    required this.name,
    required this.color,
    required this.type,
    this.position = 1,
  });
}
