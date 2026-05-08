import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isRead;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.isRead = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isRead ? Colors.transparent : Colors.blue.shade50,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        leading: Icon(
          Icons.notifications,
          color: isRead ? Colors.grey : Colors.blue,
        ),
        onTap: onTap,
      ),
    );
  }
}
