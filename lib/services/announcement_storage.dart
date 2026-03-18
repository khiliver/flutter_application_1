import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kAnnouncementsKey = 'risa_announcements_v1';

class Announcement {
  final String title;
  final String body;
  final DateTime createdAt;
  final String? imagePath; // Local path to image
  final String? gifUrl; // URL to GIF
  final String? emoji; // Emoji character
  final String? sticker; // Sticker identifier or path

  Announcement({
    required this.title,
    required this.body,
    required this.createdAt,
    this.imagePath,
    this.gifUrl,
    this.emoji,
    this.sticker,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'imagePath': imagePath,
    'gifUrl': gifUrl,
    'emoji': emoji,
    'sticker': sticker,
  };

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imagePath: json['imagePath'] as String?,
      gifUrl: json['gifUrl'] as String?,
      emoji: json['emoji'] as String?,
      sticker: json['sticker'] as String?,
    );
  }
}

class AnnouncementStorage {
  AnnouncementStorage._();

  static final AnnouncementStorage instance = AnnouncementStorage._();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<Announcement>> getAnnouncements() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_kAnnouncementsKey);
    if (raw == null) return [];
    final list = raw
        .map(
          (s) => Announcement.fromJson(jsonDecode(s) as Map<String, dynamic>),
        )
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    final prefs = await _prefs;
    final announcements = await getAnnouncements();
    announcements.insert(0, announcement);
    final values = announcements.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_kAnnouncementsKey, values);
  }

  Future<void> clearAnnouncements() async {
    final prefs = await _prefs;
    await prefs.remove(_kAnnouncementsKey);
  }
}
