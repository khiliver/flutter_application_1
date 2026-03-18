import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const NotificationTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      leading: const Icon(Icons.notifications),
    );
  }
}
