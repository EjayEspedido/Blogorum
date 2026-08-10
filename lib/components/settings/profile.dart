import 'package:blogorum/providers/profiles.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _profileService = ProfileService.instance;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    await _profileService.loadCurrentProfile();

    final profile = _profileService.currentProfile;

    if (profile != null) {
      _displayNameController.text = profile.displayName;
      _bioController.text = profile.bio;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    final userId = supabase.auth.currentUser?.id;

    if (_isLoading || userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await supabase
          .from('profiles')
          .update({
            'display_name': _displayNameController.text.trim(),
            'bio': _bioController.text.trim(),
          })
          .eq('uuid', userId);

      await _profileService.loadCurrentProfile();

      debugPrint('PROFILE UPDATED');
    } catch (e) {
      debugPrint('PROFILE UPDATE FAILED: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final userId = supabase.auth.currentUser?.id;

    if (_isLoading || userId == null) return;

    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.bytes == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final fileName =
          'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storagePath = '$userId/$fileName';

      await supabase.storage
          .from('profile-pictures')
          .uploadBinary(
            storagePath,
            file.bytes!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
            ),
          );

      debugPrint('IMAGE UPLOADED: $storagePath');

      final imageUrl = supabase.storage
          .from('profile-pictures')
          .getPublicUrl(storagePath);

      debugPrint('IMAGE URL: $imageUrl');

      await supabase
          .from('profiles')
          .update({
            'avatar_url': imageUrl,
          })
          .eq('uuid', userId);

      debugPrint('AVATAR URL SAVED');

      await _profileService.loadCurrentProfile();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('IMAGE UPLOAD FAILED: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profileService.currentProfile;

    if (profile == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final displayName = profile.displayName.trim().isEmpty
        ? 'New User'
        : profile.displayName;

    final hasAvatar =
        profile.avatarUrl != null &&
        profile.avatarUrl!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: hasAvatar
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: hasAvatar
                      ? null
                      : Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'Display name',
            style: Theme.of(context).textTheme.labelLarge,
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Your display name',
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Bio',
            style: Theme.of(context).textTheme.labelLarge,
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Tell people a little about yourself',
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isLoading ? null : _saveChanges,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}