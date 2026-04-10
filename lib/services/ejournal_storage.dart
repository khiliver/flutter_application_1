import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class EJournalEntry {
  final String id;
  final String title;
  final String link;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EJournalEntry({
    required this.id,
    required this.title,
    required this.link,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'link': link,
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  factory EJournalEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return EJournalEntry(
      id: snapshot.id,
      title: (data['title'] ?? '').toString(),
      link: (data['link'] ?? '').toString(),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']),
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

class EJournalStorage {
  EJournalStorage._();

  static final EJournalStorage instance = EJournalStorage._();

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance
        .collection('app_settings')
        .doc('ejournal')
        .collection('entries');
  }

  bool get isReady => _collection != null;

  Future<List<EJournalEntry>> getEntries() async {
    if (_collection == null) return [];

    final snapshot = await _collection!
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));

    return snapshot.docs
        .map(EJournalEntry.fromSnapshot)
        .where((entry) => entry.title.isNotEmpty && entry.link.isNotEmpty)
        .toList();
  }

  Future<void> addEntry({required String title, required String link}) async {
    if (_collection == null) {
      throw StateError('Firebase is not initialized for e-journal writes.');
    }

    await _collection!.add({
      'title': title.trim(),
      'link': link.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateEntry({
    required String id,
    required String title,
    required String link,
  }) async {
    if (_collection == null) {
      throw StateError('Firebase is not initialized for e-journal writes.');
    }

    await _collection!.doc(id).set({
      'title': title.trim(),
      'link': link.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteEntry(String id) async {
    if (_collection == null) {
      throw StateError('Firebase is not initialized for e-journal writes.');
    }

    await _collection!.doc(id).delete();
  }

  Future<String?> getLink() async {
    final entries = await getEntries();
    if (entries.isEmpty) return null;
    return entries.first.link;
  }

  Future<void> setLink(String? link) async {
    if (link == null || link.trim().isEmpty) {
      final entries = await getEntries();
      if (entries.isEmpty) return;
      await deleteEntry(entries.first.id);
      return;
    }

    final entries = await getEntries();
    if (entries.isEmpty) {
      await addEntry(title: 'E-Journal', link: link);
      return;
    }

    await updateEntry(
      id: entries.first.id,
      title: entries.first.title,
      link: link,
    );
  }
}
