import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<List<Map<String, dynamic>>> getComments(int postId) async {
  final response = await supabase
      .from('comments')
      .select('*, profiles(display_name, avatar_url), comment_images(*)')
      .eq('post_id', postId)
      .order('created_at');

  return List<Map<String, dynamic>>.from(response);
}

