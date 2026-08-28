import 'package:flutter/material.dart';
import '../services/shop_service.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart' as intl;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ShopService.getMyOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری سفارشات: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سفارش‌های من')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
                ? const Center(child: Text('هنوز سفارشی ثبت نکرده‌اید.'))
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return _OrderTile(order: order);
                      },
                    ),
                  ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _buildStatusIcon(order.status),
        title: Text(
          order.itemTitleSnapshot,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('وضعیت: ${_translateStatus(order.status)}'),
        trailing: Text(
          '${order.coinAmount > 0 ? order.coinAmount : order.priceAtPurchase * order.quantity} ${order.coinAmount > 0 ? "سکه" : "تومان"}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('شناسه سفارش:', order.id),
                _detailRow('تعداد:', order.quantity.toString()),
                _detailRow('قیمت واحد:', '${order.priceAtPurchase} سکه'),
                _detailRow('تاریخ:', _formatDate(order.createdAt)),
                const Divider(),
                const Text(
                  'توضیحات مدیریت:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Text('در حال بررسی توسط کارشناسان...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'processing':
        icon = Icons.sync;
        color = Colors.blue;
        break;
      default:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
    }
    return Icon(icon, color: color);
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'completed': return 'تکمیل شده';
      case 'cancelled': return 'لغو شده';
      case 'processing': return 'در حال انجام';
      default: return 'در انتظار بررسی';
    }
  }

  String _formatDate(DateTime date) {
    return intl.DateFormat('yyyy/MM/dd HH:mm').format(date);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
