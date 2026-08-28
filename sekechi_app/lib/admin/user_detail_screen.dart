import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';
import '../models/coin_transaction_model.dart';
import 'package:intl/intl.dart' as intl;

class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  UserModel? _user;
  List<CoinTransactionModel> _transactions = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await AdminService.getUsers();
      final user = users.firstWhere((u) => u.id == widget.userId);
      final transactions = await AdminService.getUserTransactions(widget.userId);
      
      setState(() {
        _user = user;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در بارگذاری: $e')));
      }
    }
  }

  Future<void> _adjustCoins(bool isAdding) async {
    if (_amountController.text.isEmpty || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً مبلغ و دلیل را وارد کنید.')));
      return;
    }

    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isProcessing = true);
    try {
      final finalAmount = isAdding ? amount : -amount;
      await AdminService.adjustUserCoins(
        userId: widget.userId,
        amount: finalAmount,
        reason: _reasonController.text,
      );
      
      _amountController.clear();
      _reasonController.clear();
      if (mounted) {
        Navigator.pop(context); // Close dialog
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تغییرات با موفقیت ثبت شد.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showAdjustDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تغییر موجودی سکه'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'تعداد سکه', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'دلیل تغییر (اجباری)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _adjustCoins(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('افزایش'),
            ),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _adjustCoins(false),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('کاهش'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('جزئیات کاربر')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _user == null
                ? const Center(child: Text('کاربر یافت نشد'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserInfoCard(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('تاریخچه تراکنش‌ها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              onPressed: _showAdjustDialog,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('تغییر سکه'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTransactionList(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(radius: 40, child: Text(_user!.username[0], style: const TextStyle(fontSize: 32))),
            const SizedBox(height: 16),
            Text(_user!.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(_user!.email, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('موجودی سکه', '${_user!.coins}', Colors.amber),
                _buildInfoItem('بازی‌ها', '${_user!.gamesPlayed}', Colors.blue),
                _buildInfoItem('نقش کاربری', _user!.role, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('تراکنشی یافت نشد.')));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isNegative = tx.amount < 0;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(
              isNegative ? Icons.remove_circle_outline : Icons.add_circle_outline,
              color: isNegative ? Colors.red : Colors.green,
            ),
            title: Text(tx.description),
            subtitle: Text(intl.DateFormat('yyyy/MM/dd HH:mm').format(tx.createdAt)),
            trailing: Text(
              '${isNegative ? "" : "+"}${tx.amount}',
              style: TextStyle(fontWeight: FontWeight.bold, color: isNegative ? Colors.red : Colors.green),
            ),
          ),
        );
      },
    );
  }
}
