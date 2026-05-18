import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReservationType { seat, discussionRoom, book, scannedCopy, collection }

extension ReservationTypeExt on ReservationType {
  String get label {
    switch (this) {
      case ReservationType.seat:
        return 'Seat';
      case ReservationType.discussionRoom:
        return 'Facility';
      case ReservationType.book:
        return 'Book';
      case ReservationType.scannedCopy:
        return 'Scanned Copy';
      case ReservationType.collection:
        return 'Collection';
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
      case ReservationType.collection:
        return Icons.library_books;
    }
  }
}

enum ReservationStatus { pending, accepted, declined, done, cancelled }

extension ReservationStatusExt on ReservationStatus {
  String get label {
    switch (this) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.accepted:
        return 'Accepted';
      case ReservationStatus.declined:
        return 'Declined';
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
  final String service;
  final String author;
  final int pageStart;
  final int pageEnd;
  final String thesisProgram;
  final int thesisYear;
  final int publicationYear;
  String adminMessage;
  DateTime? startTime;
  DateTime? endTime;

  // Collection request fields
  final String collectionName;
  final String collectionDescription;
  final String requestReason;
  final int desiredQuantity;

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
    this.service = '',
    this.author = '',
    this.pageStart = 0,
    this.pageEnd = 0,
    this.thesisProgram = '',
    this.thesisYear = 0,
    this.publicationYear = 0,
    this.adminMessage = '',
    this.startTime,
    this.endTime,
    this.collectionName = '',
    this.collectionDescription = '',
    this.requestReason = '',
    this.desiredQuantity = 0,
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
    'service': service,
    'author': author,
    'pageStart': pageStart,
    'pageEnd': pageEnd,
    'thesisProgram': thesisProgram,
    'thesisYear': thesisYear,
    'publicationYear': publicationYear,
    'adminMessage': adminMessage,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'collectionName': collectionName,
    'collectionDescription': collectionDescription,
    'requestReason': requestReason,
    'desiredQuantity': desiredQuantity,
  };

  factory ReservationItem.fromJson(Map<String, dynamic> json) {
    return ReservationItem(
      id: _stringValue(json['id']),
      type: ReservationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ReservationType.book,
      ),
      title: _stringValue(json['title'], fallback: 'Reservation'),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      status: ReservationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ReservationStatus.pending,
      ),
      requesterEmail: _stringValue(json['requesterEmail']),
      requesterName: _stringValue(json['requesterName']),
      firstName: _stringValue(json['firstName']),
      middleName: _stringValue(json['middleName']),
      surname: _stringValue(json['surname']),
      reservationDate: _parseDateTime(json['reservationDate']),
      schoolId: _stringValue(json['schoolId']),
      cellphone: _stringValue(json['cellphone']),
      college: _stringValue(
        json['college'],
        fallback: _stringValue(json['schoolOrigin']),
      ),
      schoolOrigin: _stringValue(json['schoolOrigin']),
      library: _stringValue(json['library']),
      service: _stringValue(json['service']),
      author: _stringValue(json['author']),
      pageStart: _intValue(json['pageStart']),
      pageEnd: _intValue(json['pageEnd']),
      thesisProgram: _stringValue(json['thesisProgram']),
      thesisYear: _intValue(json['thesisYear']),
      publicationYear: _intValue(json['publicationYear']),
      adminMessage: _stringValue(json['adminMessage']),
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      collectionName: _stringValue(json['collectionName']),
      collectionDescription: _stringValue(json['collectionDescription']),
      requestReason: _stringValue(json['requestReason']),
      desiredQuantity: _intValue(json['desiredQuantity']),
    );
  }

  static String _stringValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return fallback;
    return text;
  }

  static int _intValue(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
