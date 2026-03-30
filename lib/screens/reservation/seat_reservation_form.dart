import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/reservation.dart';

/// Form for students to reserve a seat.
/// Collects: name, date, school ID, cellphone, college, from school.
class SeatReservationForm extends StatefulWidget {
  final String? userEmail;
  final String? userName;

  const SeatReservationForm({super.key, this.userEmail, this.userName});

  @override
  State<SeatReservationForm> createState() => _SeatReservationFormState();
}

class _SeatReservationFormState extends State<SeatReservationForm> {
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final surnameController = TextEditingController();
  final schoolIdController = TextEditingController();
  final cellphoneController = TextEditingController();
  final collegeController = TextEditingController();
  final schoolOriginController = TextEditingController();

  DateTime? selectedDate;
  final formKey = GlobalKey<ShadFormState>();

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    surnameController.dispose();
    schoolIdController.dispose();
    cellphoneController.dispose();
    collegeController.dispose();
    schoolOriginController.dispose();
    super.dispose();
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Choose date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
    if (selectedDate == null) return;

    final name =
        '${firstNameController.text.trim()} ${middleNameController.text.trim()} ${surnameController.text.trim()}'
            .trim();

    Navigator.of(context).pop(
      ReservationItem(
        type: ReservationType.seat,
        title: ReservationType.seat.label,
        createdAt: DateTime.now(),
        requesterEmail: widget.userEmail ?? '',
        requesterName: name.isNotEmpty ? name : widget.userName ?? '',
        firstName: firstNameController.text.trim(),
        middleName: middleNameController.text.trim(),
        surname: surnameController.text.trim(),
        reservationDate: selectedDate,
        schoolId: schoolIdController.text.trim(),
        cellphone: cellphoneController.text.trim(),
        college: collegeController.text.trim(),
        schoolOrigin: schoolOriginController.text.trim(),
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
                ShadInput(
                  controller: firstNameController,
                  placeholder: const Text('First Name'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: middleNameController,
                  placeholder: const Text('Middle Name'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: surnameController,
                  placeholder: const Text('Surname'),
                ),
                const SizedBox(height: 12),
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
                ShadInput(
                  controller: schoolIdController,
                  placeholder: const Text('School ID / Student ID'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: cellphoneController,
                  placeholder: const Text('Cellphone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: collegeController,
                  placeholder: const Text('From College'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: schoolOriginController,
                  placeholder: const Text('From School'),
                ),
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
