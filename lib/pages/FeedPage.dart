import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blogorum/components/sideBar.dart';
import 'package:blogorum/components/topBar.dart';
import 'package:blogorum/components/post_card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:blogorum/functions/getPosts.dart';

final supabase = Supabase.instance.client;

final user = supabase.auth.currentUser?.email ?? 'Guest';
String _searchQuery = '';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const int _pageSize = 12;

  int _currentPage = 0;
  bool _hasNextPage = false;

  late Future<PostsPage> _postsFuture;

  @override
  void initState() {
    super.initState();

    _loadPage(0);
  }

  void _loadPage(int page, {String? searchQuery}) {
    final query = searchQuery ?? _searchQuery;

    setState(() {
      _currentPage = page;
      _searchQuery = query;

      _postsFuture = _loadPostsWithoutHidden(
        page: page,
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

  Future<PostsPage> _loadPostsWithoutHidden({
    required int page,
    required String searchQuery,
  }) async {
    final result = await getPosts(
      page: page,
      pageSize: _pageSize,
      searchQuery: searchQuery,
    );

    final currentUser = supabase.auth.currentUser;

    // Guests don't have hidden posts.
    if (currentUser == null) {
      return result;
    }

    final hidden = await supabase
        .from('hidden_posts')
        .select('post_id')
        .eq('user_id', currentUser.id);

    final hiddenPostIds = hidden
        .map<int>((row) => row['post_id'] as int)
        .toSet();

    final filteredPosts = result.posts
        .where((post) => !hiddenPostIds.contains(post['id']))
        .toList();

    return PostsPage(posts: filteredPosts, hasNextPage: result.hasNextPage);
  }

  void _searchPosts(String query) {
    _loadPage(0, searchQuery: query.trim());
  }

  void _goToPage(int page) {
    if (page < 0) return;

    if (page > _currentPage && !_hasNextPage) {
      return;
    }

    _loadPage(page);
  }

  Future<void> _refresh() async {
    _loadPage(0);

    await _postsFuture;
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
      child: Row(
        children: [
          sideBar(),

          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    TopBar(onSearch: _searchPosts),
                    Expanded(
                      child: FutureBuilder<PostsPage>(
                        future: _postsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
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
                              child: Text('Unable to load posts.'),
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
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.7,
                                    child: Center(
                                      child: Text(
                                        'No posts yet.',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: [
                              // SCROLLABLE POSTS
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _refresh,
                                  child: MasonryGridView.count(
                                    padding: const EdgeInsets.all(12),
                                    physics: const BouncingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                                    cacheExtent: 1000,
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
                      onTap: () => _refresh(),
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
      authorId: post['uuid'],
      comments: commentCount,
      postID: post['id'],
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
