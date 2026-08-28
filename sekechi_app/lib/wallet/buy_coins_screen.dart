import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../models/payment_package_model.dart';
import '../core/theme/app_colors.dart';
import 'package:intl/intl.dart' as intl;

class BuyCoinsScreen extends StatefulWidget {
  const BuyCoinsScreen({super.key});

  @override
  State<BuyCoinsScreen> createState() => _BuyCoinsScreenState();
}

class _BuyCoinsScreenState extends State<BuyCoinsScreen> {
  List<PaymentPackageModel> _packages = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      final packages = await PaymentService.getActivePackages();
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در بارگذاری بسته‌ها: $e')));
      }
    }
  }

  Future<void> _startPayment(PaymentPackageModel package) async {
    setState(() => _isProcessing = true);
    try {
      // ۱. ایجاد درخواست در دیتابیس
      final payment = await PaymentService.initiatePayment(package);
      
      // ۲. در دنیای واقعی: هدایت به درگاه (url_launcher)
      // فعلاً شبیه‌سازی می‌کنیم
      if (!mounted) return;
      _showSimulationDialog(payment.id);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در شروع پرداخت: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSimulationDialog(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('شبیه‌ساز درگاه پرداخت'),
          content: const Text('در نسخه نهایی، شما در این مرحله به درگاه بانکی هدایت می‌شوید.\nآیا پرداخت با موفقیت انجام شود؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _verifyPayment(paymentId, 'FAILED', 'nok');
              },
              child: const Text('خطا در پرداخت'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _verifyPayment(paymentId, 'SIMULATED_TRANS_ID', 'OK');
              },
              child: const Text('پرداخت موفق'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyPayment(String paymentId, String authority, String status) async {
    setState(() => _isProcessing = true);
    try {
      final success = await PaymentService.verifyPayment(
        paymentId: paymentId,
        authority: authority,
        status: status,
      );

      if (!mounted) return;
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پرداخت ناموفق بود یا تایید نشد.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در تایید: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          title: const Text('خرید موفق'),
          content: const Text('حساب شما با موفقیت شارژ شد. اکنون می‌توانید در بازی‌ها و چالش‌ها شرکت کنید.'),
          actions: [
            Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog
                  Navigator.pop(context); // Screen
                },
                child: const Text('متوجه شدم'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = intl.NumberFormat.decimalPattern();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خرید سکه'),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _packages.length,
                    itemBuilder: (context, index) {
                      final pkg = _packages[index];
                      return _buildPackageCard(pkg, currencyFormat);
                    },
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildPackageCard(PaymentPackageModel pkg, intl.NumberFormat format) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: InkWell(
        onTap: _isProcessing ? null : () => _startPayment(pkg),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.coinGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.monetization_on, color: AppColors.coinGold, size: 35),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${format.format(pkg.coinsAmount)} سکه',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    format.format(pkg.priceIrr),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryPurple),
                  ),
                  const Text('تومان', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
