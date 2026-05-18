import 'package:flutter/material.dart';

import '../../models/reservation.dart';

/// Dialog to view reservation details.
class ReservationInfoDialog extends StatelessWidget {
  final ReservationItem reservation;
  final bool isAdmin;

  const ReservationInfoDialog({
    super.key,
    required this.reservation,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(reservation.type.label),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${reservation.title}'),
            if (reservation.library.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Library: ${reservation.library}'),
            ],
            if (reservation.service.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Service: ${reservation.service}'),
            ],
            if (reservation.type == ReservationType.scannedCopy) ...[
              const SizedBox(height: 8),
              if (reservation.service == 'Thesis/Dissertation' &&
                  reservation.thesisProgram.isNotEmpty) ...[
                Text('Program: ${reservation.thesisProgram}'),
                const SizedBox(height: 4),
                Text('Year: ${reservation.thesisYear}'),
              ] else if (reservation.service == 'Periodical') ...[
                Text('Periodical title: ${reservation.title}'),
                const SizedBox(height: 4),
                Text('Title of page: ${reservation.author}'),
              ] else if (reservation.service == 'Books' &&
                  reservation.publicationYear > 0) ...[
                Text('Year: ${reservation.publicationYear}'),
                const SizedBox(height: 4),
                Text(
                  'Pages: ${reservation.pageStart} - ${reservation.pageEnd} (${reservation.scannedCopyPageCount} pages)',
                ),
              ] else if (reservation.hasScannedCopyPages) ...[
                Text(
                  'Pages: ${reservation.pageStart} - ${reservation.pageEnd} (${reservation.scannedCopyPageCount} pages)',
                ),
              ],
            ],
            const SizedBox(height: 8),
            Text('Status: ${reservation.status.label}'),
            const SizedBox(height: 8),
            Text('Created: ${reservation.createdAt}'),
            if (reservation.reservationDate != null) ...[
              const SizedBox(height: 8),
              Text('Date reserved: ${reservation.reservationDate}'),
            ],
            if (reservation.firstName.isNotEmpty ||
                reservation.surname.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Name: ${reservation.firstName} ${reservation.middleName} ${reservation.surname}'
                    .trim(),
              ),
            ],
            if (reservation.schoolId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('School ID: ${reservation.schoolId}'),
            ],
            if (reservation.cellphone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Cellphone: ${reservation.cellphone}'),
            ],
            if (reservation.collegeName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('College: ${reservation.collegeName}'),
            ],
            if (reservation.schoolOrigin.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('From School: ${reservation.schoolOrigin}'),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 8),
              Text('Requested by: ${reservation.requesterName}'),
              const SizedBox(height: 4),
              Text('Email: ${reservation.requesterEmail}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
