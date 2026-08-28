import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'users_management_screen.dart';
import 'orders_management_screen.dart';
import 'shop_management_screen.dart';
import 'news_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isAdmin = await AdminService.isAdmin();
      if (!isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('دسترسی شما محدود شده است.')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final stats = await AdminService.getAdminStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پنل مدیریت سکه‌چی'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkAccessAndLoad,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('خطا: $_error', style: const TextStyle(color: Colors.red)),
                        ElevatedButton(
                          onPressed: _checkAccessAndLoad,
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsGrid(),
                        const SizedBox(height: 24),
                        const Text(
                          'بخش‌های مدیریتی',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildMenuGrid(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard('کاربران', _stats?['total_users']?.toString() ?? '۰', Icons.people, Colors.blue),
        _buildStatCard('سفارشات', _stats?['total_orders']?.toString() ?? '۰', Icons.shopping_bag, Colors.orange),
        _buildStatCard('در انتظار', _stats?['pending_orders']?.toString() ?? '۰', Icons.hourglass_empty, Colors.red),
        _buildStatCard('کل سکه‌ها', _stats?['total_coins']?.toString() ?? '۰', Icons.monetization_on, Colors.amber),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMenuCard('کاربران', Icons.manage_accounts, Colors.indigo, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersManagementScreen()));
        }),
        _buildMenuCard('سفارشات', Icons.receipt_long, Colors.teal, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersManagementScreen()));
        }),
        _buildMenuCard('فروشگاه', Icons.storefront, Colors.deepPurple, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopManagementScreen()));
        }),
        _buildMenuCard('اخبار', Icons.campaign, Colors.pink, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsManagementScreen()));
        }),
      ],
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
