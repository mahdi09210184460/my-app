import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../games/games_screen.dart';
import '../news/news_screen.dart';
import '../lottery/lottery_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../services/notification_service.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        _checkNotifications();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkNotifications() async {
    final welcome = await NotificationService.checkWelcomeMessage();
    if (welcome != null && mounted) {
      _showNotificationDialog('خوش آمدید', welcome);
      return;
    }
    final daily = await NotificationService.getDailyMessage();
    if (daily != null && mounted) {
      _showNotificationDialog('پیام روزانه', daily);
    }
  }

  void _showNotificationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          Center(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('متوجه شدم'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AppLoading();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildBalanceCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('بازی‌های سریع', () {
                    // Navigate to Games tab if using MainLayout index switching
                  }),
                  const SizedBox(height: 12),
                  _buildQuickGames(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('آخرین اخبار', () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen()));
                  }),
                  const SizedBox(height: 12),
                  _buildNewsBanner(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('قرعه‌کشی‌های فعال', () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const LotteryScreen()));
                  }),
                  const SizedBox(height: 12),
                  _buildLotteryTeaser(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('سکه‌چی', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryPurple, AppColors.primaryPurpleDark],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
      ),
      actions: [
        if (_user?.role == 'admin')
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.orangeAccent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
          ),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: 8,
      shadowColor: AppColors.primaryPurple.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.coinGold,
              child: Icon(Icons.monetization_on, size: 35, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('موجودی سکه‌های شما', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${_user?.coins ?? 0} سکه', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primaryPurple)),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {},
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(backgroundColor: AppColors.primaryPurpleLight.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onSeeAll, child: const Text('مشاهده همه')),
      ],
    );
  }

  Widget _buildQuickGames() {
    return Row(
      children: [
        _QuickGameItem(
          title: 'منچ',
          icon: Icons.casino,
          color: Colors.red.shade400,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen())),
        ),
        const SizedBox(width: 12),
        _QuickGameItem(
          title: 'مار و پله',
          icon: Icons.linear_scale,
          color: Colors.green.shade400,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen())),
        ),
      ],
    );
  }

  Widget _buildNewsBanner() {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen())),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.newspaper, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('جایزه ویژه این ماه اعلام شد!', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('برای مشاهده شرایط کلیک کنید', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLotteryTeaser() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.amber.shade700]),
      ),
      child: Stack(
        children: [
          Positioned(right: -10, bottom: -10, child: Icon(Icons.stars, size: 80, color: Colors.white.withValues(alpha: 0.3))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('قرعه‌کشی بزرگ ۱۰۰۰ سکه‌ای', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('همین حالا شانس خود را امتحان کنید', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LotteryScreen())),
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.orange.shade700),
                  child: const Text('ورود'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickGameItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickGameItem({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 35),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
