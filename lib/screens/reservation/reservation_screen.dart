import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/reservation.dart';
import '../../services/account_storage.dart';
import '../../services/reservation_notification_helper.dart';
import '../../services/reservation_storage.dart';
import '../../widgets/app_header.dart';
import '../../widgets/reservation_card.dart';
import 'book_reservation_form.dart';
import 'discussion_room_reservation_form.dart';
import 'edit_reservation_dialog.dart';
import 'reservation_info_dialog.dart';
import 'reservation_type_picker_dialog.dart';
import 'scanned_copy_reservation_form.dart';
import 'seat_reservation_form.dart';

class ReservationsScreen extends StatefulWidget {
  final String userRole;
  final String? userName;
  final String? userEmail;
  final String? userType;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onLogoPressed;

  const ReservationsScreen({
    super.key,
    required this.userRole,
    this.userName,
    this.userEmail,
    this.userType,
    this.onProfilePressed,
    this.onLogoPressed,
  });

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  static const Set<String> _noReservationLibraries = {
    'Perpectual ebook collection',
    'Subscribed Database',
  };

  List<ReservationItem> _reservations = [];
  bool _isLoading = true;
  Account? _currentAccount;

  String _normalizeRoleToken(String role) {
    return role.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  }

  String get _normalizedRole => _normalizeRoleToken(userRole);
  bool get _isAdmin => _normalizedRole == 'admin';
  bool get _isUser => _normalizedRole == 'user';
  bool get _canManageAllRequests => _isManager;
  bool get _isManager {
    return _normalizedRole == 'admin' ||
        _normalizedRole == 'librarian' ||
        _normalizedRole == 'overalladmin' ||
        _normalizedRole == 'superadmin';
  }

  String get userRole => widget.userRole;
  bool get _isNonBuUser => (widget.userType ?? '').toLowerCase() == 'non-bu';

  @override
  void initState() {
    super.initState();
    _loadCurrentAccount();
    _loadReservations();
  }

  Future<void> _loadCurrentAccount() async {
    final email = widget.userEmail?.trim();
    if (email == null || email.isEmpty) return;

    try {
      final account = await AccountStorage.instance.findByEmail(email);
      if (!mounted) return;
      setState(() {
        _currentAccount = account;
      });
    } catch (_) {
      // Keep the existing fallback values if the account lookup fails.
    }
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);

