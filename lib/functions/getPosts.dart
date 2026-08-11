import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class PostsPage {
  final List<Map<String, dynamic>> posts;
  final bool hasNextPage;

  PostsPage({required this.posts, required this.hasNextPage});
}

Future<List<int>> _getHiddenPostIds() async {
  final currentUser = supabase.auth.currentUser;

  if (currentUser == null) {
    return [];
  }

  final response = await supabase
      .from('hidden_posts')
      .select('post_id')
      .eq('user_id', currentUser.id);

  return List<Map<String, dynamic>>.from(
    response,
  ).map((row) => row['post_id'] as int).toList();
}

Future<PostsPage> getPosts({
  required int page,
  int pageSize = 12,
  String searchQuery = '',
}) async {
  final from = page * pageSize;
  final to = from + pageSize;

  final search = searchQuery.trim();

  final hiddenPostIds = await _getHiddenPostIds();

  // Normal feed
  if (search.isEmpty) {
    final response = await supabase
        .from('posts')
        .select('''
      id,
      uuid,
      title,
      body,
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
    ''')
        .order('created_at', ascending: false)
        .range(from, to);

    final posts = List<Map<String, dynamic>>.from(
      response,
    ).where((post) => !hiddenPostIds.contains(post['id'] as int)).toList();

    final hasNextPage = posts.length > pageSize;

    if (hasNextPage) {
      posts.removeLast();
    }

    return PostsPage(posts: posts, hasNextPage: hasNextPage);
  }

  final titleResponse = await supabase
      .from('posts')
      .select('id')
      .ilike('title', '%$search%');

  final titlePostIds = List<Map<String, dynamic>>.from(
    titleResponse,
  ).map((post) => post['id'] as int).toSet();

  final profileResponse = await supabase
      .from('profiles')
      .select('uuid')
      .ilike('display_name', '%$search%');

  final profileUuids = List<Map<String, dynamic>>.from(
    profileResponse,
  ).map((profile) => profile['uuid'] as String).toList();

  final authorPostIds = <int>{};

  if (profileUuids.isNotEmpty) {
    final authorResponse = await supabase
        .from('posts')
        .select('id')
        .inFilter('uuid', profileUuids);

    authorPostIds.addAll(
      List<Map<String, dynamic>>.from(
        authorResponse,
      ).map((post) => post['id'] as int),
    );
  }

  final matchingPostIds = {...titlePostIds, ...authorPostIds}.toList();

  if (matchingPostIds.isEmpty) {
    return PostsPage(posts: [], hasNextPage: false);
  }

  final response = await supabase
      .from('posts')
      .select('''
  id,
  uuid,
  title,
  body,
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
''')
      .inFilter('id', matchingPostIds)
      .order('created_at', ascending: false)
      .range(from, to);

  final posts = List<Map<String, dynamic>>.from(response);

  final hasNextPage = posts.length > pageSize;

  if (hasNextPage) {
    posts.removeLast();
  }

  return PostsPage(posts: posts, hasNextPage: hasNextPage);
}
