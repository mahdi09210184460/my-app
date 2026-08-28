import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/failure.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: 'https://yslkhmuwcmdqiituzfpx.supabase.co',
        publishableKey: 'sb_publishable_diqg6Q06Q8bl8tr4nuzFYg_dDQUH_uM',
      );
    } catch (e) {
      throw ServerFailure('خطا در اتصال به سرور: ${e.toString()}');
    }
  }

  static Failure handleException(Object e) {
    if (e is AuthException) {
      return AuthFailure(_translateAuthError(e.message));
    } else if (e is PostgrestException) {
      return ServerFailure('خطای دیتابیس: ${e.message}');
    }
    return Failure('خطای نامشخص رخ داد');
  }

  static String _translateAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('already registered')) return 'این ایمیل قبلاً ثبت شده است.';
    if (msg.contains('invalid login credentials')) return 'ایمیل یا رمز عبور اشتباه است.';
    if (msg.contains('email not confirmed')) return 'لطفاً ابتدا ایمیل خود را تأیید کنید.';
    return 'خطا در احراز هویت';
  }
}
