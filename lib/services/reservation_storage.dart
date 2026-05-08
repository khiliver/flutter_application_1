import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/reservation.dart';

class ReservationStorage {
  ReservationStorage._();

  static final ReservationStorage instance = ReservationStorage._();

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance.collection('request list');
  }

  bool get isReady => _collection != null;

  Map<String, dynamic> _toFirestore(ReservationItem reservation) =>
      reservation.toJson()..['updatedAt'] = FieldValue.serverTimestamp();

  ReservationItem? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      if (data == null) return null;
      data['id'] = doc.id;
      return ReservationItem.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<ReservationItem>> getReservations() async {
    if (_collection == null) return [];

    final snapshot = await _collection!
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));

    final items = snapshot.docs
        .map(_fromDoc)
        .whereType<ReservationItem>()
        .toList();
    return items;
  }

  Future<List<ReservationItem>> getReservationsForUser(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final all = await getReservations();
    return all
        .where((r) => r.requesterEmail.toLowerCase() == normalizedEmail)
        .toList();
  }

  Future<void> addReservation(ReservationItem reservation) async {
    if (_collection == null) {
      throw StateError('Firebase is not initialized for reservation writes.');
    }

    await _collection!.doc(reservation.id).set({
      ..._toFirestore(reservation),
      'createdAt': reservation.createdAt,
    });
  }

  Future<void> updateReservation(ReservationItem reservation) async {
    if (_collection == null) {
      throw StateError('Firebase is not initialized for reservation writes.');
    }

    await _collection!.doc(reservation.id).set(_toFirestore(reservation));
  }

  Future<void> removeReservation(String id) async {
    if (_collection == null) {
      throw StateError('Firebase is not initialized for reservation writes.');
    }

    await _collection!.doc(id).delete();
  }

  Future<void> clearReservations() async {
    if (_collection == null) return;

    final snapshot = await _collection!.limit(500).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
