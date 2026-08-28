import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleChangePassword(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغییر رمز عبور'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'رمز عبور جدید'),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لغو')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تغییر')),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      try {
        await AccountService.changePassword(controller.text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز عبور با موفقیت تغییر یافت.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
        }
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف حساب کاربری', style: TextStyle(color: Colors.red)),
        content: const Text('آیا از حذف دائمی حساب خود اطمینان دارید؟ این عمل غیرقابل بازگشت است.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف حساب', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AccountService.deleteAccount();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در حذف حساب: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تنظیمات')),
        body: ListView(
          children: [
            _buildSectionTitle('امنیت حساب'),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('تغییر رمز عبور'),
              onTap: () => _handleChangePassword(context),
            ),
            ListTile(
              leading: const Icon(Icons.devices_other),
              title: const Text('خروج از همه دستگاه‌ها'),
              onTap: () async {
                await AccountService.signOutFromAllDevices();
                if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('حذف حساب کاربری', style: TextStyle(color: Colors.red)),
              onTap: () => _handleDeleteAccount(context),
            ),
            const Divider(),
            _buildSectionTitle('اطلاعات برنامه'),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('قوانین و مقررات'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('درباره سکه‌چی'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('تماس با پشتیبانی'),
              onTap: () {},
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'نسخه ۱.۰.۰',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
      ),
    );
  }
}
