import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/notification_storage.dart';
import '../../widgets/notification_tile.dart';
import '../../widgets/app_header.dart';

class NotificationsScreen extends StatefulWidget {
  final String userRole;
  final String userEmail;
  final String? userType;
  final VoidCallback onGoToReservations;

  const NotificationsScreen({
    super.key,
    required this.userRole,
    required this.userEmail,
    this.userType,
    required this.onGoToReservations,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _kLastSeenPopupPrefix = 'last_seen_notification_popup_v1_';

  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  String get _lastSeenPopupKey =>
      '$_kLastSeenPopupPrefix${widget.userEmail.trim().toLowerCase()}';

  String _normalizeRoleToken(String role) {
    return role.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  }

  String _notificationFingerprint(AppNotification notification) {
    return '${notification.createdAt.toIso8601String()}|${notification.title}|${notification.subtitle}';
  }

  Future<String?> _getLastSeenPopupFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSeenPopupKey);
  }

  Future<void> _setLastSeenPopupFingerprint(String fingerprint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenPopupKey, fingerprint);
  }

  bool get _isManager {
    final role = _normalizeRoleToken(widget.userRole);
    return role == 'admin' ||
        role == 'librarian' ||
        role == 'overalladmin' ||
        role == 'superadmin';
  }

  bool get _isAdminLike {
    final role = _normalizeRoleToken(widget.userRole);
    return role == 'admin' || role == 'overalladmin' || role == 'superadmin';
  }

  bool _isUserVisibleNotification(AppNotification notification) {
    final normalizedTitle = notification.title.trim().toLowerCase();
    return normalizedTitle != 'new user registered';
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final fetchedNotifications = _isAdminLike
        ? await NotificationStorage.instance.getNotifications()
        : await NotificationStorage.instance.getNotificationsForAccount(
            role: widget.userRole,
            email: widget.userEmail,
            userType: widget.userType,
          );

    final notifications = _isManager
        ? fetchedNotifications
        : fetchedNotifications.where(_isUserVisibleNotification).toList();

    if (!mounted) return;

    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });

    if (!_isManager && notifications.isNotEmpty) {
      final latest = notifications.first;
      final latestFingerprint = _notificationFingerprint(latest);
      final seenFingerprint = await _getLastSeenPopupFingerprint();
      if (seenFingerprint == latestFingerprint) {
        return;
      }

      await _setLastSeenPopupFingerprint(latestFingerprint);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showPopup(latest);
      });
    }
  }

  Future<void> _showPopup(AppNotification notification) async {
    SystemSound.play(SystemSoundType.alert);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New notification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.title),
              const SizedBox(height: 8),
              Text(notification.subtitle),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
        actions: _isManager
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
      body: _isManager ? _buildManagerBody() : _buildUserBody(),
    );
  }

  Widget _buildManagerBody() {
    return _buildRefreshableNotificationsBody(
      onItemTap: widget.onGoToReservations,
    );
  }

  Widget _buildUserBody() {
    return _buildRefreshableNotificationsBody();
  }

  Widget _buildRefreshableNotificationsBody({VoidCallback? onItemTap}) {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: _buildNotificationsList(onItemTap: onItemTap),
    );
  }

  Widget _buildNotificationsList({VoidCallback? onItemTap}) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: Text('No notifications yet.')),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final item = _notifications[index];
        final tile = NotificationTile(
          title: item.title,
          subtitle: item.subtitle,
        );
        if (onItemTap == null) {
          return tile;
        }
        return InkWell(onTap: onItemTap, child: tile);
      },
    );
  }
}
