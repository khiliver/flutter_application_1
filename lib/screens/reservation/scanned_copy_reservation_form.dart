import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/reservation.dart';
import '../../services/account_storage.dart';
import 'reservation_form_user_info.dart';

/// Form for students to request a scanned copy.
/// Collects: book title, page range (max 20 pages), and requester details.
class ScannedCopyReservationForm extends StatefulWidget {
  final String? userEmail;
  final String? userName;
  final String? selectedLibrary;
  final Account? userAccount;

  const ScannedCopyReservationForm({
    super.key,
    this.userEmail,
    this.userName,
    this.selectedLibrary,
    this.userAccount,
  });

  @override
  State<ScannedCopyReservationForm> createState() =>
      _ScannedCopyReservationFormState();
}

class _ScannedCopyReservationFormState
    extends State<ScannedCopyReservationForm> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final pageStartController = TextEditingController();
  final pageEndController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String _selectedDocumentType = 'Thesis';
  String? errorText;
  final formKey = GlobalKey<ShadFormState>();

  final List<String> _documentTypeOptions = [
    'Thesis',
    'Printed Journals',
    'Periodical',
  ];

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    pageStartController.dispose();
    pageEndController.dispose();
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

  void _submit() {
    final documentType = _selectedDocumentType.trim();
    final bookTitle = titleController.text.trim();
    final author = authorController.text.trim();
    final pageStart = int.tryParse(pageStartController.text.trim());
    final pageEnd = int.tryParse(pageEndController.text.trim());

    if (selectedDate == null ||
        selectedTime == null ||
        documentType.isEmpty ||
        bookTitle.isEmpty ||
        author.isEmpty ||
        pageStart == null ||
        pageEnd == null) {
      setState(() {
        errorText =
            'Please complete document type, title, author, date, time, and page range.';
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

    final userInfo = ReservationFormUserInfo.fromAccount(
      widget.userAccount,
      fallbackEmail: widget.userEmail,
      fallbackName: widget.userName,
    );
    final slotStart = combineDateAndTime(selectedDate!, selectedTime!);
    final slotEnd = slotStart.add(const Duration(hours: 2));

    Navigator.of(context).pop(
      ReservationItem(
        type: ReservationType.scannedCopy,
        title: bookTitle,
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
        service: documentType,
        author: author,
        pageStart: pageStart,
        pageEnd: pageEnd,
        startTime: slotStart,
        endTime: slotEnd,
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
                if ((widget.selectedLibrary ?? '').isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Library: ${widget.selectedLibrary}'),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  initialValue: _selectedDocumentType,
                  decoration: const InputDecoration(
                    labelText: 'Document type',
                    border: OutlineInputBorder(),
                  ),
                  items: _documentTypeOptions
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedDocumentType = value;
                      errorText = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: titleController,
                  placeholder: const Text('Title'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: authorController,
                  placeholder: const Text('Author'),
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
