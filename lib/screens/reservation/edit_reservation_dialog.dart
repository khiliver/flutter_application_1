import 'package:flutter/material.dart';

import '../../models/reservation.dart';

/// Dialog to edit a reservation's title and status.
class EditReservationDialog extends StatefulWidget {
  final ReservationItem reservation;

  const EditReservationDialog({super.key, required this.reservation});

  @override
  State<EditReservationDialog> createState() => _EditReservationDialogState();
}

class _EditReservationDialogState extends State<EditReservationDialog> {
  late TextEditingController _titleController;
  late ReservationStatus _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reservation.title);
    _status = widget.reservation.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.reservation.type.label} reservation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText:
                  widget.reservation.type == ReservationType.book ||
                      widget.reservation.type == ReservationType.scannedCopy
                  ? 'Book title'
                  : 'Name',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReservationStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: ReservationStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (s) {
              if (s != null) {
                setState(() {
                  _status = s;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedTitle = _titleController.text.trim();
            if (updatedTitle.isEmpty) return;
            Navigator.of(context).pop(
              ReservationItem(
                id: widget.reservation.id,
                type: widget.reservation.type,
                title: updatedTitle,
                createdAt: widget.reservation.createdAt,
                status: _status,
                requesterEmail: widget.reservation.requesterEmail,
                requesterName: widget.reservation.requesterName,
                firstName: widget.reservation.firstName,
                middleName: widget.reservation.middleName,
                surname: widget.reservation.surname,
                reservationDate: widget.reservation.reservationDate,
                schoolId: widget.reservation.schoolId,
                cellphone: widget.reservation.cellphone,
                college: widget.reservation.college,
                schoolOrigin: widget.reservation.schoolOrigin,
                library: widget.reservation.library,
                pageStart: widget.reservation.pageStart,
                pageEnd: widget.reservation.pageEnd,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
