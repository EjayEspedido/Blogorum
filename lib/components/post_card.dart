import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_date_formatter/flutter_date_formatter.dart';
import 'package:blogorum/components/image_carousels.dart';

import 'package:go_router/go_router.dart';

final supabase = Supabase.instance.client;
final user = supabase.auth.currentUser?.email ?? 'Guest';
final isLoggedIn = supabase.auth.currentUser != null;

class PostCard extends StatefulWidget {
  final String title;
  final String body;
  final List<String> images;
  final DateTime createdAt;
  final String author;
  final int comments;
  final int postID;

  const PostCard({
    super.key,
    required this.title,
    required this.body,
    required this.images,
    required this.createdAt,
    this.author = 'Unknown',
    this.comments = 0,
    required this.postID,
  });

  @override
  PostCardState createState() => PostCardState();
}

class PostCardState extends State<PostCard> {
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    final currentUser = supabase.auth.currentUser;

    final likes = await supabase
        .from('post_likes')
        .select('user_id')
        .eq('post_id', widget.postID);

    if (!mounted) return;

    setState(() {
      _likeCount = likes.length;

      if (currentUser != null) {
        _isLiked = likes.any((like) => like['user_id'] == currentUser.id);
      }
    });
  }

  Future<void> _toggleLike() async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) return;

    if (_isLiked) {
      await supabase
          .from('post_likes')
          .delete()
          .eq('post_id', widget.postID)
          .eq('user_id', currentUser.id);

      if (!mounted) return;

      setState(() {
        _isLiked = false;
        if (_likeCount > 0) {
          _likeCount--;
        }
      });
    } else {
      await supabase.from('post_likes').insert({
        'post_id': widget.postID,
        'user_id': currentUser.id,
      });

      if (!mounted) return;

      setState(() {
        _isLiked = true;
        _likeCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedRelativeDate = FlutterDateFormatter.formatRelativeDateTime(
      widget.createdAt,
      locale: 'en',
    );

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.images.isNotEmpty) PostCarousel(images: widget.images),

            const SizedBox(height: 8),

            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 6),

            Text(
              widget.body,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            Text(
              'by ${widget.author}. Created $formattedRelativeDate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                IconButton(
                  tooltip: isLoggedIn
                      ? (_isLiked ? 'Unlike' : 'Like')
                      : 'Log in to like',
                  icon: Icon(
                    _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  ),
                  color: _isLiked
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  onPressed: isLoggedIn ? _toggleLike : null,
                ),

                Text('$_likeCount'),
                IconButton(
                  tooltip: 'Comments',
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    context.push('/posts/${widget.postID}');
                  },
                ),

                Text('${widget.comments}'),

                const Spacer(),

                TextButton(
                  onPressed: () {
                    context.push('/posts/${widget.postID}');
                  },
                  child: const Text('Read More'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
