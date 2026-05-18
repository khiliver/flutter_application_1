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
  final yearController = TextEditingController();

  DateTime? selectedDate;
  String _selectedDocumentType = 'Thesis/Dissertation';
  String? errorText;
  final formKey = GlobalKey<ShadFormState>();

  final List<String> _documentTypeOptions = [
    'Thesis/Dissertation',
    'Books',
    'Periodical',
  ];

  bool get _isThesisRequest => _selectedDocumentType == 'Thesis/Dissertation';

  bool get _isBookRequest => _selectedDocumentType == 'Books';

  bool get _isPeriodicalRequest => _selectedDocumentType == 'Periodical';

  String get _pageStartLabel => _isThesisRequest ? 'Program' : 'Page start';

  String get _pageEndLabel => _isThesisRequest ? 'Year' : 'Page end';

  String get _yearLabel => 'Year';

  String get _titleLabel => _isPeriodicalRequest ? 'Periodical title' : 'Title';

  String get _authorLabel => _isPeriodicalRequest ? 'Title of page' : 'Author';

  String get _completionErrorMessage => _isThesisRequest
      ? 'Please complete document type, title, author, date, program, and year.'
      : 'Please complete document type, title, author, date, and page range.';

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    pageStartController.dispose();
    pageEndController.dispose();
    yearController.dispose();
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
    final documentType = _selectedDocumentType.trim();
    final bookTitle = titleController.text.trim();
    final author = authorController.text.trim();
    final pageStartValue = pageStartController.text.trim();
    final pageEndValue = pageEndController.text.trim();
    final yearValue = yearController.text.trim();
    final pageStart = _isThesisRequest ? null : int.tryParse(pageStartValue);
    final pageEnd = int.tryParse(pageEndValue);
    final publicationYear = _isBookRequest ? int.tryParse(yearValue) : 0;

    if (selectedDate == null ||
        documentType.isEmpty ||
        bookTitle.isEmpty ||
        author.isEmpty ||
        pageEnd == null ||
        (_isThesisRequest ? pageStartValue.isEmpty : pageStart == null) ||
        (_isBookRequest && publicationYear == null)) {
      setState(() {
        errorText = _completionErrorMessage;
      });
      return;
    }

    if (_isThesisRequest) {
      if (pageEnd <= 0) {
        setState(() {
          errorText = 'Year is invalid.';
        });
        return;
      }
    } else {
      if (pageStart == null ||
          pageStart <= 0 ||
          pageEnd <= 0 ||
          pageEnd < pageStart) {
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

      if (_isBookRequest && (publicationYear == null || publicationYear <= 0)) {
        setState(() {
          errorText = 'Year is invalid.';
        });
        return;
      }
    }

    final userInfo = ReservationFormUserInfo.fromAccount(
      widget.userAccount,
      fallbackEmail: widget.userEmail,
      fallbackName: widget.userName,
    );

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
        reservationDate: selectedDate,
        schoolId: userInfo.schoolId,
        cellphone: userInfo.cellphone,
        college: userInfo.college,
        schoolOrigin: userInfo.schoolOrigin,
        library: widget.selectedLibrary ?? '',
        service: documentType,
        author: author,
        pageStart: pageStart ?? 0,
        pageEnd: pageEnd,
        thesisProgram: _isThesisRequest ? pageStartValue : '',
        thesisYear: _isThesisRequest ? pageEnd : 0,
        publicationYear: _isBookRequest ? publicationYear! : 0,
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
                  placeholder: Text(_titleLabel),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: authorController,
                  placeholder: Text(_authorLabel),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: pageStartController,
                  placeholder: Text(_pageStartLabel),
                  keyboardType: _isThesisRequest
                      ? TextInputType.text
                      : TextInputType.number,
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: pageEndController,
                  placeholder: Text(_pageEndLabel),
                  keyboardType: TextInputType.number,
                ),
                if (_isBookRequest) ...[
                  const SizedBox(height: 12),
                  ShadInput(
                    controller: yearController,
                    placeholder: Text(_yearLabel),
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date Requested: ${formatDate(selectedDate)}',
                      ),
                    ),
                    TextButton(onPressed: _pickDate, child: const Text('Pick')),
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
