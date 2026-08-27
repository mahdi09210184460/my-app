import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _points = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final supabase = SupabaseService.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('points')
          .eq('id', user.id)
          .maybeSingle();

      final transactions = await supabase
          .from('coin_transactions')
          .select(
        'id, amount, balance_after, type, description, created_at',
      )
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      if (!mounted) return;

      setState(() {
        _points = (profile?['points'] as num?)?.toInt() ?? 0;

        _transactions = List<Map<String, dynamic>>.from(
          transactions,
        );

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'دریافت اطلاعات کیف پول انجام نشد.',
      );
    }
  }

  String _transactionTitle(Map<String, dynamic> transaction) {
    final description = transaction['description'];

    if (description != null &&
        description.toString().trim().isNotEmpty) {
      return description.toString();
    }

    final type = transaction['type']?.toString();

    switch (type) {
      case 'signup_bonus':
        return 'هدیه ثبت‌نام';

      case 'game_reward':
        return 'جایزه بازی';

      case 'game_entry':
        return 'ورود به بازی';

      case 'daily_reward':
        return 'پاداش روزانه';

      default:
        return 'تراکنش سکه';
    }
  }

  IconData _transactionIcon(Map<String, dynamic> transaction) {
    final amount =
        (transaction['amount'] as num?)?.toInt() ?? 0;

    if (amount > 0) {
      return Icons.add_circle_outline;
    }

    return Icons.remove_circle_outline;
  }

  String _formatAmount(Map<String, dynamic> transaction) {
    final amount =
        (transaction['amount'] as num?)?.toInt() ?? 0;

    if (amount > 0) {
      return '+$amount';
    }

    return amount.toString();
  }

  String _formatDate(String? value) {
    if (value == null) return '';

    try {
      final date = DateTime.parse(value).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$year/$month/$day - $hour:$minute';
    } catch (_) {
      return '';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'کیف پول',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : RefreshIndicator(
          onRefresh: _loadWallet,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBalanceCard(),

              const SizedBox(height: 28),

              const Text(
                'تاریخچه سکه‌ها',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (_transactions.isEmpty)
                _buildEmptyState()
              else
                ..._transactions.map(
                  _buildTransactionItem,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.monetization_on,
              size: 65,
            ),

            const SizedBox(height: 12),

            const Text(
              'موجودی سکه',
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$_points',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'سکه',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 55,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            const Text(
              'هنوز تراکنشی ثبت نشده است.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
      Map<String, dynamic> transaction,
      ) {
    final amount =
        (transaction['amount'] as num?)?.toInt() ?? 0;

    final isPositive = amount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            _transactionIcon(transaction),
          ),
        ),
        title: Text(
          _transactionTitle(transaction),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _formatDate(
            transaction['created_at']?.toString(),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatAmount(transaction),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPositive
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            Text(
              'موجودی: ${transaction['balance_after'] ?? 0}',
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


