import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blogorum/components/post_card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:blogorum/functions/getPosts.dart';

final supabase = Supabase.instance.client;

class HiddenPage extends StatefulWidget {
  const HiddenPage({super.key});

  @override
  State<HiddenPage> createState() => _HiddenPageState();
}

class _HiddenPageState extends State<HiddenPage> {
  static const int _pageSize = 12;

  int _currentPage = 0;
  bool _hasNextPage = false;
  String _searchQuery = '';

  late Future<PostsPage> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPage(0);
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

    return (response as List).map((row) => row['post_id'] as int).toList();
  }

  Future<PostsPage> _loadHiddenPosts({
    required int page,
    int pageSize = 12,
    String searchQuery = '',
  }) async {
    final hiddenIds = await _getHiddenPostIds();

    if (hiddenIds.isEmpty) {
      return PostsPage(posts: [], hasNextPage: false);
    }

    var query = supabase
        .from('posts')
        .select('''
          *,
          profiles(display_name),
          post_images(image_url),
          comments(count)
        ''')
        .inFilter('id', hiddenIds);

    if (searchQuery.trim().isNotEmpty) {
      final search = searchQuery.trim();
      query = query.or('title.ilike.%$search%,body.ilike.%$search%');
    }

    final from = page * pageSize;
    final to = from + pageSize;

    final response = await query
        .order('created_at', ascending: false)
        .range(from, to);

    final posts = List<Map<String, dynamic>>.from(response);

    return PostsPage(
      posts: posts.take(pageSize).toList(),
      hasNextPage: posts.length > pageSize,
    );
  }

  void _loadPage(int page, {String? searchQuery}) {
    final query = searchQuery ?? _searchQuery;

    setState(() {
      _currentPage = page;
      _searchQuery = query;

      _postsFuture = _loadHiddenPosts(
        page: page,
        pageSize: _pageSize,
        searchQuery: _searchQuery,
      );
    });

    _postsFuture.then((result) {
      if (!mounted) return;

      setState(() {
        _hasNextPage = result.hasNextPage;
      });
    });
  }

  void _goToPage(int page) {
    if (page < 0) return;

    if (page > _currentPage && !_hasNextPage) {
      return;
    }

    _loadPage(page);
  }

  Future<void> _refresh() async {
    _loadPage(_currentPage);
    await _postsFuture;
  }

  Future<void> _unhidePost(int postId) async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) return;

    await supabase
        .from('hidden_posts')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', currentUser.id);

    if (!mounted) return;

    _loadPage(_currentPage);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final crossAxisCount = width > 1400
        ? 4
        : width > 1000
        ? 3
        : width > 700
        ? 2
        : 1;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FutureBuilder<PostsPage>(
                  future: _postsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () {
                                _loadPage(_currentPage);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: Text('Unable to load hidden posts.'),
                      );
                    }

                    final result = snapshot.data!;
                    final posts = result.posts;

                    if (posts.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Center(
                                child: Text(
                                  'No hidden posts.',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refresh,
                            child: MasonryGridView.count(
                              padding: const EdgeInsets.all(12),
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                return _buildPostCard(posts[index]);
                              },
                            ),
                          ),
                        ),

                        _buildPaginator(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 84,
            right: 24,
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 6,
              shadowColor: Theme.of(context).colorScheme.shadow,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _refresh,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final profile = post['profiles'] as Map<String, dynamic>?;

    final images = (post['post_images'] as List<dynamic>? ?? [])
        .map((image) => image['image_url'] as String)
        .toList();

    final comments = post['comments'] as List<dynamic>? ?? [];

    final commentCount = comments.isNotEmpty
        ? comments[0]['count'] as int? ?? 0
        : 0;

    return PostCard(
      title: post['title'],
      body: post['body'],
      images: images,
      createdAt: DateTime.parse(post['created_at']),
      author: profile?['display_name'] ?? 'Unknown',
      comments: commentCount,
      postID: post['id'],
      onUnhide: () => _unhidePost(post['id']),
      authorId: post['uuid'],
    );
  }

  Widget _buildPaginator() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous page',
            onPressed: _currentPage > 0
                ? () => _goToPage(_currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page ${_currentPage + 1}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),

          const SizedBox(width: 8),

          IconButton(
            tooltip: 'Next page',
            onPressed: _hasNextPage ? () => _goToPage(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
