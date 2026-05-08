import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/reservation.dart';
import '../../services/account_storage.dart';
import 'reservation_form_user_info.dart';

/// Form for students to reserve a facility (discussion room).
/// If `selectedServiceName` is provided, it's used as the reservation title/service.
class DiscussionRoomReservationForm extends StatefulWidget {
  final String? userEmail;
  final String? userName;
  final String? selectedLibrary;
  final String? selectedServiceName;
  final Account? userAccount;

  const DiscussionRoomReservationForm({
    super.key,
    this.userEmail,
    this.userName,
    this.selectedLibrary,
    this.selectedServiceName,
    this.userAccount,
  });

  @override
  State<DiscussionRoomReservationForm> createState() =>
      _DiscussionRoomReservationFormState();
}

class _DiscussionRoomReservationFormState
    extends State<DiscussionRoomReservationForm> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? errorText;
  String? _selectedFacility;
  final TextEditingController _otherController = TextEditingController();
  final List<String> _facilityOptions = [
    'Discussion Room',
    'Interfaith',
    'AV Room',
    'Others',
  ];
  final formKey = GlobalKey<ShadFormState>();

  String formatDate(DateTime? date) {
    if (date == null) return 'Choose date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _otherController.dispose();
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

  Future<void> _pickDate() async {
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

  @override
  void initState() {
    super.initState();
    // Initialize facility selection from provided service name if possible
    final options = _facilityOptions;
    if (widget.selectedServiceName != null) {
      if (options.contains(widget.selectedServiceName)) {
        _selectedFacility = widget.selectedServiceName;
      } else {
        _selectedFacility = 'Others';
        _otherController.text = widget.selectedServiceName!;
      }
    } else {
      _selectedFacility = _facilityOptions.first;
    }
  }

  void _submit() {
    if (selectedDate == null || selectedTime == null) {
      setState(() {
        errorText = 'Please choose both date and time.';
      });
      return;
    }

    final facilityName = (_selectedFacility == 'Others')
        ? _otherController.text.trim()
        : (_selectedFacility ?? ReservationType.discussionRoom.label);

    if (facilityName.isEmpty) {
      setState(() {
        errorText = 'Please specify facility name.';
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

    try {
      final reservation = ReservationItem(
        type: ReservationType.discussionRoom,
        title: facilityName,
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
        service: facilityName,
        startTime: slotStart,
        endTime: slotEnd,
      );

      Navigator.of(context).pop(reservation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create reservation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle = widget.selectedServiceName != null
        ? 'Reserve ${widget.selectedServiceName}'
        : 'Reserve ${ReservationType.discussionRoom.label}';

    return AlertDialog(
      title: Text(dialogTitle),
      content: SingleChildScrollView(
        child: ShadCard(
          padding: const EdgeInsets.all(12),
          child: ShadForm(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Facility selection dropdown
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select facility'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedFacility,
                  items: _facilityOptions
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedFacility = v),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectedFacility == 'Others') ...[
                  TextField(
                    controller: _otherController,
                    decoration: const InputDecoration(
                      labelText: 'Specify facility',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
