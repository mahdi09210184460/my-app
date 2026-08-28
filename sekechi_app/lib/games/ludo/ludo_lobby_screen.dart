import 'package:flutter/material.dart';

class LudoLobbyScreen extends StatelessWidget {
  const LudoLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لابی بازی منچ')),
      body: const Center(
        child: Text('بخش بازی آنلاین به‌زودی فعال خواهد شد.'),
      ),
    );
  }
}
