import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://yslkhmuwcmdqiituzfpx.supabase.co',
      anonKey: 'sb_publishable_diqg6Q06Q8bl8tr4nuzFYg_dDQUH_uM',
    );
  }
}


