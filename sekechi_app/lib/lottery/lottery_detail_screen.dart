import 'package:flutter/material.dart';
import '../models/lottery_model.dart';
import 'package:intl/intl.dart' hide TextDirection;

class LotteryDetailScreen extends StatelessWidget {
  final LotteryModel lottery;
  const LotteryDetailScreen({super.key, required this.lottery});

  @override
  Widget build(BuildContext context) {
    final bool isFinished = lottery.status == 'finished';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('جزئیات قرعه‌کشی')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                      const SizedBox(height: 16),
                      Text(
                        lottery.prizeTitle,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text('جایزه ویژه این دوره', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(lottery.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(lottery.description, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 24),
              const Divider(),
              _infoRow('تاریخ شروع:', DateFormat('yyyy/MM/dd').format(lottery.startDate)),
              _infoRow('تاریخ پایان:', DateFormat('yyyy/MM/dd').format(lottery.endDate)),
              if (isFinished && lottery.drawDate != null)
                _infoRow('تاریخ قرعه‌کشی:', DateFormat('yyyy/MM/dd').format(lottery.drawDate!)),
              
              if (isFinished) ...[
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      const Text('🎉 برنده خوش‌شانس 🎉', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 10),
                      Text(
                        lottery.winnerName ?? 'نامشخص',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      Text('شناسه کاربر: ${lottery.winnerId?.substring(0, 8) ?? '---'}'),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'این قرعه‌کشی در حال برگزاری است.\nمنتظر اعلام نتایج باشید.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
