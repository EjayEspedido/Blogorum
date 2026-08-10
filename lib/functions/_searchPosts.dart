import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<List<Map<String, dynamic>>> searchPosts(String query) async {
  final search = query.trim();

  if (search.isEmpty) {
    return [];
  }

  // Search post titles
  final titleResults = await supabase
      .from('posts')
      .select('''
        id,
        uuid,
        title,
        body,
        created_at,
        updated_at,
        profiles (
          uuid,
          display_name,
          avatar_url
        ),
        post_images (
          id,
          image_url
        ),
        comments (
          count
        )
      ''')
      .ilike('title', '%$search%')
      .order('created_at', ascending: false);

  // Search usernames/display names
  final profileResults = await supabase
      .from('profiles')
      .select('uuid')
      .ilike('display_name', '%$search%');

  final profileUuids = profileResults
      .map((profile) => profile['uuid'] as String)
      .toList();

  List<Map<String, dynamic>> authorResults = [];

  if (profileUuids.isNotEmpty) {
    authorResults = List<Map<String, dynamic>>.from(
      await supabase
          .from('posts')
          .select('''
            id,
            uuid,
            title,
            body,
            created_at,
            updated_at,
            profiles (
              uuid,
              display_name,
              avatar_url
            ),
            post_images (
              id,
              image_url
            ),
            comments (
              count
            )
          ''')
          .inFilter('uuid', profileUuids)
          .order('created_at', ascending: false),
    );
  }

  // Merge title + author results without duplicates
  final combined = <int, Map<String, dynamic>>{};

  for (final post in titleResults) {
    combined[post['id'] as int] = Map<String, dynamic>.from(post);
  }

  for (final post in authorResults) {
    combined[post['id'] as int] = Map<String, dynamic>.from(post);
  }

  final results = combined.values.toList();

  // Newest first
  results.sort((a, b) {
    final aDate = DateTime.parse(a['created_at'] as String);
    final bDate = DateTime.parse(b['created_at'] as String);

    return bDate.compareTo(aDate);
  });

  return results;
}