import 'package:flutter/material.dart';
import '../../theme/app_text_theme.dart';
import 'profile.dart';
import 'settings.dart';
import 'security.dart';

class SettingsAndProfile extends StatefulWidget {
  final String user;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  const SettingsAndProfile({
    super.key,
    required this.user,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  @override
  State<SettingsAndProfile> createState() => _SettingsAndProfileState();
}

class _SettingsAndProfileState extends State<SettingsAndProfile> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant SettingsAndProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
  }

  Widget _buildSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return const Profile();
      // case 1:
      //   return Settings(user: widget.user);
      // case 2:
      //   return Security(user: widget.user);
      default:
        return const Profile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxShadows =
        Theme.of(context).extension<AppThemeExtension>()?.boxShadows ??
        AppTextTheme.lightBoxShadows;

    return Container(
      width: 900,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        boxShadow: boxShadows,
      ),
      child: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
              widget.onDestinationSelected?.call(index);
            },
            backgroundColor: const Color.fromARGB(26, 63, 55, 55),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
              // NavigationRailDestination(
              //   icon: Icon(Icons.settings_outlined),
              //   selectedIcon: Icon(Icons.settings),
              //   label: Text('Preferences'),
              // ),
              // NavigationRailDestination(
              //   icon: Icon(Icons.security_outlined),
              //   selectedIcon: Icon(Icons.security),
              //   label: Text('Security'),
              // ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSelectedPage(),
            ),
          ),
        ],
      ),
    );
  }
}
