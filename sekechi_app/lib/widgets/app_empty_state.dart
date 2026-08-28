import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AppEmptyState({
    super.key,
    this.title = 'موردی یافت نشد',
    this.message = 'در حال حاضر اطلاعاتی برای نمایش وجود ندارد.',
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
