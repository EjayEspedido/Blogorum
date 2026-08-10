import 'package:flutter/material.dart';
import 'package:blogorum/components/sideBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

final supabase = Supabase.instance.client;

class EditPost extends StatefulWidget {
  final String postID;

  const EditPost({super.key, required this.postID});

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  // Existing images already stored in Supabase.
  List<Map<String, dynamic>> _existingImages = [];

  // Newly selected images that have not been uploaded yet.
  List<PlatformFile> _newImages = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }

    try {
      final post = await supabase
          .from('posts')
          .select('title, body, uuid')
          .eq('id', widget.postID)
          .eq('uuid', currentUser.id)
          .maybeSingle();

      if (post == null) {
        throw Exception('Post not found or you do not own this post.');
      }

      final images = await supabase
          .from('post_images')
          .select('id, image_url')
          .eq('post_id', widget.postID)
          .eq('uuid', currentUser.id);

      if (!mounted) return;

      setState(() {
        _titleController.text = post['title'] ?? '';
        _bodyController.text = post['body'] ?? '';

        _existingImages = List<Map<String, dynamic>>.from(images);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load post.\n$e'),
          backgroundColor: Colors.red,
        ),
      );

      context.pop();
    }
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

  Future<void> _deleteExistingImage(Map<String, dynamic> image) async {
    if (_isSaving) return;

    final imageUrl = image['image_url'] as String?;

    if (imageUrl == null) return;

    setState(() {
      _existingImages.remove(image);
    });

    try {
      // Extract the storage filename from the public URL.
      final marker = '/post-images/';

      if (imageUrl.contains(marker)) {
        final fileName = Uri.decodeComponent(imageUrl.split(marker).last);

        await supabase.storage.from('post-images').remove([fileName]);
      }

      await supabase
          .from('post_images')
          .delete()
          .eq('image_url', imageUrl)
          .eq('post_id', widget.postID);
    } catch (e) {
      if (!mounted) return;

      // Put the image back if deletion failed.
      setState(() {
        _existingImages.add(image);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove image.\n$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePost() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title.')));
      return;
    }

    if (body.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a body.')));
      return;
    }

    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      context.go('/login');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Update the post itself.
      await supabase
          .from('posts')
          .update({'title': title, 'body': body})
          .eq('id', widget.postID)
          .eq('uuid', currentUser.id);

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
            '${widget.postID}_${DateTime.now().millisecondsSinceEpoch}_${image.name.split('.').first}.jpg';

        await supabase.storage
            .from('post-images')
            .uploadBinary(fileName, compressedImage);

        final imageUrl = supabase.storage
            .from('post-images')
            .getPublicUrl(fileName);

        await supabase.from('post_images').insert({
          'post_id': widget.postID,
          'image_url': imageUrl,
          'uuid': currentUser.id,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated successfully!')),
      );

      context.go('posts/${widget.postID}');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update post.\n$e'),
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

  Widget _buildExistingImage(Map<String, dynamic> image, int index) {
    final imageUrl = image['image_url'] as String;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 120,
                height: 120,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image),
              );
            },
          ),
        ),

        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isSaving ? null : () => _deleteExistingImage(image),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(Icons.close, color: Colors.white, size: 18),
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
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 4,
          right: 4,
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
                width: 28,
                height: 28,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final hasImages = _existingImages.isNotEmpty || _newImages.isNotEmpty;

    return Scaffold(
      body: Container(
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
                    padding: const EdgeInsets.fromLTRB(12, 80, 12, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Post',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),

                        const SizedBox(height: 24),

                        if (hasImages)
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  _existingImages.length + _newImages.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                if (index < _existingImages.length) {
                                  return _buildExistingImage(
                                    _existingImages[index],
                                    index,
                                  );
                                }

                                final newIndex = index - _existingImages.length;

                                return _buildNewImage(
                                  _newImages[newIndex],
                                  newIndex,
                                );
                              },
                            ),
                          ),

                        if (hasImages) const SizedBox(height: 24),

                        TextField(
                          controller: _titleController,
                          enabled: !_isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _bodyController,
                          enabled: !_isSaving,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'Body',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            IconButton(
                              onPressed: _isSaving ? null : _pickImages,
                              icon: const Icon(Icons.image),
                              iconSize: 32,
                              tooltip: 'Add images',
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: FilledButton(
                                  onPressed: _isSaving ? null : _savePost,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Save Changes'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: 12,
                    left: 12,
                    child: Material(
                      color: Theme.of(context).colorScheme.primary,
                      shape: const CircleBorder(),
                      elevation: 6,
                      shadowColor: Theme.of(context).colorScheme.shadow,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isSaving
                            ? null
                            : () => context.go('posts/${widget.postID}'),
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
      ),
    );
  }
}
