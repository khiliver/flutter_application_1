import 'package:flutter/material.dart';

import '../../services/account_storage.dart';

class ReservationFormUserInfo {
  final String requesterEmail;
  final String requesterName;
  final String firstName;
  final String middleName;
  final String surname;
  final String schoolId;
  final String cellphone;
  final String college;
  final String schoolOrigin;

  const ReservationFormUserInfo({
    required this.requesterEmail,
    required this.requesterName,
    required this.firstName,
    required this.middleName,
    required this.surname,
    required this.schoolId,
    required this.cellphone,
    required this.college,
    required this.schoolOrigin,
  });

  factory ReservationFormUserInfo.fromAccount(
    Account? account, {
    String? fallbackEmail,
    String? fallbackName,
  }) {
    final email = (account?.email ?? fallbackEmail ?? '').trim();
    final fullName = _clean(account?.name ?? fallbackName ?? '');
    final parts = _splitName(
      account?.firstName,
      account?.middleName,
      account?.lastName,
      fullName,
    );

    return ReservationFormUserInfo(
      requesterEmail: email,
      requesterName: fullName.isNotEmpty ? fullName : email,
      firstName: parts.firstName,
      middleName: parts.middleName,
      surname: parts.lastName,
      schoolId: _clean(account?.schoolId),
      cellphone: _clean(account?.contactNumber),
      college: _clean(account?.college),
      schoolOrigin: _clean(account?.institutionOrSchool),
    );
  }
}

class _NameParts {
  final String firstName;
  final String middleName;
  final String lastName;

  const _NameParts({
    required this.firstName,
    required this.middleName,
    required this.lastName,
  });
}

_NameParts _splitName(
  String? firstName,
  String? middleName,
  String? lastName,
  String fallbackName,
) {
  final resolvedFirstName = _clean(firstName);
  final resolvedMiddleName = _clean(middleName);
  final resolvedLastName = _clean(lastName);
  if (resolvedFirstName.isNotEmpty ||
      resolvedMiddleName.isNotEmpty ||
      resolvedLastName.isNotEmpty) {
    return _NameParts(
      firstName: resolvedFirstName,
      middleName: resolvedMiddleName,
      lastName: resolvedLastName,
    );
  }

  final parts = fallbackName
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return const _NameParts(firstName: '', middleName: '', lastName: '');
  }
  if (parts.length == 1) {
    return _NameParts(firstName: parts.first, middleName: '', lastName: '');
  }
  if (parts.length == 2) {
    return _NameParts(
      firstName: parts.first,
      middleName: '',
      lastName: parts.last,
    );
  }
  return _NameParts(
    firstName: parts.first,
    middleName: parts.sublist(1, parts.length - 1).join(' '),
    lastName: parts.last,
  );
}

String _clean(String? value) {
  final text = value?.trim() ?? '';
  return text == 'null' ? '' : text;
}

DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String formatTimeOfDay(TimeOfDay? time) {
  if (time == null) return 'Choose time';
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
