import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reservation.dart';

const _kReservationsKey = 'risa_reservations_v1';

class ReservationStorage {
  ReservationStorage._();

  static final ReservationStorage instance = ReservationStorage._();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<ReservationItem>> getReservations() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_kReservationsKey);
    if (raw == null) return [];
    final list = raw
        .map(
          (s) =>
              ReservationItem.fromJson(jsonDecode(s) as Map<String, dynamic>),
        )
        .toList();
    // newest first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<ReservationItem>> getReservationsForUser(String email) async {
    final all = await getReservations();
    return all
        .where((r) => r.requesterEmail.toLowerCase() == email.toLowerCase())
        .toList();
  }

  Future<void> addReservation(ReservationItem reservation) async {
    final prefs = await _prefs;
    final reservations = await getReservations();
    reservations.insert(0, reservation);
    final values = reservations.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_kReservationsKey, values);
  }

  Future<void> updateReservation(ReservationItem reservation) async {
    final prefs = await _prefs;
    final reservations = await getReservations();
    final index = reservations.indexWhere((r) => r.id == reservation.id);
    if (index == -1) return;
    reservations[index] = reservation;
    final values = reservations.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_kReservationsKey, values);
  }

  Future<void> removeReservation(String id) async {
    final prefs = await _prefs;
    final reservations = await getReservations();
    reservations.removeWhere((r) => r.id == id);
    final values = reservations.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_kReservationsKey, values);
  }

  Future<void> clearReservations() async {
    final prefs = await _prefs;
    await prefs.remove(_kReservationsKey);
  }
}
