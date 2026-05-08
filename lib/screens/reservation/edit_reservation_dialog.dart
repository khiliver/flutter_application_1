import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/reservation.dart';
import 'reservation_form_user_info.dart';

/// Dialog to edit a full reservation record.
class EditReservationDialog extends StatefulWidget {
  final ReservationItem reservation;

  const EditReservationDialog({super.key, required this.reservation});

  @override
  State<EditReservationDialog> createState() => _EditReservationDialogState();
}

class _EditReservationDialogState extends State<EditReservationDialog> {
  late TextEditingController _titleController;
  late TextEditingController _pageStartController;
  late TextEditingController _pageEndController;
  late ReservationStatus _status;
  late String _selectedLibrary;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool get _isScannedCopy =>
      widget.reservation.type == ReservationType.scannedCopy;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reservation.title);
    _pageStartController = TextEditingController(
      text: widget.reservation.pageStart > 0
          ? widget.reservation.pageStart.toString()
          : '',
    );
    _pageEndController = TextEditingController(
      text: widget.reservation.pageEnd > 0
          ? widget.reservation.pageEnd.toString()
          : '',
    );
    _status = widget.reservation.status;

    final library = widget.reservation.library.trim();
    _selectedLibrary = kLibraryOptions.contains(library)
        ? library
        : kLibraryOptions.first;

    final reservationDate = widget.reservation.reservationDate;
    if (reservationDate != null) {
      _selectedDate = DateTime(
        reservationDate.year,
        reservationDate.month,
        reservationDate.day,
      );
      _selectedTime = TimeOfDay(
        hour: reservationDate.hour,
        minute: reservationDate.minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageStartController.dispose();
    _pageEndController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? widget.reservation.createdAt,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked == null) return;

    setState(() {
      _selectedTime = picked;
    });
  }

  void _save() {
    final updatedTitle = _titleController.text.trim();
    if (updatedTitle.isEmpty) return;

    final hasPickedDateAndTime = _selectedDate != null && _selectedTime != null;
    final updatedReservationDate = hasPickedDateAndTime
        ? combineDateAndTime(_selectedDate!, _selectedTime!)
        : widget.reservation.reservationDate;
    final updatedStartTime = hasPickedDateAndTime
        ? updatedReservationDate
        : widget.reservation.startTime;
    final updatedEndTime = hasPickedDateAndTime
        ? updatedStartTime?.add(const Duration(hours: 2))
        : widget.reservation.endTime;

    int updatedPageStart = widget.reservation.pageStart;
    int updatedPageEnd = widget.reservation.pageEnd;
    if (_isScannedCopy) {
      final pageStart = int.tryParse(_pageStartController.text.trim());
      final pageEnd = int.tryParse(_pageEndController.text.trim());
      if (pageStart == null || pageEnd == null) return;
      if (pageStart <= 0 || pageEnd <= 0 || pageEnd < pageStart) return;
      if (pageEnd - pageStart + 1 > 20) return;
      updatedPageStart = pageStart;
      updatedPageEnd = pageEnd;
    }

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
        reservationDate: updatedReservationDate,
        schoolId: widget.reservation.schoolId,
        cellphone: widget.reservation.cellphone,
        college: widget.reservation.college,
        schoolOrigin: widget.reservation.schoolOrigin,
        library: _selectedLibrary,
        service: widget.reservation.service,
        pageStart: updatedPageStart,
        pageEnd: updatedPageEnd,
        adminMessage: widget.reservation.adminMessage,
        startTime: updatedStartTime,
        endTime: updatedEndTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.reservation.type.label} reservation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText:
                    widget.reservation.type == ReservationType.book ||
                        widget.reservation.type == ReservationType.scannedCopy
                    ? 'Book title'
                    : 'Reservation title',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedLibrary,
              decoration: const InputDecoration(labelText: 'Library'),
              items: kLibraryOptions
                  .map(
                    (library) =>
                        DropdownMenuItem(value: library, child: Text(library)),
                  )
                  .toList(),
              onChanged: (library) {
                if (library == null) return;
                setState(() {
                  _selectedLibrary = library;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${_selectedDate == null ? 'Not set' : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'}',
                  ),
                ),
                TextButton(onPressed: _pickDate, child: const Text('Pick')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Time: ${formatTimeOfDay(_selectedTime)}'),
                ),
                TextButton(onPressed: _pickTime, child: const Text('Pick')),
              ],
            ),
            if (_isScannedCopy) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _pageStartController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Page start'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pageEndController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Page end'),
              ),
            ],
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
