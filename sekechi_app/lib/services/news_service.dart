import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/news_model.dart';

class NewsService {
  static SupabaseClient get _client => SupabaseService.client;

  /// Fetches all active news for users.
  static Future<List<NewsModel>> getActiveNews() async {
    try {
      final response = await _client
          .from('news')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List).map((e) => NewsModel.fromJson(e)).toList();
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }

  /// Fetches details of a single news item.
  static Future<NewsModel?> getNewsDetail(String newsId) async {
    try {
      final response = await _client
          .from('news')
          .select()
          .eq('id', newsId)
          .maybeSingle();

      if (response == null) return null;
      return NewsModel.fromJson(response);
    } catch (e) {
      throw SupabaseService.handleException(e);
    }
  }
}
