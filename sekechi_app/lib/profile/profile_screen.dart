import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  String _email = '';
  int _points = 0;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final supabase = SupabaseService.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('username, display_name, points')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile != null) {
        _usernameController.text =
            profile['username']?.toString() ?? '';

        _displayNameController.text =
            profile['display_name']?.toString() ?? '';

        _points =
            (profile['points'] as num?)?.toInt() ?? 0;
      }

      _email = user.email ?? '';

      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'دریافت اطلاعات پروفایل انجام نشد.',
      );
    }
  }

  Future<void> _saveProfile() async {
    final username =
    _usernameController.text.trim();

    final displayName =
    _displayNameController.text.trim();

    if (username.isEmpty) {
      _showMessage(
        'نام کاربری نمی‌تواند خالی باشد.',
      );
      return;
    }

    if (username.length < 3) {
      _showMessage(
        'نام کاربری باید حداقل ۳ کاراکتر باشد.',
      );
      return;
    }

    final user =
        SupabaseService.client.auth.currentUser;

    if (user == null) {
      _showMessage(
        'ابتدا وارد حساب خود شوید.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await SupabaseService.client
          .from('profiles')
          .update({
        'username': username,
        'display_name':
        displayName.isEmpty ? null : displayName,
      }).eq('id', user.id);

      if (!mounted) return;

      _showMessage(
        'پروفایل با موفقیت ذخیره شد.',
      );
    } catch (error) {
      if (!mounted) return;

      final message =
      error.toString().toLowerCase();

      if (message.contains('duplicate') ||
          message.contains('unique')) {
        _showMessage(
          'این نام کاربری قبلاً استفاده شده است.',
        );
      } else {
        _showMessage(
          'ذخیره پروفایل انجام نشد.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
            'پروفایل من',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              const CircleAvatar(
                radius: 55,
                child: Icon(
                  Icons.person,
                  size: 60,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                _displayNameController.text.isEmpty
                    ? _usernameController.text
                    : _displayNameController.text,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                _email,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 25),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on_outlined,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          const Text(
                            'موجودی سکه',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_points',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

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
                    Icons.alternate_email,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller:
                _displayNameController,
                decoration:
                const InputDecoration(
                  labelText: 'نام نمایشی',
                  hintText:
                  'نامی که دیگران می‌بینند',
                  border:
                  OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed:
                  _isSaving
                      ? null
                      : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                    CircularProgressIndicator(),
                  )
                      : const Text(
                    'ذخیره تغییرات',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


