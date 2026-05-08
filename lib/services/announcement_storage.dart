import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class Announcement {
  final String? id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? imagePath; // Local path to image
  final String? gifUrl; // URL to GIF
  final String? emoji; // Emoji character
  final String? sticker; // Sticker identifier or path
  final String? postedByEmail;
  final String? postedByName;
  final String? postedByRole;

  Announcement({
    this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.imagePath,
    this.gifUrl,
    this.emoji,
    this.sticker,
    this.postedByEmail,
    this.postedByName,
    this.postedByRole,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'imagePath': imagePath,
    'gifUrl': gifUrl,
    'emoji': emoji,
    'sticker': sticker,
    if (postedByEmail != null) 'postedByEmail': postedByEmail,
    if (postedByName != null) 'postedByName': postedByName,
    if (postedByRole != null) 'postedByRole': postedByRole,
  };

  factory Announcement.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Announcement(
      id: docId,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      imagePath: json['imagePath'] as String?,
      gifUrl: json['gifUrl'] as String?,
      emoji: json['emoji'] as String?,
      sticker: json['sticker'] as String?,
      postedByEmail: json['postedByEmail'] as String?,
      postedByName: json['postedByName'] as String?,
      postedByRole: json['postedByRole'] as String?,
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

class AnnouncementStorage {
  AnnouncementStorage._();

  static final AnnouncementStorage instance = AnnouncementStorage._();

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance.collection('announcements');
  }

  bool get isReady => _collection != null;

  bool canModifyAnnouncement(
    Announcement announcement, {
    String? currentEmail,
    String? currentRole,
  }) {
    final normalizedRole = currentRole?.trim().toLowerCase() ?? '';
    final isManager =
        normalizedRole == 'admin' ||
        normalizedRole == 'librarian' ||
        normalizedRole == 'over all admin' ||
        normalizedRole == 'super admin';
    final normalizedEmail = currentEmail?.trim().toLowerCase() ?? '';
    final ownerEmail = announcement.postedByEmail?.trim().toLowerCase() ?? '';

    return isManager ||
        (normalizedEmail.isNotEmpty &&
            ownerEmail.isNotEmpty &&
            normalizedEmail == ownerEmail);
  }

  Future<List<Announcement>> getAnnouncements() async {
    if (_collection == null) return [];

    final snapshot = await _collection!
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));

    final list = snapshot.docs
        .map((doc) {
          try {
            return Announcement.fromJson({...doc.data()}, docId: doc.id);
          } catch (_) {
            return null;
          }
        })
        .whereType<Announcement>()
        .toList();

    return list;
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    if (_collection == null) {
      throw StateError('Firebase is not initialized for announcement writes.');
    }

    await _collection!.add({
      ...announcement.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    if (_collection == null) {
      throw StateError('Firebase is not initialized for announcement writes.');
    }
    if (announcement.id == null || announcement.id!.trim().isEmpty) {
      throw StateError('Announcement id is required for updates.');
    }

    await _collection!.doc(announcement.id).update({
      ...announcement.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    if (_collection == null) {
      throw StateError('Firebase is not initialized for announcement writes.');
    }
    await _collection!.doc(id).delete();
  }

  Future<void> clearAnnouncements() async {
    if (_collection == null) return;

    final snapshot = await _collection!.limit(500).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
