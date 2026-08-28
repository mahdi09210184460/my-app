import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart' as intl;

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  List<OrderModel> _allOrders = [];
  List<OrderModel> _filteredOrders = [];
  bool _isLoading = true;
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await AdminService.getOrders();
      setState(() {
        _allOrders = orders;
        _applyFilter(_currentFilter);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      if (filter == 'all') {
        _filteredOrders = _allOrders;
      } else {
        _filteredOrders = _allOrders.where((o) => o.status == filter).toList();
      }
    });
  }

  Future<void> _changeStatus(OrderModel order) async {
    final reasonController = TextEditingController();
    String? selectedStatus;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تغییر وضعیت سفارش'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: order.status,
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('در انتظار')),
                  DropdownMenuItem(value: 'processing', child: Text('در حال انجام')),
                  DropdownMenuItem(value: 'completed', child: Text('تکمیل شده')),
                  DropdownMenuItem(value: 'cancelled', child: Text('لغو شده')),
                ],
                onChanged: (v) => selectedStatus = v,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'وضعیت جدید'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'دلیل تغییر (اجباری)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ثبت تغییرات')),
          ],
        ),
      ),
    );

    if (result == true && selectedStatus != null && reasonController.text.isNotEmpty) {
      try {
        await AdminService.updateOrderStatus(
          orderId: order.id,
          status: selectedStatus!,
          reason: reasonController.text,
        );
        _loadOrders();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وضعیت سفارش با موفقیت تغییر یافت.')));
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
          title: const Text('مدیریت سفارشات'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _filterChip('همه', 'all'),
                  const SizedBox(width: 8),
                  _filterChip('در انتظار', 'pending'),
                  const SizedBox(width: 8),
                  _filterChip('تکمیل شده', 'completed'),
                  const SizedBox(width: 8),
                  _filterChip('لغو شده', 'cancelled'),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadOrders,
                child: ListView.builder(
                  itemCount: _filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.itemTitleSnapshot, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                _buildStatusBadge(order.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('کاربر: ${order.userId}'),
                            Text('مبلغ: ${order.coinAmount} سکه | ${order.priceAtPurchase} تومان'),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  intl.DateFormat('yyyy/MM/dd HH:mm').format(order.createdAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                TextButton.icon(
                                  onPressed: () => _changeStatus(order),
                                  icon: const Icon(Icons.edit_note),
                                  label: const Text('تغییر وضعیت'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _applyFilter(value),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String label = status;
    switch (status) {
      case 'pending': color = Colors.orange; label = 'در انتظار'; break;
      case 'processing': color = Colors.blue; label = 'در حال انجام'; break;
      case 'completed': color = Colors.green; label = 'تکمیل شده'; break;
      case 'cancelled': color = Colors.red; label = 'لغو شده'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
