import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

final supabase = Supabase.instance.client;
final user = supabase.auth.currentUser?.id;
bool _isSending = false;

class CreateComment extends StatefulWidget {
  final int postId;
  final VoidCallback? onCommentCreated;

  @override
  State<CreateComment> createState() => _CreateCommentState();

  const CreateComment({Key? key, required this.postId, this.onCommentCreated})
    : super(key: key);
}

class _CreateCommentState extends State<CreateComment> {
  final TextEditingController _controller = TextEditingController();
  List<PlatformFile> _images = [];

  @override
  void dispose() {
    _images.clear();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _images.addAll(result.files);
      });
    }
  }

  Future<void> _sendComment() async {
    if (_controller.text.trim().isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final comment = await supabase
          .from('comments')
          .insert({
            'body': _controller.text.trim(),
            'post_id': widget.postId,
            'uuid': user,
          })
          .select()
          .single();

      final commentId = comment['id'];

      for (final image in _images) {
        final compressedImage = await FlutterImageCompress.compressWithList(
          image.bytes!,
          minWidth: 1280,
          minHeight: 1280,
          quality: 80,
          format: CompressFormat.jpeg,
        );

        final fileName =
            "${commentId}_${DateTime.now().millisecondsSinceEpoch}_${image.name}.jpg";

        await supabase.storage
            .from('comment-images')
            .uploadBinary(fileName, compressedImage);

        final imageUrl = supabase.storage
            .from('comment-images')
            .getPublicUrl(fileName);

        await supabase.from('comment_images').insert({
          'comment_id': commentId,
          'image_url': imageUrl,
          'uuid': user,
        });
      }

      if (!mounted) return;

      _controller.clear();

      setState(() {
        _images.clear();
      });

      widget.onCommentCreated?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: supabase.auth.currentUser != null,
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: supabase.auth.currentUser != null
                          ? 'Write a comment...'
                          : 'Please log in to comment.',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: supabase.auth.currentUser != null
                      ? _pickImages
                      : null,
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: supabase.auth.currentUser != null && !_isSending
                      ? _sendComment
                      : null,
                ),
              ],
            ),
            if (_images.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _images[index].bytes!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IgnorePointer(
                              ignoring: _isSending,
                              child: GestureDetector(
                                onTap: _isSending
                                    ? null
                                    : () {
                                        setState(() {
                                          _images.removeAt(index);
                                        });
                                      },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
