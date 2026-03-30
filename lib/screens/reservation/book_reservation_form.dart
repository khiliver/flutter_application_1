import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/reservation.dart';

/// Form for students to reserve a book.
/// Collects: book title, name, date, school ID, cellphone, college, from school.
class BookReservationForm extends StatefulWidget {
  final String? userEmail;
  final String? userName;

  const BookReservationForm({super.key, this.userEmail, this.userName});

  @override
  State<BookReservationForm> createState() => _BookReservationFormState();
}

class _BookReservationFormState extends State<BookReservationForm> {
  final titleController = TextEditingController();
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
    titleController.dispose();
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
    final bookTitle = titleController.text.trim();
    if (selectedDate == null) return;
    if (bookTitle.isEmpty) {
      return;
    }

    final name =
        '${firstNameController.text.trim()} ${middleNameController.text.trim()} ${surnameController.text.trim()}'
            .trim();

    Navigator.of(context).pop(
      ReservationItem(
        type: ReservationType.book,
        title: bookTitle,
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
      title: const Text('Reserve Book'),
      content: SingleChildScrollView(
        child: ShadCard(
          padding: const EdgeInsets.all(12),
          child: ShadForm(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadInput(
                  controller: titleController,
                  placeholder: const Text('Book title'),
                ),
                const SizedBox(height: 12),
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
