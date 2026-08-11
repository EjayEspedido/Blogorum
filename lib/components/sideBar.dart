import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/settings/settingsAndProfile.dart';
import '../providers/auth.dart';
import '../providers/profiles.dart';
import '../theme/app_text_theme.dart';

class sideBar extends StatefulWidget {
  const sideBar({super.key});

  @override
  State<sideBar> createState() => _sideBarState();
}

class _sideBarState extends State<sideBar> {
  final _authService = AuthService();
  final _profileService = ProfileService.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!_authService.isLoggedIn) return;

    await _profileService.loadCurrentProfile();

    if (mounted) {
      setState(() {});
    }
  }

  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final boxShadows =
        Theme.of(context).extension<AppThemeExtension>()?.boxShadows ??
        AppTextTheme.lightBoxShadows;

    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        boxShadow: boxShadows,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              ListenableBuilder(
                listenable: _profileService,
                builder: (context, child) {
                  final profile = _profileService.currentProfile;

                  final hasAvatar =
                      profile?.avatarUrl != null &&
                      profile!.avatarUrl!.isNotEmpty;

                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (profile != null) {
                          _showProfileDialog();
                        } else {
                          context.go('/login');
                        }
                      },
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: hasAvatar
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: hasAvatar
                            ? null
                            : Text(
                                profile != null &&
                                        profile.displayName.isNotEmpty
                                    ? profile.displayName[0].toUpperCase()
                                    : 'G',
                              ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_authService.isLoggedIn)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home, color: Color(0xFFF06D22)),
                      onPressed: () {
                        context.go('/');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.person, color: Color(0xFFF06D22)),
                      onPressed: () {
                        context.go('/myProfile');
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.visibility_off,
                        color: Color(0xFFF06D22),
                      ),
                      onPressed: () {
                        context.go('/hiddenPosts');
                      },
                    ),
                  ],
                ),
            ],
          ),
          

          IconButton(
            icon: Icon(_authService.isLoggedIn ? Icons.logout : Icons.login),
            tooltip: _authService.isLoggedIn ? 'Logout' : 'Login',
            onPressed: () async {
              if (!_authService.isLoggedIn) {
                context.go('/login');
                return;
              }

              try {
                await _authService.signOut();

                _profileService.clear();

                if (mounted) {
                  setState(() {});
                }
              } catch (e) {
                debugPrint('Logout failed: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    final profile = _profileService.currentProfile;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SettingsAndProfile(user: profile?.displayName ?? 'Guest'),
        ),
      ),
    );
  }
}
