import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';

class CoinManagementScreen extends StatefulWidget {
  final UserModel user;
  const CoinManagementScreen({super.key, required this.user});

  @override
  State<CoinManagementScreen> createState() => _CoinManagementScreenState();
}

class _CoinManagementScreenState extends State<CoinManagementScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _updateCoins(bool isAdding) async {
    final amountText = _amountController.text.trim();
    final reason = _reasonController.text.trim();
    
    if (amountText.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً مبلغ و دلیل را وارد کنید.')));
      return;
    }

    final amount = int.tryParse(amountText) ?? 0;
    if (amount <= 0) return;

    setState(() => _isProcessing = true);
    try {
      final change = isAdding ? amount : -amount;
      await AdminService.adjustUserCoins(
        userId: widget.user.id,
        amount: change,
        reason: reason,
      );
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تغییرات با موفقیت اعمال شد.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('مدیریت سکه: ${widget.user.username}')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('موجودی فعلی:'),
                      Text('${widget.user.coins} سکه', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'مقدار سکه', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'دلیل تغییر', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () => _updateCoins(true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('افزایش سکه'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () => _updateCoins(false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: const Text('کاهش سکه'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
