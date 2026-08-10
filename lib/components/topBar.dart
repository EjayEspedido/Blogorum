import 'package:flutter/material.dart';
import 'package:blogorum/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

final supabase = Supabase.instance.client;

class TopBar extends StatelessWidget {
  final ValueChanged<String> onSearch;

  const TopBar({
    super.key,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      hintText: 'Search posts or users...',
                      leading: const Icon(
                        Icons.search,
                        color: Color(0xFFF06D22),
                      ),
                      onSubmitted: (query) {
                        onSearch(query.trim());
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  if (supabase.auth.currentUser != null)
                    IconButton(
                      tooltip: 'Create post',
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xFFF06D22),
                      ),
                      onPressed: () {
                        context.go('/createPost');
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                const SizedBox(width: 8),

                IconButton(
                  tooltip: themeController.themeMode == ThemeMode.dark
                      ? 'Switch to light mode'
                      : 'Switch to dark mode',
                  onPressed: themeController.toggleTheme,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      themeController.themeMode == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      key: ValueKey(themeController.themeMode),
                      color: const Color(0xFFF06D22),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}