    try {
      final reservations = _canManageAllRequests
          ? await ReservationStorage.instance.getReservations()
          : (widget.userEmail != null
                ? await ReservationStorage.instance.getReservationsForUser(
                    widget.userEmail!,
                  )
                : <ReservationItem>[]);

      if (!mounted) return;
      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load requests: $e')));
    }
  }

  Future<ReservationItem?> _showReservationForm(
    ReservationType type,
    String library,
  ) async {
    final useDetailedRequestForm =
        type == ReservationType.book ||
        type == ReservationType.seat ||
        type == ReservationType.discussionRoom ||
        type == ReservationType.scannedCopy;

    if (useDetailedRequestForm) {
      return _showUserReservationForm(type, library);
    }

    if (_isUser) {
      return _showUserReservationForm(type, library);
    }

    final title = await _showTitleInput(type);
    if (title?.isNotEmpty ?? false) {
      return ReservationItem(
        type: type,
        title: title!,
        createdAt: DateTime.now(),
        requesterEmail: widget.userEmail ?? '',
        requesterName: widget.userName ?? '',
        library: library,
        service: type.label,
      );
    }

    return null;
  }

  Future<ReservationItem?> _showUserReservationForm(
    ReservationType type,
    String library,
  ) {
    switch (type) {
      case ReservationType.book:
        return showDialog<ReservationItem>(
          context: context,
          builder: (context) => BookReservationForm(
            userEmail: widget.userEmail,
            userName: widget.userName,
            selectedLibrary: library,
            userAccount: _currentAccount,
          ),
        );
      case ReservationType.scannedCopy:
        return showDialog<ReservationItem>(
          context: context,
          builder: (context) => ScannedCopyReservationForm(
            userEmail: widget.userEmail,
            userName: widget.userName,
            selectedLibrary: library,
            userAccount: _currentAccount,
          ),
        );
      case ReservationType.seat:
        return showDialog<ReservationItem>(
          context: context,
          builder: (context) => SeatReservationForm(
            userEmail: widget.userEmail,
            userName: widget.userName,
            selectedLibrary: library,
            userAccount: _currentAccount,
          ),
        );
      case ReservationType.discussionRoom:
        return showDialog<ReservationItem>(
          context: context,
          builder: (context) => DiscussionRoomReservationForm(
            userEmail: widget.userEmail,
            userName: widget.userName,
            selectedLibrary: library,
            userAccount: _currentAccount,
          ),
        );
      case ReservationType.collection:
        // Collection requests moved to profile screen
        return Future.value(null);
    }
  }

  Future<String?> _showTitleInput(ReservationType type) async {
    final controller = TextEditingController();
    final dialogTitle = type == ReservationType.scannedCopy
        ? 'Document Delivery'
        : 'Reserve ${type.label}';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText:
                type == ReservationType.book ||
                    type == ReservationType.scannedCopy
                ? 'Book title'
                : 'Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showLibraryPicker() {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: kLibraryOptions.length,
          itemBuilder: (context, index) {
            final library = kLibraryOptions[index];
            return ListTile(
              leading: const Icon(Icons.local_library),
              title: Text(library),
              onTap: () => Navigator.of(context).pop(library),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addReservation() async {
    final library = await _showLibraryPicker();
    if (!mounted) return;
    if (library == null) return;
    if (_noReservationLibraries.contains(library)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Requests are not available for this library selection.',
          ),
        ),
      );
      return;
    }

    final ReservationType? selectedType;
    if (_isNonBuUser) {
      selectedType = ReservationType.seat;
    } else {
      selectedType = await showModalBottomSheet<ReservationType>(
        context: context,
        builder: (context) => const ReservationTypePickerDialog(),
      );
      if (selectedType == null) return;
    }

    final newReservation = await _showReservationForm(selectedType, library);
    if (newReservation == null) return;

    try {
      await ReservationStorage.instance.addReservation(newReservation);
      await _loadReservations();
      if (!mounted) return;
      await ReservationNotificationHelper.notifyReservationCreated(
        newReservation,
        userEmail: widget.userEmail,
        userName: widget.userName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  Future<void> _cancelReservation(int index) async {
    _reservations[index].status = ReservationStatus.cancelled;
    await ReservationStorage.instance.updateReservation(_reservations[index]);
    setState(() {});

    await ReservationNotificationHelper.notifyReservationCancelled(
      _reservations[index],
      isManager: _isManager,
      userRole: userRole,
      userEmail: widget.userEmail,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cancelled "${_reservations[index].title}"')),
    );
  }

  Future<void> _deleteReservation(int index) async {
    final removed = _reservations.removeAt(index);
    await ReservationStorage.instance.removeReservation(removed.id);
    setState(() {});

    await ReservationNotificationHelper.notifyReservationDeleted(
      removed,
      isManager: _isManager,
      userRole: userRole,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted "${removed.title}"')));
  }

  Future<void> _editReservation(int index) async {
    final updated = await showDialog<ReservationItem>(
      context: context,
      builder: (context) =>
          EditReservationDialog(reservation: _reservations[index]),
    );

    if (updated == null) return;

    await ReservationStorage.instance.updateReservation(updated);
    await _loadReservations();

    await ReservationNotificationHelper.notifyReservationUpdated(
      _reservations[index],
      updated,
      isManager: _isManager,
      userRole: userRole,
      userEmail: widget.userEmail,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Updated "${updated.title}"')));
  }

  Future<void> _acceptReservation(int index) async {
    final messageController = TextEditingController();
    DateTime? selectedStartTime;

    final shouldAccept = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Accept Reservation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    hintText: 'Add a message for the requester',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Select 2-hour Timeslot:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedStartTime != null
                                  ? 'Start: ${selectedStartTime!.hour.toString().padLeft(2, '0')}:${selectedStartTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Select start time',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedStartTime = DateTime(
                                    _reservations[index]
                                            .reservationDate
                                            ?.year ??
                                        DateTime.now().year,
                                    _reservations[index]
                                            .reservationDate
                                            ?.month ??
                                        DateTime.now().month,
                                    _reservations[index].reservationDate?.day ??
                                        DateTime.now().day,
                                    picked.hour,
                                    picked.minute,
                                  );
                                });
                              }
                            },
                            child: const Text('Pick'),
                          ),
                        ],
                      ),
                      if (selectedStartTime != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'End: ${selectedStartTime!.add(const Duration(hours: 2)).hour.toString().padLeft(2, '0')}:${selectedStartTime!.add(const Duration(hours: 2)).minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedStartTime != null
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Accept'),
            ),
          ],
        ),
      ),
    );

    if (shouldAccept == true && selectedStartTime != null) {
      _reservations[index].status = ReservationStatus.accepted;
      _reservations[index].adminMessage = messageController.text;
      _reservations[index].startTime = selectedStartTime;
      _reservations[index].endTime = selectedStartTime!.add(
        const Duration(hours: 2),
      );

      await ReservationStorage.instance.updateReservation(_reservations[index]);

      // Send approval notification
      await ReservationNotificationHelper.notifyReservationApproved(
        _reservations[index],
        userEmail: _reservations[index].requesterEmail,
      );

      setState(() {});
      messageController.dispose();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accepted "${_reservations[index].title}"')),
      );
    }
    messageController.dispose();
  }

  Future<void> _declineReservation(int index) async {
    final messageController = TextEditingController();

    final shouldDecline = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Reservation'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'Explain why you are declining',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (shouldDecline == true) {
      _reservations[index].status = ReservationStatus.declined;
      _reservations[index].adminMessage = messageController.text;

      await ReservationStorage.instance.updateReservation(_reservations[index]);
      setState(() {});
      messageController.dispose();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Declined "${_reservations[index].title}"')),
      );
    }
    messageController.dispose();
  }

  Future<void> _clearReservations() async {
    try {
      await ReservationStorage.instance.clearReservations();
      if (!mounted) return;
      setState(() {
        _reservations = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not clear requests: $e')));
    }
  }

  List<Widget> _buildActions(ReservationItem reservation, int index) {
    if (_isManager && reservation.status == ReservationStatus.pending) {
      return [
        TextButton(
          onPressed: () => _acceptReservation(index),
          child: const Text('Accept', style: TextStyle(color: Colors.green)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _declineReservation(index),
          child: const Text('Decline', style: TextStyle(color: Colors.red)),
        ),
      ];
    }

    if (_isAdmin) {
      return [
        TextButton(
          onPressed: () => _deleteReservation(index),
          child: const Text('Delete'),
        ),
      ];
    }

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

  Widget _buildRefreshableReservationsBody() {
    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_reservations.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No requests yet. Tap + to add one.')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final reservation = _reservations[index];
                return GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => ReservationInfoDialog(
                      reservation: reservation,
                      isAdmin: _isAdmin,
                    ),
                  ),
                  onLongPress: () {
                    if (_isManager &&
                        reservation.status != ReservationStatus.cancelled) {
                      _editReservation(index);
                    }
                  },
                  child: ReservationCard(
                    title: reservation.title,
                    type: reservation.type,
                    requesterName: reservation.requesterName,
                    status: reservation.status,
                    createdAt: reservation.createdAt,
                    adminMessage: reservation.adminMessage,
                    startTime: reservation.startTime,
                    endTime: reservation.endTime,
                    actions: _buildActions(reservation, index),
                  ),
                );
              }, childCount: _reservations.length),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: '',
        onProfilePressed: widget.onProfilePressed,
        onLogoPressed: widget.onLogoPressed,
        actions: _isManager
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Clear all',
                  onPressed: _reservations.isEmpty ? null : _clearReservations,
                ),
              ]
            : null,
      ),
      body: _buildRefreshableReservationsBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReservation,
        tooltip: 'Add request',
        child: const Icon(Icons.add),
      ),
    );
  }
}
