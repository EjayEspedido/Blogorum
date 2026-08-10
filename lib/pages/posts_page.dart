import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blogorum/components/image_carouselsBig.dart';
import 'package:blogorum/functions/getCurrentPost.dart';
import 'package:go_router/go_router.dart';

import '../functions/dateFormats.dart' as dateFormats;
import '../components/sideBar.dart';
import '../components/commentList.dart';

final supabase = Supabase.instance.client;
final user = supabase.auth.currentUser?.email ?? 'Guest';
final uuid = supabase.auth.currentUser?.id;

class PostPage extends StatefulWidget {
  final String postID;

  const PostPage({super.key, required this.postID});

  @override
  State<PostPage> createState() => PostPageState();
}

class PostPageState extends State<PostPage> {
  Future<void> _deletePost(Map<String, dynamic> post) async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete post?'),
          content: const Text(
            'This post and its images will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Get the post images first.
      final images = await supabase
          .from('post_images')
          .select('id, image_url')
          .eq('post_id', post['id'])
          .eq('uuid', currentUser.id);

      // Delete the actual files from storage.
      for (final image in images) {
        final imageUrl = image['image_url'] as String?;

        if (imageUrl == null) continue;

        const marker = '/post-images/';

        if (imageUrl.contains(marker)) {
          final fileName = Uri.decodeComponent(imageUrl.split(marker).last);

          await supabase.storage.from('post-images').remove([fileName]);
        }
      }

      // Delete post image records.
      await supabase
          .from('post_images')
          .delete()
          .eq('post_id', post['id'])
          .eq('uuid', currentUser.id);

      // Delete the post itself.
      await supabase
          .from('posts')
          .delete()
          .eq('id', post['id'])
          .eq('uuid', currentUser.id);

      if (!mounted) return;

      context.go('/');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post.\n$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getCurrentPost(widget.postID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load post.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Post not found.'));
        }

        final post = snapshot.data!;

        final images = (post['post_images'] as List? ?? [])
            .map((e) => e['image_url'] as String)
            .toList();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sideBar(),

              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 24.0),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            child: images.isNotEmpty
                                ? PostCarouselLarge(images: images)
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 16.0),

                          // Post information
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post['title'] ?? 'Untitled',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),

                                const SizedBox(height: 8.0),

                                Text(
                                  post['body'] ?? '',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),

                                const SizedBox(height: 12.0),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'by ${post['profiles']?['display_name'] ?? 'Unknown'}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    if (uuid == post['uuid'])
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_horiz,
                                          size: 25,
                                        ),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            context.go(
                                              '/editPost/${post['id']}',
                                            );
                                          }

                                          if (value == 'delete') {
                                            _deletePost(post);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit),
                                                SizedBox(width: 10),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),

                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete),
                                                SizedBox(width: 10),
                                                Text('Delete'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 4.0),

                                Text(
                                  dateFormats.formatYMd(
                                    DateTime.parse(post['created_at']),
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16.0),

                          const Divider(),

                          // Comments
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CommentList(postId: post['id']),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      top: 24,
                      left: 24,
                      child: Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        elevation: 6,
                        shadowColor: Theme.of(context).colorScheme.shadow,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.go('/'),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.arrow_back,
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
      },
    );
  }
}
