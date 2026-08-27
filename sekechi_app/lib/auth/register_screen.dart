import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../home/home_screen.dart';

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
    final confirmPassword =
        _confirmPasswordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(
        'لطفاً همه فیلدها را تکمیل کنید.',
      );
      return;
    }

    if (username.length < 3) {
      _showMessage(
        'نام کاربری باید حداقل ۳ کاراکتر باشد.',
      );
      return;
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email)) {
      _showMessage(
        'لطفاً یک ایمیل معتبر وارد کنید.',
      );
      return;
    }

    if (password.length < 8) {
      _showMessage(
        'رمز عبور باید حداقل ۸ کاراکتر باشد.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'رمزهای عبور یکسان نیستند.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
      await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'display_name': username,
        },
      );

      if (!mounted) return;

      final user = response.user;

      if (user == null) {
        _showMessage(
          'ثبت‌نام انجام نشد. دوباره تلاش کنید.',
        );
        return;
      }

// اگر تأیید ایمیل فعال باشد، هنوز session نداریم.
      if (response.session == null) {
        _showMessage(
          'ثبت‌نام انجام شد. لطفاً ایمیل خود را تأیید کنید.',
        );

        await Future.delayed(
          const Duration(seconds: 2),
        );

        if (!mounted) return;

        Navigator.of(context).pop();
        return;
      }

      _showMessage(
        'ثبت‌نام با موفقیت انجام شد. ۱۰۰ سکه هدیه گرفتید.',
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
            (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      final message =
      error.message.toLowerCase();

      if (message.contains('already registered') ||
          message.contains('user already registered')) {
        _showMessage(
          'این ایمیل قبلاً ثبت شده است.',
        );
      } else if (message.contains('password')) {
        _showMessage(
          'رمز عبور قابل قبول نیست.',
        );
      } else if (message.contains('email')) {
        _showMessage(
          'ایمیل واردشده معتبر نیست.',
        );
      } else {
        _showMessage(
          error.message,
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'خطایی هنگام ثبت‌نام رخ داد. دوباره تلاش کنید.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          title: const Text(
            'ثبت‌نام در سکه‌چی',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),

                const Icon(
                  Icons.person_add_alt_1,
                  size: 80,
                ),

                const SizedBox(height: 20),

                const Text(
                  'ساخت حساب جدید',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'اطلاعات خود را وارد کنید',
                ),

                const SizedBox(height: 30),

                TextField(
                  controller:
                  _usernameController,
                  textDirection:
                  TextDirection.ltr,
                  decoration:
                  const InputDecoration(
                    labelText: 'نام کاربری',
                    hintText:
                    'مثلاً sekechi_player',
                    border:
                    OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.person_outline,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller:
                  _emailController,
                  keyboardType:
                  TextInputType.emailAddress,
                  textDirection:
                  TextDirection.ltr,
                  decoration:
                  const InputDecoration(
                    labelText: 'ایمیل',
                    border:
                    OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller:
                  _passwordController,
                  obscureText:
                  _obscurePassword,
                  textDirection:
                  TextDirection.ltr,
                  decoration:
                  InputDecoration(
                    labelText: 'رمز عبور',
                    border:
                    const OutlineInputBorder(),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon:
                    IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons
                            .visibility_outlined
                            : Icons
                            .visibility_off_outlined,
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

                const SizedBox(height: 16),

                TextField(
                  controller:
                  _confirmPasswordController,
                  obscureText:
                  _obscureConfirmPassword,
                  textDirection:
                  TextDirection.ltr,
                  decoration:
                  InputDecoration(
                    labelText:
                    'تکرار رمز عبور',
                    border:
                    const OutlineInputBorder(),
                    prefixIcon:
                    const Icon(
                      Icons.lock_reset_outlined,
                    ),
                    suffixIcon:
                    IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons
                            .visibility_outlined
                            : Icons
                            .visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed:
                    _isLoading
                        ? null
                        : _register,
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                      CircularProgressIndicator(),
                    )
                        : const Text(
                      'ایجاد حساب',
                    ),
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










