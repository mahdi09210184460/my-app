import 'package:flutter/material.dart';
import '../models/shop_item_model.dart';
import '../services/shop_service.dart';
import '../core/theme/app_colors.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ShopItemModel item;
  const ProductDetailsScreen({super.key, required this.item});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  bool _isProcessing = false;

  Future<void> _handlePurchase() async {
    setState(() => _isProcessing = true);
    try {
      await ShopService.purchaseItem(widget.item, quantity: _quantity);
      if (!mounted) return;
      
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در انجام عملیات: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('سفارش با موفقیت ثبت شد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              widget.item.coinPrice > 0 
                ? 'محصول خریداری شده و از سکه‌های شما کسر گردید.' 
                : 'درخواست شما ثبت شد. کارشناسان ما بزودی با شما تماس می‌گیرند.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('متوجه شدم'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCoinProduct = widget.item.coinPrice > 0;
    final int totalPrice = (isCoinProduct ? widget.item.coinPrice : widget.item.price) * _quantity;

    return Scaffold(
      appBar: AppBar(title: const Text('جزئیات محصول')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: widget.item.image != null
                            ? Image.network(widget.item.image!, fit: BoxFit.cover)
                            : const Icon(Icons.shopping_bag_outlined, size: 100, color: AppColors.divider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.item.category,
                          style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('توضیحات:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.7, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  _buildQuantitySelector(),
                ],
              ),
            ),
          ),
          _buildBottomAction(isCoinProduct, totalPrice),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('تعداد سفارش:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryPurple),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryPurple),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(bool isCoin, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مبلغ قابل پرداخت:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    isCoin ? '$total سکه' : '$total تومان',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isCoin ? AppColors.primaryPurple : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 58,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _handlePurchase,
                  style: FilledButton.styleFrom(
                    backgroundColor: isCoin ? AppColors.primaryPurple : Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isCoin ? 'خرید با سکه' : 'ثبت درخواست خدمت',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
