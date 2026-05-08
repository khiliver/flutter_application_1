import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/reservation.dart';
import '../../services/account_storage.dart';
import '../../services/reservation_storage.dart';
import 'reservation_form_user_info.dart';

/// Form for students to reserve a book.
/// Collects: book title, name, date, school ID, cellphone, college, from school.
class BookReservationForm extends StatefulWidget {
  final String? userEmail;
  final String? userName;
  final String? selectedLibrary;
  final Account? userAccount;

  const BookReservationForm({
    super.key,
    this.userEmail,
    this.userName,
    this.selectedLibrary,
    this.userAccount,
  });

  @override
  State<BookReservationForm> createState() => _BookReservationFormState();
}

class _BookReservationFormState extends State<BookReservationForm> {
  final titleController = TextEditingController();
  final authorController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? errorText;
  int _activeBookReservations = 0;
  bool _isLoadingBookCount = true;
  final formKey = GlobalKey<ShadFormState>();

  int get _bookReservationLimit {
    final userType = (widget.userAccount?.userType ?? '').trim().toLowerCase();
    final personelType = (widget.userAccount?.personelType ?? '')
        .trim()
        .toLowerCase();

    if (userType == 'student') {
      return 2;
    }

    if (userType == 'personel' &&
        (personelType == 'faculty' ||
            personelType == 'non-teaching personel')) {
      return 5;
    }

    return 2;
  }

  Future<int> _countActiveBookReservations(String requesterEmail) async {
    if (requesterEmail.trim().isEmpty) return 0;

    final reservations = await ReservationStorage.instance
        .getReservationsForUser(requesterEmail);
    return reservations
        .where(
          (reservation) =>
              reservation.type == ReservationType.book &&
              reservation.status != ReservationStatus.cancelled,
        )
        .length;
  }

  Future<void> _loadBookReservationCount() async {
    final requesterEmail = (widget.userEmail ?? widget.userAccount?.email ?? '')
        .trim();
    if (requesterEmail.isEmpty) {
      if (!mounted) return;
      setState(() {
        _activeBookReservations = 0;
        _isLoadingBookCount = false;
      });
      return;
    }

    try {
      final count = await _countActiveBookReservations(requesterEmail);
      if (!mounted) return;
      setState(() {
        _activeBookReservations = count;
        _isLoadingBookCount = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activeBookReservations = 0;
        _isLoadingBookCount = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBookReservationCount();
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
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

  Future<void> _submit() async {
    final bookTitle = titleController.text.trim();
    final author = authorController.text.trim();
    if (selectedDate == null || selectedTime == null) {
      setState(() {
        errorText = 'Please choose both date and time.';
      });
      return;
    }
    if (bookTitle.isEmpty) {
      return;
    }
    if (author.isEmpty) {
      setState(() {
        errorText = 'Please enter the author name.';
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
      final activeBookReservations = await _countActiveBookReservations(
        userInfo.requesterEmail,
      );

      if (!mounted) return;

      if (activeBookReservations >= _bookReservationLimit) {
        setState(() {
          errorText =
              'You can only reserve $_bookReservationLimit book(s) at a time.';
        });
        return;
      }

      Navigator.of(context).pop(
        ReservationItem(
          type: ReservationType.book,
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
          service: '',
          author: author,
          startTime: slotStart,
          endTime: slotEnd,
        ),
      );

      if (mounted) {
        setState(() {
          _activeBookReservations += 1;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not check book limit: $e')));
    }
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
                if ((widget.selectedLibrary ?? '').isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Library: ${widget.selectedLibrary}'),
                  ),
                  const SizedBox(height: 12),
                ],
                ShadInput(
                  controller: titleController,
                  placeholder: const Text('Book title'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: authorController,
                  placeholder: const Text('Author'),
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
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isLoadingBookCount
                        ? 'Checking your current book reservations...'
                        : 'You currently have $_activeBookReservations of $_bookReservationLimit book reservation(s).',
                    style: const TextStyle(color: Colors.black54),
                  ),
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
