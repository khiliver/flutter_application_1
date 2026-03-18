import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/reservation.dart';
import '../../services/notification_storage.dart';
import '../../services/reservation_storage.dart';
import '../../widgets/app_header.dart';
import '../../widgets/reservation_card.dart';

class ReservationsScreen extends StatefulWidget {
  final String userRole;
  final String? userName;
  final String? userEmail;

  const ReservationsScreen({
    super.key,
    required this.userRole,
    this.userName,
    this.userEmail,
  });

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  List<ReservationItem> _reservations = [];
  bool _isLoading = true;

  bool get _isAdmin => widget.userRole.toLowerCase() == 'admin';
  bool get _isLibrarian => widget.userRole.toLowerCase() == 'librarian';

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
    });

    final List<ReservationItem> all =
        (widget.userRole.toLowerCase() == 'admin' ||
            widget.userRole.toLowerCase() == 'librarian')
        ? await ReservationStorage.instance.getReservations()
        : (widget.userEmail != null
              ? await ReservationStorage.instance.getReservationsForUser(
                  widget.userEmail!,
                )
              : <ReservationItem>[]);

    if (!mounted) return;

    setState(() {
      _reservations = all;
      _isLoading = false;
    });
  }

  Future<void> _addReservation() async {
    final ReservationType? type = await showModalBottomSheet<ReservationType>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ReservationType.values.map((type) {
              return ListTile(
                leading: Icon(type.icon),
                title: Text('Reserve ${type.label}'),
                onTap: () => Navigator.of(context).pop(type),
              );
            }).toList(),
          ),
        );
      },
    );

    if (type == null) return;

    ReservationItem? newReservation;

    if (widget.userRole.toLowerCase() == 'user') {
      newReservation = await _showStudentReservationForm(type);
    } else {
      final title = await _askForTitle(type);
      if (title == null || title.isEmpty) return;
      newReservation = ReservationItem(
        type: type,
        title: title,
        createdAt: DateTime.now(),
        requesterEmail: widget.userEmail ?? '',
        requesterName: widget.userName ?? '',
      );
    }

    if (newReservation == null) return;

    await ReservationStorage.instance.addReservation(newReservation);
    await _loadReservations();

    // Notify admins and the student about the new reservation.
    if (widget.userRole.toLowerCase() == 'user') {
      final displayName = (widget.userName?.trim().isNotEmpty ?? false)
          ? widget.userName!
          : 'A user';

      // Admin notification (global)
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'New reservation',
          subtitle: '$displayName reserved "${newReservation.title}".',
          createdAt: DateTime.now(),
        ),
      );

      // Student notification (targeted)
      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        await NotificationStorage.instance.addNotification(
          AppNotification(
            title: 'Reservation created',
            subtitle:
                'Your reservation for "${newReservation.title}" was created.',
            createdAt: DateTime.now(),
            recipientEmail: widget.userEmail,
          ),
        );
      }
    }
  }

  Future<ReservationItem?> _showEditDialog(ReservationItem reservation) async {
    final titleController = TextEditingController(text: reservation.title);
    var status = reservation.status;
    final formKey = GlobalKey<ShadFormState>();

    return showDialog<ReservationItem>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${reservation.type.label} reservation'),
          content: ShadCard(
            padding: const EdgeInsets.all(12),
            child: ShadForm(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShadInput(
                    controller: titleController,
                    placeholder: Text(
                      reservation.type == ReservationType.book
                          ? 'Book title'
                          : 'Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ReservationStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ReservationStatus.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)),
                        )
                        .toList(),
                    onChanged: (s) {
                      if (s != null) {
                        status = s;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedTitle = titleController.text.trim();
                if (updatedTitle.isEmpty) return;
                Navigator.of(context).pop(
                  ReservationItem(
                    id: reservation.id,
                    type: reservation.type,
                    title: updatedTitle,
                    createdAt: reservation.createdAt,
                    status: status,
                    requesterEmail: reservation.requesterEmail,
                    requesterName: reservation.requesterName,
                    firstName: reservation.firstName,
                    middleName: reservation.middleName,
                    surname: reservation.surname,
                    reservationDate: reservation.reservationDate,
                    schoolId: reservation.schoolId,
                    cellphone: reservation.cellphone,
                    schoolOrigin: reservation.schoolOrigin,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<ReservationItem?> _showStudentReservationForm(
    ReservationType type,
  ) async {
    final titleController = TextEditingController();
    final firstNameController = TextEditingController();
    final middleNameController = TextEditingController();
    final surnameController = TextEditingController();
    final schoolIdController = TextEditingController();
    final cellphoneController = TextEditingController();
    final schoolOriginController = TextEditingController();

    DateTime? selectedDate;
    final formKey = GlobalKey<ShadFormState>();

    String formatDate(DateTime? date) {
      if (date == null) return 'Choose date';
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    return showDialog<ReservationItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Reserve ${type.label}'),
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
                          placeholder: Text(
                            type == ReservationType.book
                                ? 'Book title'
                                : 'Name',
                          ),
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
                            TextButton(
                              onPressed: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? now,
                                  firstDate: now,
                                  lastDate: now.add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  selectedDate = picked;
                                  setStateDialog(() {});
                                }
                              },
                              child: const Text('Pick'),
                            ),
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
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty || selectedDate == null) return;
                    final name =
                        '${firstNameController.text.trim()} ${middleNameController.text.trim()} ${surnameController.text.trim()}'
                            .trim();

                    Navigator.of(context).pop(
                      ReservationItem(
                        type: type,
                        title: title,
                        createdAt: DateTime.now(),
                        requesterEmail: widget.userEmail ?? '',
                        requesterName: name.isNotEmpty
                            ? name
                            : widget.userName ?? '',
                        firstName: firstNameController.text.trim(),
                        middleName: middleNameController.text.trim(),
                        surname: surnameController.text.trim(),
                        reservationDate: selectedDate,
                        schoolId: schoolIdController.text.trim(),
                        cellphone: cellphoneController.text.trim(),
                        schoolOrigin: schoolOriginController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _askForTitle(
    ReservationType type, {
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final formKey = GlobalKey<ShadFormState>();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${initialValue == null ? 'Reserve' : 'Edit'} ${type.label}',
          ),
          content: ShadCard(
            padding: const EdgeInsets.all(12),
            child: ShadForm(
              key: formKey,
              child: ShadInput(
                controller: controller,
                placeholder: Text(
                  type == ReservationType.book ? 'Book title' : 'Name',
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelReservation(int index) async {
    final reservation = _reservations[index];
    if (reservation.status == ReservationStatus.cancelled) return;

    reservation.status = ReservationStatus.cancelled;
    await ReservationStorage.instance.updateReservation(reservation);
    setState(() {});

    // Notify the student when their reservation changes.
    if (widget.userRole.toLowerCase() == 'user' &&
        widget.userEmail != null &&
        widget.userEmail!.isNotEmpty) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'Reservation updated',
          subtitle:
              'Your reservation for "${reservation.title}" was cancelled.',
          createdAt: DateTime.now(),
          recipientEmail: widget.userEmail,
        ),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cancelled reservation for "${reservation.title}"'),
      ),
    );
  }

  Future<void> _deleteReservation(int index) async {
    final removed = _reservations.removeAt(index);
    await ReservationStorage.instance.removeReservation(removed.id);
    setState(() {});

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted reservation "${removed.title}"')),
    );
  }

  void _showReservationInfo(ReservationItem reservation) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(reservation.type.label),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: ${reservation.title}'),
              const SizedBox(height: 8),
              Text('Status: ${reservation.status.label}'),
              const SizedBox(height: 8),
              Text('Created: ${reservation.createdAt}'),
              if (reservation.reservationDate != null) ...[
                const SizedBox(height: 8),
                Text('Date reserved: ${reservation.reservationDate}'),
              ],
              if (reservation.firstName.isNotEmpty ||
                  reservation.surname.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Name: ${reservation.firstName} ${reservation.middleName} ${reservation.surname}'
                      .trim(),
                ),
              ],
              if (reservation.schoolId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('School ID: ${reservation.schoolId}'),
              ],
              if (reservation.cellphone.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Cellphone: ${reservation.cellphone}'),
              ],
              if (reservation.schoolOrigin.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('School: ${reservation.schoolOrigin}'),
              ],
              if (_isAdmin) ...[
                const SizedBox(height: 8),
                Text('Requested by: ${reservation.requesterName}'),
                const SizedBox(height: 4),
                Text('Email: ${reservation.requesterEmail}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editReservation(int index) async {
    final reservation = _reservations[index];
    if (reservation.status == ReservationStatus.cancelled) return;

    final updated = await _showEditDialog(reservation);
    if (updated == null) return;

    await ReservationStorage.instance.updateReservation(updated);
    await _loadReservations();

    // Notify the student when their reservation changes.
    if (widget.userRole.toLowerCase() == 'user' &&
        widget.userEmail != null &&
        widget.userEmail!.isNotEmpty) {
      await NotificationStorage.instance.addNotification(
        AppNotification(
          title: 'Reservation updated',
          subtitle: 'Your reservation was updated to "${updated.title}".',
          createdAt: DateTime.now(),
          recipientEmail: widget.userEmail,
        ),
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated reservation "${updated.title}"')),
    );
  }

  List<Widget> _buildActions(ReservationItem reservation, int index) {
    // Admins can delete any reservation (and edit via long press).
    if (_isAdmin) {
      return [
        TextButton(
          onPressed: () => _deleteReservation(index),
          child: const Text('Delete'),
        ),
      ];
    }

    // Regular users can cancel only if the reservation is still pending.
    if (reservation.status == ReservationStatus.pending) {
      return [
        TextButton(
          onPressed: () => _cancelReservation(index),
          child: const Text('Cancel'),
        ),
      ];
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: ''),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
          ? const Center(child: Text('No reservations yet. Tap + to add one.'))
          : ListView.builder(
              itemCount: _reservations.length,
              itemBuilder: (context, index) {
                final reservation = _reservations[index];
                return GestureDetector(
                  onTap: () => _showReservationInfo(reservation),
                  onLongPress: () {
                    if ((_isAdmin || _isLibrarian) &&
                        reservation.status != ReservationStatus.cancelled) {
                      _editReservation(index);
                    }
                  },
                  child: ReservationCard(
                    title: reservation.title,
                    type: reservation.type,
                    status: reservation.status,
                    createdAt: reservation.createdAt,
                    actions: _buildActions(reservation, index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReservation,
        tooltip: 'Add reservation',
        child: const Icon(Icons.add),
      ),
    );
  }
}
