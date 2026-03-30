import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/reservation.dart';
import '../../services/account_storage.dart';
import '../../services/announcement_storage.dart';
import '../../services/notification_storage.dart';
import '../../services/reservation_storage.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({required this.role});

  final String role;

  late Future<List<Account>> accountsFuture;
  late Future<List<ReservationItem>> reservationsFuture;

  final TextEditingController announcementBodyController =
      TextEditingController();

  bool isPostingAnnouncement = false;
  DateTime selectedGraphDate = DateTime.now();
  String selectedCollegeFilter = 'All Colleges';

  File? selectedMedia;
  String? selectedMediaType;
  String? selectedFeeling;

  bool get isManager {
    final normalizedRole = role.toLowerCase();
    return normalizedRole == 'admin' ||
        normalizedRole == 'librarian' ||
        normalizedRole == 'super admin';
  }

  bool get isSuperAdmin => role.toLowerCase() == 'super admin';

  static const List<Map<String, Object>> topBooks = [
    {'title': 'Introduction to Flutter', 'count': 28},
    {'title': 'Data Structures in Dart', 'count': 22},
    {'title': 'Design Patterns for Mobile', 'count': 19},
  ];

  static const List<Map<String, Object>> hourlyStudents = [
    {'hour': '08:00', 'count': 14},
    {'hour': '10:00', 'count': 22},
    {'hour': '12:00', 'count': 18},
    {'hour': '14:00', 'count': 26},
    {'hour': '16:00', 'count': 17},
  ];

  static const List<Map<String, Object>> dailyStudents = [
    {'day': 'Mon', 'count': 72},
    {'day': 'Tue', 'count': 84},
    {'day': 'Wed', 'count': 63},
    {'day': 'Thu', 'count': 90},
    {'day': 'Fri', 'count': 78},
  ];

  static const List<String> assignableRoles = ['User', 'Librarian', 'Admin'];

  static const List<Map<String, dynamic>> feelings = [
    {
      'label': 'Happy',
      'icon': Icons.sentiment_satisfied,
      'color': Colors.yellow,
    },
    {
      'label': 'Sad',
      'icon': Icons.sentiment_dissatisfied,
      'color': Colors.blue,
    },
    {
      'label': 'Angry',
      'icon': Icons.sentiment_very_dissatisfied,
      'color': Colors.red,
    },
    {
      'label': 'Frustrated',
      'icon': Icons.sentiment_neutral,
      'color': Colors.orange,
    },
  ];

  void loadInitialData() {
    reloadAccounts(notify: false);
    reloadReservations(notify: false);
  }

  void reloadAccounts({bool notify = true}) {
    accountsFuture = AccountStorage.instance.getAccounts();
    if (notify) {
      notifyListeners();
    }
  }

  void reloadReservations({bool notify = true}) {
    reservationsFuture = ReservationStorage.instance.getReservations();
    if (notify) {
      notifyListeners();
    }
  }

  String collegeFor(ReservationItem reservation) {
    final college = reservation.collegeName.trim();
    return college.isEmpty ? 'Unspecified' : college;
  }

  List<String> buildCollegeFilterOptions(List<ReservationItem> reservations) {
    final options = <String>{'All Colleges'};
    for (final reservation in reservations) {
      options.add(collegeFor(reservation));
    }
    final sorted = options.toList()..sort();
    sorted.remove('All Colleges');
    return ['All Colleges', ...sorted];
  }

  void syncSelectedCollegeFilter(List<ReservationItem> reservations) {
    final options = buildCollegeFilterOptions(reservations);
    if (!options.contains(selectedCollegeFilter)) {
      selectedCollegeFilter = 'All Colleges';
    }
  }

  List<ReservationItem> applyCollegeFilter(List<ReservationItem> reservations) {
    if (selectedCollegeFilter == 'All Colleges') {
      return reservations;
    }
    return reservations
        .where(
          (reservation) => collegeFor(reservation) == selectedCollegeFilter,
        )
        .toList();
  }

  List<DateTime> buildWeekDates({int maxLength = 7}) {
    return List<DateTime>.generate(
      maxLength,
      (index) =>
          selectedGraphDate.subtract(Duration(days: maxLength - 1 - index)),
    );
  }

  Map<ReservationType, List<FlSpot>> buildSpotsByType(
    List<ReservationItem> reservations,
  ) {
    final filteredReservations = applyCollegeFilter(reservations);
    final weekDates = buildWeekDates();
    final types = ReservationType.values.toList();

    bool sameDay(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    List<FlSpot> buildTypeSpots(ReservationType type) {
      return weekDates.asMap().entries.map((entry) {
        final index = entry.key.toDouble();
        final day = entry.value;
        final count = filteredReservations
            .where((reservation) {
              final activityDate =
                  reservation.reservationDate ?? reservation.createdAt;
              return reservation.type == type && sameDay(activityDate, day);
            })
            .length
            .toDouble();
        return FlSpot(index, count);
      }).toList();
    }

    return {for (final type in types) type: buildTypeSpots(type)};
  }

  Map<ReservationType, Color> buildColorsByType(List<ReservationType> types) {
    const palette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];

    return <ReservationType, Color>{
      for (var i = 0; i < types.length; i++)
        types[i]: palette[i % palette.length],
    };
  }

  double computeChartMaxY(Map<ReservationType, List<FlSpot>> spotsByType) {
    final maxY = spotsByType.values
        .expand((spots) => spots)
        .map((spot) => spot.y)
        .fold<double>(
          0,
          (previous, value) => value > previous ? value : previous,
        );
    return maxY < 1 ? 1.0 : (maxY + 1);
  }

  double computeYInterval(double chartMaxY) {
    return chartMaxY <= 5 ? 1.0 : (chartMaxY / 5).ceilToDouble();
  }

  Future<void> pickGraphDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedGraphDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      selectedGraphDate = picked;
      notifyListeners();
    }
  }

  Future<void> pickCollegeFilter(
    BuildContext context,
    List<ReservationItem> reservations,
  ) async {
    final options = buildCollegeFilterOptions(reservations);
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: options
              .map(
                (option) => ListTile(
                  title: Text(option),
                  trailing: option == selectedCollegeFilter
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(context, option),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected != null && selected != selectedCollegeFilter) {
      selectedCollegeFilter = selected;
      notifyListeners();
    }
  }

  Future<void> postAnnouncement(BuildContext context) async {
    final body = announcementBodyController.text.trim();
    final hasMedia = selectedMedia != null;
    final hasFeeling = selectedFeeling != null;

    if (body.isEmpty && !hasMedia && !hasFeeling) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add text, photo, or feeling before posting.'),
        ),
      );
      return;
    }

    isPostingAnnouncement = true;
    notifyListeners();

    await AnnouncementStorage.instance.addAnnouncement(
      Announcement(
        title: '',
        body: body,
        createdAt: DateTime.now(),
        imagePath: selectedMedia?.path,
        emoji: selectedFeeling,
      ),
    );

    final notificationSubtitle = body.isNotEmpty
        ? body
        : 'A new announcement was posted.';
    for (final userType in ['Student', 'Faculty', 'Visitor']) {
      await NotificationStorage.instance.addAudienceNotification(
        title: 'New announcement',
        subtitle: notificationSubtitle,
        recipientRole: 'User',
        recipientUserType: userType,
      );
    }

    if (!context.mounted) {
      return;
    }

    announcementBodyController.clear();
    selectedMedia = null;
    selectedMediaType = null;
    selectedFeeling = null;
    isPostingAnnouncement = false;
    notifyListeners();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Announcement posted.')));
  }

  Future<void> pickMedia(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      return;
    }

    final media = await picker.pickImage(source: source);
    if (media != null) {
      selectedMedia = File(media.path);
      selectedMediaType = 'image';
      notifyListeners();
    }
  }

  Future<void> pickFeeling(BuildContext context) async {
    final feeling = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: feelings
              .map(
                (feelingOption) => ListTile(
                  leading: Icon(
                    feelingOption['icon'] as IconData,
                    color: feelingOption['color'] as Color,
                  ),
                  title: Text(feelingOption['label'] as String),
                  onTap: () =>
                      Navigator.pop(context, feelingOption['label'] as String),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (feeling != null) {
      selectedFeeling = feeling;
      notifyListeners();
    }
  }

  void removeSelectedMedia() {
    selectedMedia = null;
    selectedMediaType = null;
    notifyListeners();
  }

  void removeSelectedFeeling() {
    selectedFeeling = null;
    notifyListeners();
  }

  Future<void> editAccountRole(BuildContext context, Account account) async {
    if (!isSuperAdmin) {
      return;
    }

    var selectedRole = account.role;
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit role for ${account.name}'),
              content: DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: assignableRoles
                    .map(
                      (roleOption) => DropdownMenuItem(
                        value: roleOption,
                        child: Text(roleOption),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedRole = value;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(selectedRole),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result == account.role) {
      return;
    }

    final updated = await AccountStorage.instance.updateAccountRole(
      account.email,
      result,
      actingUserRole: role,
    );

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (!updated) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not update role. Only signed-in Super Admin can assign roles, or the account was changed.',
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text('Updated ${account.name} to $result.')),
    );
    reloadAccounts();
  }

  Future<void> deleteAccount(BuildContext context, Account account) async {
    if (!isSuperAdmin) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: Text('Delete ${account.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    final removed = await AccountStorage.instance.removeAccount(account.email);

    if (!context.mounted) {
      return;
    }

    if (!removed) {
      final accountIsSuperAdmin = account.role.toLowerCase() == 'super admin';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accountIsSuperAdmin
                ? 'Cannot delete the only Super Admin account.'
                : 'Could not remove account. It may have been changed already.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Removed ${account.name}')));
    reloadAccounts();
  }

  @override
  void dispose() {
    announcementBodyController.dispose();
    super.dispose();
  }
}
