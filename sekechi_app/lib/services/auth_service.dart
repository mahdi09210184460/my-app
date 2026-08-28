import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'wallet_service.dart';
import '../models/user_model.dart';
import '../core/failure.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client;

  static User? get currentUser => _client.auth.currentUser;

  static Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson({...response, 'email': user.email});
  }

  static Future<void> updateProfile({
    required String username,
    String? displayName,
  }) async {
    final user = currentUser;
    if (user == null) throw const AuthFailure('ابتدا وارد حساب خود شوید.');

    try {
      await _client.from('profiles').update({
        'username': username,
        'display_name': displayName,
      }).eq('id', user.id);
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'display_name': username,
        },
      );

      if (response.user != null && response.session != null) {
        try {
          await WalletService.claimSignupBonus();
        } catch (_) {}
      }
      
      return response;
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
