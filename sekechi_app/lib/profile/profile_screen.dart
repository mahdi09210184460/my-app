import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/account_service.dart';
import '../services/admin_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../models/user_model.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_loading.dart';
import '../settings/settings_screen.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userModel = await AuthService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _user = userModel;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEditProfile() async {
    final controller = TextEditingController(text: _user?.username);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ویرایش پروفایل'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'نام نمایشی جدید'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      try {
        await AccountService.updateProfile(username: controller.text);
        _loadProfile();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
      }
    }
  }

  Future<void> _navigateToAdminPanel() async {
    // نمایش لودینگ کوتاه برای بررسی دسترسی
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final isAdmin = await AdminService.isAdmin();
      if (!mounted) return;
      Navigator.pop(context); // بستن لودینگ

      if (isAdmin) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا: دسترسی مدیریت تایید نشد.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در بررسی دسترسی: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AppLoading();

    return Scaffold(
      appBar: AppBar(
        title: const Text('حساب کاربری'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildDetailedInfo(),
              if (_user?.role == 'admin') _buildAdminSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.shade200),
        ),
        child: ListTile(
          leading: Icon(Icons.admin_panel_settings, color: Colors.red.shade700, size: 30),
          title: Text(
            'پنل مدیریت سیستم',
            style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('دسترسی به تنظیمات حساس و نظارتی'),
          trailing: Icon(Icons.chevron_right, color: Colors.red.shade700),
          onTap: _navigateToAdminPanel,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white24,
                backgroundImage: _user?.avatar != null ? NetworkImage(_user!.avatar!) : null,
                child: _user?.avatar == null ? const Icon(Icons.person, size: 70, color: Colors.white) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: AppColors.coinGold,
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    onPressed: _handleEditProfile,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _user?.username ?? 'کاربر',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _user?.email ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (_user?.role == 'admin')
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('مدیر سیستم', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _StatCard(title: 'کل بازی‌ها', value: '${_user?.gamesPlayed ?? 0}', color: Colors.blue),
          const SizedBox(width: 12),
          _StatCard(title: 'بردها', value: '${_user?.gamesWon ?? 0}', color: Colors.green),
          const SizedBox(width: 12),
          _StatCard(title: 'باخت‌ها', value: '${_user?.gamesLost ?? 0}', color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _infoTile(Icons.monetization_on, 'موجودی سکه', '${_user?.coins ?? 0} سکه', AppColors.coinGoldDark),
          const Divider(height: 1),
          _infoTile(Icons.calendar_month, 'تاریخ عضویت', DateFormat('yyyy/MM/dd').format(_user?.createdAt ?? DateTime.now()), Colors.blueGrey),
          const Divider(height: 1),
          _infoTile(Icons.verified_user_outlined, 'وضعیت حساب', 'تایید شده', Colors.green),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color iconColor) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      trailing: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}
