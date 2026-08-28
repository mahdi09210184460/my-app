import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../core/constants.dart';

class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({super.key});

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen> {
  bool _isLoading = true;
  bool _isClaiming = false;
  bool _canClaim = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _checkReward();
  }

  Future<void> _checkReward() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _message = 'ابتدا وارد حساب خود شوید.';
        });
        return;
      }

      final reward = await SupabaseService.client
          .from('daily_rewards')
          .select('last_claimed_at')
          .eq('user_id', user.id)
          .maybeSingle();

      bool canClaim = true;
      if (reward != null && reward['last_claimed_at'] != null) {
        final lastClaimed = DateTime.parse(reward['last_claimed_at'].toString()).toLocal();
        final difference = DateTime.now().difference(lastClaimed);
        if (difference < const Duration(hours: 24)) {
          canClaim = false;
        }
      }

      if (mounted) {
        setState(() {
          _canClaim = canClaim;
          _isLoading = false;
          _message = canClaim ? 'پاداش امروز آماده دریافت است.' : 'پاداش روزانه قبلاً دریافت شده است.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = 'بررسی پاداش روزانه انجام نشد.';
        });
      }
    }
  }

  Future<void> _claimReward() async {
    if (_isClaiming || !_canClaim) return;
    setState(() => _isClaiming = true);

    try {
      // WalletService internal RPC call (if defined) or direct RPC for reward
      final result = await SupabaseService.client.rpc('claim_daily_reward');
      
      if (!mounted) return;
      final newBalance = (result as num?)?.toInt();

      setState(() {
        _canClaim = false;
        _isClaiming = false;
        _message = '${AppConstants.dailyRewardAmount} سکه با موفقیت دریافت شد.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newBalance != null ? '${AppConstants.dailyRewardAmount} سکه دریافت کردید. موجودی جدید: $newBalance سکه' : '${AppConstants.dailyRewardAmount} سکه دریافت کردید.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isClaiming = false);
      _showMessage('دریافت پاداش انجام نشد. دوباره تلاش کنید.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پاداش روزانه', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    const Icon(Icons.card_giftcard, size: 100),
                    const SizedBox(height: 25),
                    const Text('پاداش روزانه', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('هر ۲۴ ساعت یک بار می‌توانید\n${AppConstants.dailyRewardAmount} سکه رایگان دریافت کنید.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 30),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          children: [
                            const Icon(Icons.monetization_on, size: 60),
                            const SizedBox(height: 12),
                            Text('+${AppConstants.dailyRewardAmount} سکه', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(_message, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton.icon(
                        onPressed: _canClaim && !_isClaiming ? _claimReward : null,
                        icon: _isClaiming ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator()) : const Icon(Icons.redeem),
                        label: Text(_isClaiming ? 'در حال دریافت...' : _canClaim ? 'دریافت ${AppConstants.dailyRewardAmount} سکه' : 'پاداش دریافت شده'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
