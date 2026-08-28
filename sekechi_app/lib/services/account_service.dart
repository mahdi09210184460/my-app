import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AccountService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Updates the user's display name and avatar URL.
  static Future<void> updateProfile({
    required String username,
    String? avatarUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('ابتدا وارد حساب خود شوید.');

    try {
      await _client.from('profiles').update({
        'username': username,
        'avatar_url': avatarUrl,
      }).eq('id', userId);
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Changes the user's password.
  static Future<void> changePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Signs out from all active sessions/devices.
  static Future<void> signOutFromAllDevices() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.global);
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Deletes the user account and associated profile data.
  /// Note: This usually requires a server-side function or administrative privileges in Supabase
  /// to delete from auth.users. Here we provide a template for profile cleanup.
  static Future<void> deleteAccount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. Delete profile data (RLS will ensure only owner can delete)
      await _client.from('profiles').delete().eq('id', userId);
      
      // 2. Sign out
      await _client.auth.signOut();
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }
}
