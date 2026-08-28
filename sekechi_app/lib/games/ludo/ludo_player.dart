import 'package:flutter/material.dart';
import 'ludo_piece.dart';

class LudoPlayer {
  final String name;
  final Color color;
  final bool isBot;
  final List<LudoPiece> pieces;
  int goalCount;

  LudoPlayer({
    required this.name,
    required this.color,
    required this.isBot,
    required this.pieces,
    this.goalCount = 0,
  });
}
