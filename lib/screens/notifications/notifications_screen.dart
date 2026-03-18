import 'package:flutter/material.dart';

import '../../services/notification_storage.dart';
import '../../widgets/notification_tile.dart';
import '../../widgets/app_header.dart';

class NotificationsScreen extends StatefulWidget {
  final String userRole;
  final String userEmail;
  final VoidCallback onGoToReservations;

  const NotificationsScreen({
    super.key,
    required this.userRole,
    required this.userEmail,
    required this.onGoToReservations,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  bool get _isAdmin => widget.userRole.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final notifications = _isAdmin
        ? await NotificationStorage.instance.getNotifications()
        : await NotificationStorage.instance.getNotificationsForUser(
            widget.userEmail,
          );

    if (!mounted) return;

    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _clearNotifications() async {
    await NotificationStorage.instance.clearNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        actions: _isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear all',
                  onPressed: _notifications.isEmpty
                      ? null
                      : _clearNotifications,
                ),
              ]
            : null,
      ),
      body: _isAdmin
          ? _buildAdminBody()
          : const Center(
              child: Text('Notifications are only available for admins.'),
            ),
    );
  }

  Widget _buildAdminBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return const Center(child: Text('No notifications yet.'));
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return InkWell(
            onTap: widget.onGoToReservations,
            child: NotificationTile(title: item.title, subtitle: item.subtitle),
          );
        },
      ),
    );
  }
}
