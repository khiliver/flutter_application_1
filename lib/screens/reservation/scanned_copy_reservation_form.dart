import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/reservation.dart';

/// Form for students to request a scanned copy.
/// Collects: book title, page range (max 20 pages), and requester details.
class ScannedCopyReservationForm extends StatefulWidget {
  final String? userEmail;
  final String? userName;

  const ScannedCopyReservationForm({super.key, this.userEmail, this.userName});

  @override
  State<ScannedCopyReservationForm> createState() =>
      _ScannedCopyReservationFormState();
}

class _ScannedCopyReservationFormState
    extends State<ScannedCopyReservationForm> {
  final titleController = TextEditingController();
  final pageStartController = TextEditingController();
  final pageEndController = TextEditingController();
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final surnameController = TextEditingController();
  final schoolIdController = TextEditingController();
  final cellphoneController = TextEditingController();
  final collegeController = TextEditingController();
  final schoolOriginController = TextEditingController();

  DateTime? selectedDate;
  String? errorText;
  final formKey = GlobalKey<ShadFormState>();

  @override
  void dispose() {
    titleController.dispose();
    pageStartController.dispose();
    pageEndController.dispose();
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
    final pageStart = int.tryParse(pageStartController.text.trim());
    final pageEnd = int.tryParse(pageEndController.text.trim());

    if (selectedDate == null ||
        bookTitle.isEmpty ||
        pageStart == null ||
        pageEnd == null) {
      setState(() {
        errorText = 'Please complete title, date, and page range.';
      });
      return;
    }

    if (pageStart <= 0 || pageEnd <= 0 || pageEnd < pageStart) {
      setState(() {
        errorText = 'Page range is invalid.';
      });
      return;
    }

    final pageCount = pageEnd - pageStart + 1;
    if (pageCount > 20) {
      setState(() {
        errorText = 'Scanned copy request is limited to 20 pages only.';
      });
      return;
    }

    final name =
        '${firstNameController.text.trim()} ${middleNameController.text.trim()} ${surnameController.text.trim()}'
            .trim();

    Navigator.of(context).pop(
      ReservationItem(
        type: ReservationType.scannedCopy,
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
        pageStart: pageStart,
        pageEnd: pageEnd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Scanned Copy'),
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
                  controller: pageStartController,
                  placeholder: const Text('Page start'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: pageEndController,
                  placeholder: const Text('Page end'),
                  keyboardType: TextInputType.number,
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
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Maximum 20 pages per scanned copy request.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
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
