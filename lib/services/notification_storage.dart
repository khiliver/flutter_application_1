import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AppNotification {
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final String? recipientEmail;
  final String? recipientRole;
  final String? recipientUserType;

  AppNotification({
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.recipientEmail,
    this.recipientRole,
    this.recipientUserType,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'createdAt': createdAt.toIso8601String(),
    if (recipientEmail != null) 'recipientEmail': recipientEmail,
    if (recipientRole != null) 'recipientRole': recipientRole,
    if (recipientUserType != null) 'recipientUserType': recipientUserType,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      recipientEmail: json['recipientEmail'] as String?,
      recipientRole: json['recipientRole'] as String?,
      recipientUserType: json['recipientUserType'] as String?,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

class NotificationStorage {
  NotificationStorage._();

  static final NotificationStorage instance = NotificationStorage._();

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance.collection('notifications');
  }

  bool get isReady => _collection != null;

  String _normalizeRoleToken(String role) {
    return role.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  }

  Future<List<AppNotification>> getNotifications() async {
    if (_collection == null) return [];

    final snapshot = await _collection!
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));

    final list = snapshot.docs
        .map((doc) {
          try {
            return AppNotification.fromJson({...doc.data()});
          } catch (_) {
            return null;
          }
        })
        .whereType<AppNotification>()
        .toList();

    return list;
  }

  Future<List<AppNotification>> getNotificationsForUser(String email) async {
    final all = await getNotifications();
    return all
        .where((n) => n.recipientEmail?.toLowerCase() == email.toLowerCase())
        .toList();
  }

  Future<List<AppNotification>> getNotificationsForAccount({
    required String role,
    required String email,
    String? userType,
  }) async {
    final all = await getNotifications();
    final normalizedRole = _normalizeRoleToken(role);
    final normalizedEmail = email.toLowerCase();
    final normalizedUserType = userType?.toLowerCase();

    return all.where((notification) {
      if (notification.recipientEmail != null) {
        return notification.recipientEmail!.toLowerCase() == normalizedEmail;
      }

      if (notification.recipientRole != null) {
        final roleMatches =
            _normalizeRoleToken(notification.recipientRole!) == normalizedRole;
        if (!roleMatches) return false;

        if (notification.recipientUserType == null) {
          return true;
        }

        return normalizedUserType != null &&
            notification.recipientUserType!.toLowerCase() == normalizedUserType;
      }

      // Global notifications (no recipient restrictions) shown to all users
      return true;
    }).toList();
  }

  Future<void> addAudienceNotification({
    required String title,
    required String subtitle,
    required String recipientRole,
    String? recipientUserType,
  }) async {
    await addNotification(
      AppNotification(
        title: title,
        subtitle: subtitle,
        createdAt: DateTime.now(),
        recipientRole: recipientRole,
        recipientUserType: recipientUserType,
      ),
    );
  }

  Future<void> addNotification(AppNotification notification) async {
    if (_collection == null) {
      throw StateError('Firebase is not initialized for notification writes.');
    }

    await _collection!.add({
      ...notification.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearNotifications() async {
    if (_collection == null) return;

    final snapshot = await _collection!.limit(500).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
