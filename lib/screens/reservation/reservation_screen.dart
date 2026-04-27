import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/reservation.dart';
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

  const ReservationsScreen({
    super.key,
    required this.userRole,
    this.userName,
    this.userEmail,
    this.userType,
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
    _loadReservations();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load requests: $e')),
      );
    }
  }

  Future<ReservationItem?> _showReservationForm(
    ReservationType type,
    String library,
  ) async {
    if (_isUser) {
      return _showUserReservationForm(type, library);
    }

    if (type == ReservationType.scannedCopy) {
      return _showManagerScannedCopyRequestInput(library);
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
          ),
        );
      case ReservationType.scannedCopy:
        return showDialog<ReservationItem>(
          context: context,
          builder: (context) => ScannedCopyReservationForm(
            userEmail: widget.userEmail,
            userName: widget.userName,
            selectedLibrary: library,
          ),
        );
      case ReservationType.seat:
        return showDialog<ReservationItem>(
          context: context,
          builder: (context) => SeatReservationForm(
            userEmail: widget.userEmail,
            userName: widget.userName,
            selectedLibrary: library,
          ),
        );
      case ReservationType.discussionRoom:
        return showDialog<ReservationItem>(
          context: context,
          builder: (context) => DiscussionRoomReservationForm(
            userEmail: widget.userEmail,
            userName: widget.userName,
            selectedLibrary: library,
          ),
        );
    }
  }

  Future<ReservationItem?> _showManagerScannedCopyRequestInput(
    String library,
  ) async {
    final titleController = TextEditingController();
    final pageStartController = TextEditingController();
    final pageEndController = TextEditingController();
    String? errorMessage;

    final result = await showDialog<ReservationItem>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void onSave() {
            final title = titleController.text.trim();
            final pageStart = int.tryParse(pageStartController.text.trim());
            final pageEnd = int.tryParse(pageEndController.text.trim());

            if (title.isEmpty || pageStart == null || pageEnd == null) {
              setDialogState(() {
                errorMessage = 'Please enter title and valid page numbers.';
              });
              return;
            }

            if (pageStart <= 0 || pageEnd <= 0 || pageEnd < pageStart) {
              setDialogState(() {
                errorMessage =
                    'Page range is invalid. Ensure start/end are positive and end is not before start.';
              });
              return;
            }

            final totalPages = pageEnd - pageStart + 1;
            if (totalPages > 20) {
              setDialogState(() {
                errorMessage =
                    'Scanned copy request is limited to 20 pages only.';
              });
              return;
            }

            Navigator.of(dialogContext).pop(
              ReservationItem(
                type: ReservationType.scannedCopy,
                title: title,
                createdAt: DateTime.now(),
                requesterEmail: widget.userEmail ?? '',
                requesterName: widget.userName ?? '',
                library: library,
                pageStart: pageStart,
                pageEnd: pageEnd,
              ),
            );
          }

          return AlertDialog(
            title: const Text('Request Scanned Copy'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Book title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pageStartController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Page start'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pageEndController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Page end'),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Maximum 20 pages per request.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(onPressed: onSave, child: const Text('Save')),
            ],
          );
        },
      ),
    );

    titleController.dispose();
    pageStartController.dispose();
    pageEndController.dispose();
    return result;
  }

  Future<String?> _showTitleInput(ReservationType type) async {
    final controller = TextEditingController();
    final dialogTitle = type == ReservationType.scannedCopy
        ? 'Request Scan'
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
              child: Center(
                child: Text('No requests yet. Tap + to add one.'),
              ),
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
                    status: reservation.status,
                    createdAt: reservation.createdAt,
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
