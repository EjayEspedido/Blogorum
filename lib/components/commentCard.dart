import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

final supabase = Supabase.instance.client;

class CommentCard extends StatefulWidget {
  final Map<String, dynamic> comment;
  final VoidCallback? onCommentUpdated;

  const CommentCard({super.key, required this.comment, this.onCommentUpdated});

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _controller;

  List<Map<String, dynamic>> _existingImages = [];
  List<Map<String, dynamic>> _imagesToDelete = [];
  List<PlatformFile> _newImages = [];

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.comment['body'] ?? '');

    _existingImages = List<Map<String, dynamic>>.from(
      widget.comment['comment_images'] ?? [],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;

      _controller.text = widget.comment['body'] ?? '';

      _existingImages = List<Map<String, dynamic>>.from(
        widget.comment['comment_images'] ?? [],
      );

      _imagesToDelete.clear();
      _newImages.clear();
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;

      _controller.text = widget.comment['body'] ?? '';

      _existingImages = List<Map<String, dynamic>>.from(
        widget.comment['comment_images'] ?? [],
      );

      _imagesToDelete.clear();
      _newImages.clear();
    });
  }

  Future<void> _pickImages() async {
    if (_isSaving) return;

    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );

    if (!mounted || result == null) return;

    setState(() {
      _newImages.addAll(result.files.where((file) => file.bytes != null));
    });
  }

  Future<void> _deleteComment() async {
    if (_isSaving) return;

    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete comment?'),
          content: const Text(
            'This comment and its images will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Get all images belonging to this comment.
      final images = await supabase
          .from('comment_images')
          .select('id, image_url')
          .eq('comment_id', widget.comment['id'])
          .eq('uuid', currentUser.id);

      // Delete image files from storage.
      for (final image in images) {
        final imageUrl = image['image_url'] as String?;

        if (imageUrl == null) continue;

        const marker = '/comment-images/';

        if (imageUrl.contains(marker)) {
          final fileName = Uri.decodeComponent(imageUrl.split(marker).last);

          await supabase.storage.from('comment-images').remove([fileName]);
        }
      }

      // Delete comment image records.
      await supabase
          .from('comment_images')
          .delete()
          .eq('comment_id', widget.comment['id'])
          .eq('uuid', currentUser.id);

      // Delete the comment itself.
      await supabase
          .from('comments')
          .delete()
          .eq('id', widget.comment['id'])
          .eq('uuid', currentUser.id);

      if (!mounted) return;

      widget.onCommentUpdated?.call();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete comment.\n$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteExistingImage(Map<String, dynamic> image) async {
    if (_isSaving) return;

    setState(() {
      _existingImages.remove(image);
      _imagesToDelete.add(image);
    });
  }

  Future<void> _saveComment() async {
    if (_isSaving) return;

    final body = _controller.text.trim();

    if (body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment cannot be empty.')));
      return;
    }

    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update the comment.
      await supabase
          .from('comments')
          .update({'body': body, 'isEdited': true})
          .eq('id', widget.comment['id'])
          .eq('uuid', currentUser.id);

      // Delete existing images that the user removed.
      for (final image in _imagesToDelete) {
        final imageUrl = image['image_url'] as String?;

        if (imageUrl != null) {
          const marker = '/comment-images/';

          if (imageUrl.contains(marker)) {
            final fileName = Uri.decodeComponent(imageUrl.split(marker).last);

            await supabase.storage.from('comment-images').remove([fileName]);
          }
        }

        await supabase.from('comment_images').delete().eq('id', image['id']);
      }

      // Upload newly added images.
      for (final image in _newImages) {
        final bytes = image.bytes;

        if (bytes == null) continue;

        final compressedImage = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 1280,
          minHeight: 1280,
          quality: 80,
          format: CompressFormat.jpeg,
        );

        final fileName =
            '${widget.comment['id']}_${DateTime.now().millisecondsSinceEpoch}_${image.name}.jpg';

        await supabase.storage
            .from('comment-images')
            .uploadBinary(fileName, compressedImage);

        final imageUrl = supabase.storage
            .from('comment-images')
            .getPublicUrl(fileName);

        await supabase.from('comment_images').insert({
          'comment_id': widget.comment['id'],
          'image_url': imageUrl,
          'uuid': currentUser.id,
        });
      }

      if (!mounted) return;

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _imagesToDelete.clear();
        _newImages.clear();
      });

      widget.onCommentUpdated?.call();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update comment.\n$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildExistingImage(Map<String, dynamic> image) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            image['image_url'],
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          ),
        ),

        if (_isEditing)
          Positioned(
            top: 3,
            right: 3,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isSaving ? null : () => _deleteExistingImage(image),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNewImage(PlatformFile image, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            image.bytes!,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 3,
          right: 3,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _newImages.removeAt(index);
                      });
                    },
              child: const SizedBox(
                width: 24,
                height: 24,
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalComment(
    BuildContext context,
    List<dynamic> images,
    String displayName,
    String? avatarUrl,
    bool isOwner,
    bool isEdited,
  ) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),

            title: Row(
              children: [
                Text(displayName),

                if (isEdited)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text(
                      '(edited)',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),

            subtitle: Text(widget.comment['body'] ?? ''),

            trailing: isOwner
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit),
                        onPressed: _startEditing,
                      ),

                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete),
                        onPressed: _deleteComment,
                      ),
                    ],
                  )
                : null,
          ),
        ),

        if (images.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 20, right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      images[index]['image_url'],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEditComment(
    BuildContext context,
    String displayName,
    String? avatarUrl,
  ) {
    final hasImages = _existingImages.isNotEmpty || _newImages.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),

                  const SizedBox(height: 6),

                  TextField(
                    controller: _controller,
                    enabled: !_isSaving,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Edit your comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (hasImages)
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _existingImages.length + _newImages.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index < _existingImages.length) {
                            return _buildExistingImage(_existingImages[index]);
                          }

                          final newIndex = index - _existingImages.length;

                          return _buildNewImage(_newImages[newIndex], newIndex);
                        },
                      ),
                    ),

                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Add images',
                        icon: const Icon(Icons.image),
                        onPressed: _isSaving ? null : _pickImages,
                      ),

                      const Spacer(),

                      TextButton(
                        onPressed: _isSaving ? null : _cancelEditing,
                        child: const Text('Cancel'),
                      ),

                      IconButton(
                        tooltip: 'Save',
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        onPressed: _isSaving ? null : _saveComment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.comment['comment_images'] as List<dynamic>? ?? [];

    final profile = widget.comment['profiles'] as Map<String, dynamic>?;

    final displayName = profile?['display_name'] as String? ?? 'Unknown User';

    final avatarUrl = profile?['avatar_url'] as String?;

    final currentUserId = supabase.auth.currentUser?.id;

    final isOwner = currentUserId == widget.comment['uuid'];

    final isEdited = widget.comment['isEdited'] == true;

    if (_isEditing) {
      return _buildEditComment(context, displayName, avatarUrl);
    }

    return _buildNormalComment(
      context,
      images,
      displayName,
      avatarUrl,
      isOwner,
      isEdited,
    );
  }
}
