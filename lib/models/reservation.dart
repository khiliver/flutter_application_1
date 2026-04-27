import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReservationType { seat, discussionRoom, book, scannedCopy }

extension ReservationTypeExt on ReservationType {
  String get label {
    switch (this) {
      case ReservationType.seat:
        return 'Seat';
      case ReservationType.discussionRoom:
        return 'Discussion Room';
      case ReservationType.book:
        return 'Book';
      case ReservationType.scannedCopy:
        return 'Scanned Copy';
    }
  }

  IconData get icon {
    switch (this) {
      case ReservationType.seat:
        return Icons.event_seat;
      case ReservationType.discussionRoom:
        return Icons.meeting_room;
      case ReservationType.book:
        return Icons.book;
      case ReservationType.scannedCopy:
        return Icons.document_scanner;
    }
  }
}

enum ReservationStatus { pending, done, cancelled }

extension ReservationStatusExt on ReservationStatus {
  String get label {
    switch (this) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.done:
        return 'Done';
      case ReservationStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class ReservationItem {
  final String id;
  final ReservationType type;
  String title;
  final DateTime createdAt;
  ReservationStatus status;

  // Personal info (students fill this when reserving)
  final String requesterEmail;
  final String requesterName;
  final String firstName;
  final String middleName;
  final String surname;
  final DateTime? reservationDate;
  final String schoolId;
  final String cellphone;
  final String college;
  final String schoolOrigin;
  final String library;
  final int pageStart;
  final int pageEnd;

  ReservationItem({
    String? id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.status = ReservationStatus.pending,
    required this.requesterEmail,
    required this.requesterName,
    this.firstName = '',
    this.middleName = '',
    this.surname = '',
    this.reservationDate,
    this.schoolId = '',
    this.cellphone = '',
    this.college = '',
    this.schoolOrigin = '',
    this.library = '',
    this.pageStart = 0,
    this.pageEnd = 0,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  bool get hasScannedCopyPages => pageStart > 0 && pageEnd > 0;

  int get scannedCopyPageCount {
    if (!hasScannedCopyPages) return 0;
    return pageEnd - pageStart + 1;
  }

  String get collegeName {
    final c = college.trim();
    if (c.isNotEmpty) return c;
    return schoolOrigin.trim();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'status': status.toString(),
    'requesterEmail': requesterEmail,
    'requesterName': requesterName,
    'firstName': firstName,
    'middleName': middleName,
    'surname': surname,
    'reservationDate': reservationDate?.toIso8601String(),
    'schoolId': schoolId,
    'cellphone': cellphone,
    'college': college,
    'schoolOrigin': schoolOrigin,
    'library': library,
    'pageStart': pageStart,
    'pageEnd': pageEnd,
  };

  factory ReservationItem.fromJson(Map<String, dynamic> json) {
    return ReservationItem(
      id: json['id'] as String?,
      type: ReservationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ReservationType.book,
      ),
      title: json['title'] as String,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      status: ReservationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ReservationStatus.pending,
      ),
      requesterEmail: json['requesterEmail'] as String? ?? '',
      requesterName: json['requesterName'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      reservationDate: _parseDateTime(json['reservationDate']),
      schoolId: json['schoolId'] as String? ?? '',
      cellphone: json['cellphone'] as String? ?? '',
      college:
          (json['college'] as String?) ??
          (json['schoolOrigin'] as String?) ??
          '',
      schoolOrigin: json['schoolOrigin'] as String? ?? '',
      library: json['library'] as String? ?? '',
      pageStart: json['pageStart'] as int? ?? 0,
      pageEnd: json['pageEnd'] as int? ?? 0,
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
