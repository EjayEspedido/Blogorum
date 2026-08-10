import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class ProfileService extends ChangeNotifier {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final _supabase = Supabase.instance.client;

  Profile? currentProfile;

  Future<void> loadCurrentProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    var profile = await _supabase
        .from('profiles')
        .select()
        .eq('uuid', user.id)
        .maybeSingle();

    if (profile == null) {
      await _supabase.from('profiles').insert({
        'uuid': user.id,
        'display_name': user.userMetadata?['display_name'] ?? 'New User',
        'email': user.email,
        'bio': '',
      });

      profile = await _supabase
          .from('profiles')
          .select()
          .eq('uuid', user.id)
          .single();
    }

    currentProfile = Profile.fromJson(profile);
    notifyListeners();
  }

  void clear() {
    currentProfile = null;
    notifyListeners();
  }
}

class Profile {
  final String displayName;
  final String email;
  final String bio;
  final String? avatarUrl;

  Profile({
    required this.displayName,
    required this.email,
    required this.bio,
    this.avatarUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      displayName: json['display_name'] ?? 'New User',
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}
