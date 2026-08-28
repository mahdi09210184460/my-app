import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Checks and returns a welcome message if it's the first time login.
  static Future<String?> checkWelcomeMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final key = 'welcome_seen_$userId';
    if (!prefs.getBool(key)!) {
      await prefs.setBool(key, true);
      return 'خوش آمدید! 🌟\nاز اینکه سکه‌چی را انتخاب کردید سپاسگزاریم. با بازی کردن و شرکت در چالش‌ها، جوایز نفیس ببرید.';
    }
    return null;
  }

  /// Returns the daily message for the user.
  /// Logic ensures only one display per day.
  static Future<String?> getDailyMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = 'daily_msg_$userId';
    
    if (prefs.getString(key) != today) {
      await prefs.setString(key, today);
      return 'سلام دوست عزیز 🌟\nامروز فرصت داری با بازی کردن سکه جمع کنی و شانس خودت برای جوایز را بیشتر کنی.';
    }
    return null;
  }

  /// Fetches user's notification history.
  static Future<List<NotificationModel>> getMyNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Marks a notification as read.
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }
}
