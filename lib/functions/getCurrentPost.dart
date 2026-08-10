import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<Map<String, dynamic>> getCurrentPost(String postID) async {
  final response = await supabase
      .from('posts')
      .select('''
      id,
      title,
      body,
      uuid,
      created_at,
      profiles (
        display_name
      ),
      post_images (
        image_url
      ),
      comments (
        count
        )
      )
    ''')
      .eq ('id', postID)
      .single();
      


  return response;
}