import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/reservation.dart';
import '../../services/account_storage.dart';
import 'reservation_form_user_info.dart';

/// Form for students to reserve a seat.
/// Collects: name, date, school ID, cellphone, college, from school.
class SeatReservationForm extends StatefulWidget {
  final String? userEmail;
  final String? userName;
  final String? selectedLibrary;
  final Account? userAccount;

  const SeatReservationForm({
    super.key,
    this.userEmail,
    this.userName,
    this.selectedLibrary,
    this.userAccount,
  });

  @override
  State<SeatReservationForm> createState() => _SeatReservationFormState();
}

class _SeatReservationFormState extends State<SeatReservationForm> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? errorText;
  final formKey = GlobalKey<ShadFormState>();

  String formatDate(DateTime? date) {
    if (date == null) return 'Choose date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        errorText = null;
      });
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (selectedDate == null || selectedTime == null) {
      setState(() {
        errorText = 'Please choose both date and time.';
      });
      return;
    }

    final userInfo = ReservationFormUserInfo.fromAccount(
      widget.userAccount,
      fallbackEmail: widget.userEmail,
      fallbackName: widget.userName,
    );
    final slotStart = combineDateAndTime(selectedDate!, selectedTime!);
    final slotEnd = slotStart.add(const Duration(hours: 2));

    Navigator.of(context).pop(
      ReservationItem(
        type: ReservationType.seat,
        title: ReservationType.seat.label,
        createdAt: DateTime.now(),
        requesterEmail: userInfo.requesterEmail,
        requesterName: userInfo.requesterName,
        firstName: userInfo.firstName,
        middleName: userInfo.middleName,
        surname: userInfo.surname,
        reservationDate: slotStart,
        schoolId: userInfo.schoolId,
        cellphone: userInfo.cellphone,
        college: userInfo.college,
        schoolOrigin: userInfo.schoolOrigin,
        library: widget.selectedLibrary ?? '',
        service: '',
        startTime: slotStart,
        endTime: slotEnd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reserve ${ReservationType.seat.label}'),
      content: SingleChildScrollView(
        child: ShadCard(
          padding: const EdgeInsets.all(12),
          child: ShadForm(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((widget.selectedLibrary ?? '').isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Library: ${widget.selectedLibrary}'),
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date to reserve: ${formatDate(selectedDate)}',
                      ),
                    ),
                    TextButton(onPressed: _pickDate, child: const Text('Pick')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Time to reserve: ${formatTimeOfDay(selectedTime)}',
                      ),
                    ),
                    TextButton(onPressed: _pickTime, child: const Text('Pick')),
                  ],
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ShadButton(onPressed: _submit, child: const Text('Reserve')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
