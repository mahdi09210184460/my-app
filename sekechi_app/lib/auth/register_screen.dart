import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../home/home_screen.dart';
import '../core/failure.dart';
import '../core/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('لطفاً همه فیلدها را تکمیل کنید.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('رمزهای عبور یکسان نیستند.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.signUp(
        email: email,
        password: password,
        username: username,
      );

      if (!mounted) return;

      if (response.session == null) {
        _showMessage('ثبت‌نام انجام شد. لطفاً ایمیل خود را تأیید کنید.');
        Navigator.of(context).pop();
      } else {
        _showMessage('ثبت‌نام با موفقیت انجام شد. ${AppConstants.signupBonus} سکه هدیه گرفتید.');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } on Failure catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('خطایی نامشخص رخ داد');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
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
          title: const Text('ثبت‌نام در ${AppConstants.appName}', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.person_add_alt_1, size: 80),
                const SizedBox(height: 20),
                const Text('ساخت حساب جدید', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextField(
                  controller: _usernameController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'نام کاربری',
                    hintText: 'مثلاً player1',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'ایمیل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'رمز عبور',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'تکرار رمز عبور',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading ? const CircularProgressIndicator() : const Text('ایجاد حساب'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
