import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../models/coin_transaction_model.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_state.dart';
import 'buy_coins_screen.dart';
import 'package:intl/intl.dart' as intl;

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _balance = 0;
  List<CoinTransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final balance = await WalletService.getBalance();
      final txs = await WalletService.getTransactions();
      setState(() {
        _balance = balance;
        _transactions = txs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'خطا در دریافت اطلاعات کیف پول';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کیف پول'),
        elevation: 0,
      ),
      body: _isLoading
          ? const AppLoading(message: 'در حال دریافت اطلاعات مالی...')
          : _error != null
              ? AppErrorState(message: _error!, onRetry: _loadData)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildBalanceCard()),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Text(
                            'تراکنش‌های اخیر',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      _transactions.isEmpty
                          ? const SliverFillRemaining(
                              child: AppEmptyState(
                                title: 'تراکنشی ثبت نشده است',
                                message: 'هنوز فعالیتی که شامل تغییر سکه باشد انجام نداده‌اید.',
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _TransactionTile(tx: _transactions[index]),
                                  childCount: _transactions.length,
                                ),
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 30)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryPurple, AppColors.primaryPurpleDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            'موجودی فعلی شما',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: AppColors.coinGold, size: 40),
              const SizedBox(width: 12),
              Text(
                '$_balance',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 45,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'سکه',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyCoinsScreen())).then((_) => _loadData()),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('خرید سکه'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.redeem, size: 18),
                  label: const Text('کد هدیه'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final CoinTransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final bool isPositive = tx.amount > 0;
    final String dateStr = intl.DateFormat('yyyy/MM/dd HH:mm').format(tx.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(tx.type, isPositive),
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? "+" : ""}${tx.amount}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  'سکه',
                  style: TextStyle(fontSize: 10, color: isPositive ? Colors.green : Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type, bool isPositive) {
    if (type.contains('game')) return Icons.sports_esports;
    if (type.contains('shop')) return Icons.shopping_bag;
    if (type.contains('reward') || type.contains('bonus')) return Icons.card_giftcard;
    return isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline;
  }
}
