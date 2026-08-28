import 'package:flutter/material.dart';
import '../services/game_service.dart';
import 'ludo/ludo_game_screen.dart';
import 'snake_ladder/snake_ladder_game_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دنیای بازی‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGameGroupTitle('بازی‌های کلاسیک'),
            const SizedBox(height: 12),
            _GameLargeCard(
              title: 'منچ (Ludo)',
              description: 'بازی نوستالژیک منچ با ربات‌های هوشمند',
              icon: Icons.casino,
              color: Colors.red.shade400,
              onTap: () => _handleGameEntry(context, 'ludo'),
            ),
            const SizedBox(height: 16),
            _GameLargeCard(
              title: 'مار و پله',
              description: 'از نردبان‌ها بالا برو و از مارها دوری کن!',
              icon: Icons.linear_scale,
              color: Colors.green.shade400,
              onTap: () => _handleGameEntry(context, 'snake_ladder'),
            ),
            const SizedBox(height: 24),
            _buildGameGroupTitle('بازی‌های رومیزی'),
            const SizedBox(height: 12),
            _GameLargeCard(
              title: 'بازی رومیزی',
              description: 'مجموعه بازی‌های فکری و استراتژیک (به‌زودی)',
              icon: Icons.grid_view,
              color: Colors.blueGrey,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGameEntry(BuildContext context, String gameType) async {
    // نمایش لودینگ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final canJoin = await GameService.canJoinGame();
      if (!context.mounted) return;
      Navigator.pop(context); // بستن لودینگ

      if (canJoin) {
        if (gameType == 'ludo') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LudoGameScreen()));
        } else if (gameType == 'snake_ladder') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SnakeLadderGameScreen()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('این بازی به‌زودی آماده خواهد شد.')),
          );
        }
      } else {
        _showLowBalanceDialog(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
    }
  }

  void _showLowBalanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('موجودی ناکافی'),
          content: const Text('برای شروع بازی حداقل به ۱۰۰ سکه نیاز دارید. می‌توانید از فروشگاه سکه تهیه کنید یا جایزه روزانه بگیرید.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('فهمیدم')),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('فروشگاه')),
          ],
        ),
      ),
    );
  }

  Widget _buildGameGroupTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }
}

class _GameLargeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameLargeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -20,
                bottom: -20,
                child: Icon(icon, size: 120, color: Colors.white.withValues(alpha: 0.2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const Positioned(
                right: 16,
                bottom: 16,
                child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
