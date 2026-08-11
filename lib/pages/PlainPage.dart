import 'package:flutter/material.dart';
import 'package:blogorum/components/sideBar.dart';
import 'package:blogorum/components/topBar.dart';
import 'package:blogorum/components/hiddenPosts.dart';
import 'package:blogorum/components/profile.dart';

class PlainPage extends StatelessWidget {
  final String page;
  final String? userId;

  const PlainPage({
    super.key,
    required this.page,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      child: Row(
        children: [
          sideBar(),

          Expanded(
            child: Column(
              children: [
                TopBar(onSearch: (_) {}),

                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: switch (page) {
                      'Profile' => Profile(userId: userId),
                      'My Profile' => const Profile(),
                      'Hidden Posts' => const HiddenPage(),
                      _ => const Profile(),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}