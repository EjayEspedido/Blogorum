import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import 'package:blogorum/components/post_card.dart';

final supabase = Supabase.instance.client;

class Profile extends StatefulWidget {
  final String? userId;

  const Profile({super.key, this.userId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late Future<Map<String, dynamic>?> _profileFuture;
  late Future<List<Map<String, dynamic>>> _postsFuture;

  String get _userId => widget.userId ?? supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();

    _profileFuture = _getProfile();
    _postsFuture = _getPosts();
  }

  Future<Map<String, dynamic>?> _getProfile() async {
    return await supabase
        .from('profiles')
        .select()
        .eq('uuid', _userId)
        .maybeSingle();
  }

  Future<List<Map<String, dynamic>>> _getPosts() async {
    final response = await supabase
        .from('posts')
        .select('''
          id,
          uuid,
          title,
          body,
          created_at,
          profiles(display_name),
          post_images(image_url),
          comments(count)
        ''')
        .eq('uuid', _userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileSnapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load profile:\n${profileSnapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final profile = profileSnapshot.data;

        if (profile == null) {
          return const Center(child: Text('Profile not found.'));
        }

        final displayName =
            (profile['display_name'] as String?)?.trim().isNotEmpty == true
            ? profile['display_name']
            : 'New User';

        final email = profile['email'] as String? ?? '';
        final bio = profile['bio'] as String? ?? '';
        final avatarUrl = profile['avatar_url'] as String?;

        final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

        final isMyProfile = supabase.auth.currentUser?.id == _userId;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: hasAvatar
                        ? null
                        : Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32),
                          ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),

                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],

                        if (bio.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            bio,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],

                        // if (isMyProfile) ...[
                        //   const SizedBox(height: 16),
                        //   OutlinedButton.icon(
                        //     onPressed: () {
                        //       context.go('/editProfile');
                        //     },
                        //     icon: const Icon(Icons.edit),
                        //     label: const Text('Edit Profile'),
                        //   ),
                        // ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              Text('Posts', style: Theme.of(context).textTheme.titleLarge),

              const SizedBox(height: 16),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Text('Failed to load posts.');
                  }

                  final posts = snapshot.data ?? [];

                  if (posts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No posts yet.')),
                    );
                  }

                  final width = MediaQuery.of(context).size.width;

                  final crossAxisCount = width > 1400
                      ? 4
                      : width > 1000
                      ? 3
                      : width > 700
                      ? 2
                      : 1;

                  return MasonryGridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(posts[index]);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
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
}
