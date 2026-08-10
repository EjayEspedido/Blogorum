import 'package:flutter/material.dart';
import 'package:blogorum/components/commentCard.dart';
import 'package:blogorum/functions/getComments.dart';
import 'package:blogorum/components/create_comment.dart';

class CommentList extends StatefulWidget {
  final int postId;

  const CommentList({super.key, required this.postId});

  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  late Future<List<Map<String, dynamic>>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = getComments(widget.postId);
  }

  void _refreshComments() {
    setState(() {
      _commentsFuture = getComments(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CreateComment(
          postId: widget.postId,
          onCommentCreated: _refreshComments,
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _commentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print(snapshot.error);
              return Text(snapshot.error.toString());
            }

            final comments = snapshot.data ?? [];

            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No comments yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return CommentCard(
                  comment: comments[index],
                  onCommentUpdated: _refreshComments,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
