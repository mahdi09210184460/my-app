import 'package:flutter/material.dart';
import '../services/lottery_service.dart';
import '../models/lottery_model.dart';
import 'lottery_detail_screen.dart';

class LotteryScreen extends StatefulWidget {
  const LotteryScreen({super.key});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> {
  List<LotteryModel> _lotteries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLotteries();
  }

  Future<void> _loadLotteries() async {
    setState(() => _isLoading = true);
    try {
      final result = await LotteryService.getLotteries();
      setState(() {
        _lotteries = result;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در بارگذاری قرعه‌کشی‌ها: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('قرعه‌کشی و جوایز')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadLotteries,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lotteries.length,
                  itemBuilder: (context, index) {
                    final lottery = _lotteries[index];
                    final isActive = lottery.status == 'active';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive ? Colors.green : Colors.grey,
                          child: Icon(isActive ? Icons.stars : Icons.check, color: Colors.white),
                        ),
                        title: Text(lottery.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('جایزه: ${lottery.prizeTitle}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(isActive ? 'فعال' : 'پایان یافته', style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LotteryDetailScreen(lottery: lottery)),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
