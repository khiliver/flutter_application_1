import 'package:flutter/material.dart';

enum ReservationType { seat, discussionRoom, book }

extension ReservationTypeExt on ReservationType {
  String get label {
    switch (this) {
      case ReservationType.seat:
        return 'Seat';
      case ReservationType.discussionRoom:
        return 'Discussion Room';
      case ReservationType.book:
        return 'Book';
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
  final String schoolOrigin;

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
    this.schoolOrigin = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

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
    'schoolOrigin': schoolOrigin,
  };

  factory ReservationItem.fromJson(Map<String, dynamic> json) {
    return ReservationItem(
      id: json['id'] as String?,
      type: ReservationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => ReservationType.book,
      ),
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: ReservationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ReservationStatus.pending,
      ),
      requesterEmail: json['requesterEmail'] as String? ?? '',
      requesterName: json['requesterName'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      reservationDate: json['reservationDate'] != null
          ? DateTime.parse(json['reservationDate'] as String)
          : null,
      schoolId: json['schoolId'] as String? ?? '',
      cellphone: json['cellphone'] as String? ?? '',
      schoolOrigin: json['schoolOrigin'] as String? ?? '',
    );
  }
}
