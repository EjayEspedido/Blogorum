import 'package:flutter/material.dart';
import 'package:blogorum/components/sideBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

final supabase = Supabase.instance.client;
final user = supabase.auth.currentUser?.id;

class CreatePost extends StatefulWidget {
  const CreatePost({super.key});

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  List<PlatformFile> _images = [];
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isSending) return;

    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );

    if (!mounted || result == null) return;

    setState(() {
      _images.addAll(result.files.where((file) => file.bytes != null));
    });
  }

  Future<void> _createPost() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final post = await supabase
          .from('posts')
          .insert({
            'title': _titleController.text.trim(),
            'body': _bodyController.text.trim(),
            'uuid': user,
          })
          .select()
          .single();

      final postId = post['id'];

      for (final image in _images) {
        final bytes = image.bytes;

        if (bytes == null) {
          continue;
        }

        final compressedImage = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 1280,
          minHeight: 1280,
          quality: 80,
          format: CompressFormat.jpeg,
        );

        final fileName =
            '${postId}_${DateTime.now().millisecondsSinceEpoch}_${image.name.split('.').first}.jpg';

        await supabase.storage
            .from('post-images')
            .uploadBinary(fileName, compressedImage);

        final imageUrl = supabase.storage
            .from('post-images')
            .getPublicUrl(fileName);

        await supabase.from('post_images').insert({
          'post_id': postId,
          'image_url': imageUrl,
          'uuid': user,
        });
      }

      if (!mounted) return;

      _titleController.clear();
      _bodyController.clear();

      setState(() {
        _images.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post created successfully!")),
      );

      context.go('/');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _submitPost() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a title.")));
      return;
    }

    if (_bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a body.")));
      return;
    }

    try {
      await _createPost();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to create post.\n$e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          "Create Post",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),

                        const SizedBox(height: 24),

                        if (_images.isNotEmpty)
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final image = _images[index];

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
                                          onTap: _isSending
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _images.removeAt(index);
                                                  });
                                                },
                                          child: const SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                        if (_images.isNotEmpty) const SizedBox(height: 24),

                        TextField(
                          controller: _titleController,
                          enabled: !_isSending,
                          decoration: const InputDecoration(
                            labelText: "Title",
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _bodyController,
                          enabled: !_isSending,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: "Body",
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            IconButton(
                              onPressed: _isSending ? null : _pickImages,
                              icon: const Icon(Icons.image),
                              iconSize: 32,
                              tooltip: "Add images",
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: FilledButton(
                                  onPressed: _isSending ? null : _submitPost,
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: _isSending
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text("Post"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Floating back button.
                  // It stays within the Create Post page
                  // instead of being part of the scrolling content.
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      elevation: 6,
                      shadowColor: Colors.black54,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.go('/'),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
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
