import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  final String user;

  const Settings({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
        Text('User: $user'),
        // Add more settings details here
      ],
    );
  }
}