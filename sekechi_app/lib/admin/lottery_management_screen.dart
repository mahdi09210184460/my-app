import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/lottery_service.dart';
import '../models/lottery_model.dart';
import '../models/user_model.dart';

class LotteryManagementScreen extends StatefulWidget {
  const LotteryManagementScreen({super.key});

  @override
  State<LotteryManagementScreen> createState() => _LotteryManagementScreenState();
}

class _LotteryManagementScreenState extends State<LotteryManagementScreen> {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  Future<void> _showAddDialog() async {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final prizeC = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ایجاد قرعه‌کشی جدید'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleC, decoration: const InputDecoration(labelText: 'عنوان')),
              TextField(controller: descC, decoration: const InputDecoration(labelText: 'توضیحات')),
              TextField(controller: prizeC, decoration: const InputDecoration(labelText: 'نام جایزه')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ایجاد')),
        ],
      ),
    );

    if (result == true) {
      try {
        await AdminService.addLottery({
          'title': titleC.text,
          'description': descC.text,
          'prize_title': prizeC.text,
          'status': 'active',
          'start_date': DateTime.now().toIso8601String(),
          'end_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        });
        _loadLotteries();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  Future<void> _drawWinner(String lotteryId) async {
    final users = await AdminService.getUsers();
    if (!mounted) return;
    if (users.isEmpty) return;

    final winner = await showDialog<UserModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتخاب برنده'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(users[i].username),
              onTap: () => Navigator.pop(context, users[i]),
            ),
          ),
        ),
      ),
    );

    if (winner != null) {
      try {
        await AdminService.setLotteryWinner(lotteryId, winner.id, winner.username);
        if (!mounted) return;
        _loadLotteries();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت قرعه‌کشی‌ها'),
          actions: [IconButton(onPressed: _showAddDialog, icon: const Icon(Icons.add))],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _lotteries.length,
                itemBuilder: (context, index) {
                  final lottery = _lotteries[index];
                  final isActive = lottery.status == 'active';
                  return ListTile(
                    title: Text(lottery.title),
                    subtitle: Text('جایزه: ${lottery.prizeTitle} | ${isActive ? "فعال" : "تمام شده"}'),
                    trailing: isActive
                        ? FilledButton(onPressed: () => _drawWinner(lottery.id), child: const Text('قرعه‌کشی'))
                        : const Icon(Icons.check_circle, color: Colors.green),
                  );
                },
              ),
      ),
    );
  }
}
