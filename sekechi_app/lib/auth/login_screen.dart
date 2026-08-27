import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

import 'register_screen.dart';
import '../home/home_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showMessage('لطفاً نام کاربری یا ایمیل و رمز عبور را وارد کنید.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = SupabaseService.client;

      String email = identifier;

// اگر کاربر نام کاربری وارد کرده باشد،
// ایمیل مربوط به آن را از پروفایل پیدا می‌کنیم.
      if (!identifier.contains('@')) {
        final profile = await supabase
            .from('profiles')
            .select('id')
            .eq('username', identifier)
            .maybeSingle();

        if (profile == null) {
          _showMessage('نام کاربری یا رمز عبور اشتباه است.');
          return;
        }

        final userId = profile['id'] as String;

        final userResponse = await supabase
            .from('profiles')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (userResponse == null) {
          _showMessage('حساب کاربری پیدا نشد.');
          return;
        }

// Supabase Auth برای ورود با نام کاربری مستقیماً ایمیل را
// از جدول profiles در اختیار ما نمی‌گذارد.
// بنابراین در نسخه امن نهایی باید یک Edge Function سمت سرور
// برای تبدیل username به email داشته باشیم.
        _showMessage(
          'ورود با نام کاربری در مرحله بعد با سرویس امن سرور فعال می‌شود. فعلاً با ایمیل وارد شوید.',
        );
        return;
      }

      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      _showMessage('ورود با موفقیت انجام شد.');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(),
        ),
            (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      String message = 'ورود انجام نشد.';

      final errorMessage = error.message.toLowerCase();

      if (errorMessage.contains('invalid login credentials')) {
        message = 'ایمیل یا رمز عبور اشتباه است.';
      } else if (errorMessage.contains('email not confirmed')) {
        message = 'لطفاً ابتدا ایمیل خود را تأیید کنید.';
      } else if (errorMessage.contains('too many requests')) {
        message = 'تعداد تلاش‌ها زیاد است. کمی بعد دوباره امتحان کنید.';
      }

      _showMessage(message);
    } catch (error) {
      if (!mounted) return;

      _showMessage('خطایی در ورود رخ داد. دوباره تلاش کنید.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _identifierController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMessage(
        'برای بازیابی رمز، ابتدا ایمیل خود را وارد کنید.',
      );
      return;
    }

    try {
      await SupabaseService.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.sekechi://reset-password',
      );

      if (!mounted) return;

      _showMessage(
        'لینک بازیابی رمز عبور به ایمیل شما ارسال شد.',
      );
    } on AuthException {
      if (!mounted) return;

      _showMessage(
        'ارسال لینک بازیابی انجام نشد. ایمیل را بررسی کنید.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'خطایی در بازیابی رمز عبور رخ داد.',
      );
    }
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ورود به سکه‌چی'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.casino,
                    size: 90,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'خوش آمدید',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'برای ادامه وارد حساب خود شوید',
                  ),

                  const SizedBox(height: 35),

                  TextField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'نام کاربری یا ایمیل',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.person_outline,
                      ),
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
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                            !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed:
                      _isLoading ? null : _forgotPassword,
                      child: const Text(
                        'رمز عبور را فراموش کرده‌اید؟',
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      )
                          : const Text('ورود'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Text(
                        'حساب کاربری ندارید؟',
                      ),
                      TextButton(
                        onPressed:
                        _isLoading ? null : _openRegister,
                        child: const Text('ثبت‌نام'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}








