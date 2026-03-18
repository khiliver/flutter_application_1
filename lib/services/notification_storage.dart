import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kNotificationsKey = 'risa_notifications_v1';

class AppNotification {
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final String? recipientEmail;

  AppNotification({
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.recipientEmail,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'createdAt': createdAt.toIso8601String(),
    if (recipientEmail != null) 'recipientEmail': recipientEmail,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      recipientEmail: json['recipientEmail'] as String?,
    );
  }
}

class NotificationStorage {
  NotificationStorage._();

  static final NotificationStorage instance = NotificationStorage._();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<AppNotification>> getNotifications() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_kNotificationsKey);
    if (raw == null) return [];
    final list = raw
        .map(
          (s) =>
              AppNotification.fromJson(jsonDecode(s) as Map<String, dynamic>),
        )
        .toList();
    // newest first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<AppNotification>> getNotificationsForUser(String email) async {
    final all = await getNotifications();
    return all
        .where((n) => n.recipientEmail?.toLowerCase() == email.toLowerCase())
        .toList();
  }

  Future<void> addNotification(AppNotification notification) async {
    final prefs = await _prefs;
    final notifications = await getNotifications();
    notifications.insert(0, notification);
    final values = notifications.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_kNotificationsKey, values);
  }

  Future<void> clearNotifications() async {
    final prefs = await _prefs;
    await prefs.remove(_kNotificationsKey);
  }
}
