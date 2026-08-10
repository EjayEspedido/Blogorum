import 'package:flutter/material.dart';

class Security extends StatelessWidget {
  final String user;

  const Security({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16.0),
        Text('User: $user'),
        // Add more security details here
      ],
    );
  }
}