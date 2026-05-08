import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../constants.dart';
import '../../models/reservation.dart';
import '../../services/account_storage.dart';
import '../../services/analytics_storage.dart';
import '../../services/announcement_storage.dart';
import '../../services/notification_storage.dart';
import '../../services/reservation_notification_helper.dart';
import '../../services/reservation_storage.dart';

class _AccountEditResult {
  const _AccountEditResult({required this.role, this.unit});

  final String role;
  final String? unit;
}

class DashboardController extends ChangeNotifier {
  DashboardController({
    required this.role,
    required this.creatorEmail,
    required this.creatorName,
  });

  final String role;
  final String? creatorEmail;
  final String? creatorName;

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
        normalizedRole == 'over all admin' ||
        normalizedRole == 'super admin';
  }

  bool get isSuperAdmin {
    final normalizedRole = role.toLowerCase();
    return normalizedRole == 'over all admin' ||
        normalizedRole == 'super admin';
  }

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

  Future<void> exportAnalyticsToExcel(
    BuildContext context,
    List<ReservationItem> reservations,
  ) async {
    try {
      final filteredReservations = applyCollegeFilter(reservations);
      final weekDates = buildWeekDates();

      final workbook = xlsio.Workbook();
      final summarySheet = workbook.worksheets[0];
      summarySheet.name = 'Summary';

      final types = ReservationType.values.toList();
      summarySheet.getRangeByIndex(1, 1).setText('Date');
      for (var i = 0; i < types.length; i++) {
        summarySheet.getRangeByIndex(1, i + 2).setText(types[i].label);
      }

      bool sameDay(DateTime a, DateTime b) {
        return a.year == b.year && a.month == b.month && a.day == b.day;
      }

      for (var row = 0; row < weekDates.length; row++) {
        final day = weekDates[row];
        summarySheet
            .getRangeByIndex(row + 2, 1)
            .setText(
              '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
            );

        for (var col = 0; col < types.length; col++) {
          final type = types[col];
          final count = filteredReservations.where((reservation) {
            final activityDate =
                reservation.reservationDate ?? reservation.createdAt;
            return reservation.type == type && sameDay(activityDate, day);
          }).length;
          summarySheet
              .getRangeByIndex(row + 2, col + 2)
              .setNumber(count.toDouble());
        }
      }

      final detailSheet = workbook.worksheets.addWithName('Reservations');
      final headers = [
        'Type',
        'Status',
        'Requester Name',
        'Requester Email',
        'Reservation Date',
        'Created At',
        'College',
        'School Origin',
      ];
      for (var i = 0; i < headers.length; i++) {
        detailSheet.getRangeByIndex(1, i + 1).setText(headers[i]);
      }

      for (var i = 0; i < filteredReservations.length; i++) {
        final reservation = filteredReservations[i];
        final row = i + 2;
        final reservationDate = reservation.reservationDate;
        final reservationDateText = reservationDate == null
            ? ''
            : '${reservationDate.year}-${reservationDate.month.toString().padLeft(2, '0')}-${reservationDate.day.toString().padLeft(2, '0')}';
        final createdAt = reservation.createdAt;
        final createdAtText =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

        detailSheet.getRangeByIndex(row, 1).setText(reservation.type.label);
        detailSheet.getRangeByIndex(row, 2).setText(reservation.status.label);
        detailSheet.getRangeByIndex(row, 3).setText(reservation.requesterName);
        detailSheet.getRangeByIndex(row, 4).setText(reservation.requesterEmail);
        detailSheet.getRangeByIndex(row, 5).setText(reservationDateText);
        detailSheet.getRangeByIndex(row, 6).setText(createdAtText);
        detailSheet.getRangeByIndex(row, 7).setText(collegeFor(reservation));
        detailSheet
            .getRangeByIndex(row, 8)
            .setText(reservation.schoolOrigin.trim());
      }

      final bytes = workbook.saveAsStream();
      workbook.dispose();

      final now = DateTime.now();
      final fileName =
          'reservation_analytics_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      String? savedPath;

      final supportsNativeSaveDialog =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;

      if (supportsNativeSaveDialog) {
        const xlsxTypeGroup = XTypeGroup(label: 'Excel', extensions: ['xlsx']);

        final location = await getSaveLocation(
          suggestedName: '$fileName.xlsx',
          acceptedTypeGroups: const [xlsxTypeGroup],
        );

        if (location == null) {
          return;
        }

        final file = XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          name: '$fileName.xlsx',
        );
        await file.saveTo(location.path);
        savedPath = location.path;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final exportDir = Directory(
          '${directory.path}${Platform.pathSeparator}analytics_exports',
        );
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }

        final file = File(
          '${exportDir.path}${Platform.pathSeparator}$fileName.xlsx',
        );
        await file.writeAsBytes(bytes, flush: true);
        savedPath = file.path;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analytics exported to $savedPath'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              if (savedPath != null && savedPath.isNotEmpty) {
                await OpenFile.open(savedPath);
              }
            },
          ),
        ),
      );

      // Save analytics snapshot to local storage
      await _saveAnalyticsSnapshot(filteredReservations, weekDates, fileName);
    } on MissingPluginException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Save dialog is unavailable on this device. Please restart the app and try again.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export Excel file: $e')),
      );
    }
  }

  Future<void> _saveAnalyticsSnapshot(
    List<ReservationItem> filteredReservations,
    List<DateTime> weekDates,
    String fileName,
  ) async {
    try {
      final types = ReservationType.values.toList();

      // Build summary data
      final summaryData = <String, dynamic>{};

      bool sameDay(DateTime a, DateTime b) {
        return a.year == b.year && a.month == b.month && a.day == b.day;
      }

      for (var row = 0; row < weekDates.length; row++) {
        final day = weekDates[row];
        final dateKey =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final typeCount = <String, int>{};

        for (var col = 0; col < types.length; col++) {
          final type = types[col];
          final count = filteredReservations.where((reservation) {
            final activityDate =
                reservation.reservationDate ?? reservation.createdAt;
            return reservation.type == type && sameDay(activityDate, day);
          }).length;
          typeCount[type.label] = count;
        }

        summaryData[dateKey] = typeCount;
      }

      // Build reservation details
      final reservationDetails = filteredReservations.map((reservation) {
        final reservationDate = reservation.reservationDate;
        final reservationDateText = reservationDate == null
            ? ''
            : '${reservationDate.year}-${reservationDate.month.toString().padLeft(2, '0')}-${reservationDate.day.toString().padLeft(2, '0')}';
        final createdAt = reservation.createdAt;
        final createdAtText =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

        return {
          'type': reservation.type.label,
          'status': reservation.status.label,
          'requesterName': reservation.requesterName,
          'requesterEmail': reservation.requesterEmail,
          'reservationDate': reservationDateText,
          'createdAt': createdAtText,
          'college': collegeFor(reservation),
          'schoolOrigin': reservation.schoolOrigin.trim(),
        };
      }).toList();

      // Create snapshot
      final snapshot = AnalyticsSnapshot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        snapshotDate: selectedGraphDate,
        collegeFilter: selectedCollegeFilter,
        summaryData: summaryData,
        reservationDetails: reservationDetails,
      );

      // Save to local storage
      await AnalyticsStorage.instance.saveAnalyticsSnapshot(snapshot);
    } catch (e) {
      // Silently fail to avoid disrupting the export process
      debugPrint('Failed to save analytics snapshot: $e');
    }
  }

  Future<List<AnalyticsSnapshot>> getStoredAnalyticsSnapshots() async {
    return AnalyticsStorage.instance.getAllSnapshots();
  }

  Future<void> deleteAnalyticsSnapshot(String snapshotId) async {
    await AnalyticsStorage.instance.deleteSnapshot(snapshotId);
    notifyListeners();
  }

  Future<void> clearAllAnalytics() async {
    await AnalyticsStorage.instance.deleteAllSnapshots();
    notifyListeners();
  }

  Future<void> deleteOldAnalytics(int daysOld) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    await AnalyticsStorage.instance.deleteSnapshotsOlderThan(cutoffDate);
    notifyListeners();
  }

  Future<Map<String, dynamic>> getAnalyticsStorageInfo() async {
    final metadata = await AnalyticsStorage.instance.getMetadata();
    final usage = await AnalyticsStorage.instance.getStorageUsage();
    return {...metadata, 'storageUsageBytes': usage};
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

    String? persistedImagePath;
    if (selectedMedia != null) {
      final directory = await getApplicationDocumentsDirectory();
      final announcementDir = Directory(
        '${directory.path}${Platform.pathSeparator}announcements',
      );
      if (!await announcementDir.exists()) {
        await announcementDir.create(recursive: true);
      }

      final sourceFile = selectedMedia!;
      final extension = sourceFile.path.split('.').last;
      final safeExtension = extension.length <= 5 ? extension : 'jpg';
      final fileName =
          'announcement_${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
      final savedFile = await sourceFile.copy(
        '${announcementDir.path}${Platform.pathSeparator}$fileName',
      );
      persistedImagePath = savedFile.path;
    }

    await AnnouncementStorage.instance.addAnnouncement(
      Announcement(
        title: '',
        body: body,
        createdAt: DateTime.now(),
        imagePath: persistedImagePath,
        emoji: selectedFeeling,
        postedByEmail: creatorEmail,
        postedByName: creatorName,
        postedByRole: role,
      ),
    );

    final notificationTitle = body.isNotEmpty
        ? (body.length > 60 ? '${body.substring(0, 60)}…' : body)
        : 'Announcement preview';
    final notificationSubtitle = body.isNotEmpty
        ? body
        : hasMedia
        ? 'A photo announcement was posted.'
        : 'A new announcement was posted.';
    for (final userType in ['Student', 'Personel', 'Visitor']) {
      await NotificationStorage.instance.addAudienceNotification(
        title: notificationTitle,
        subtitle: notificationSubtitle,
        recipientRole: 'User',
        recipientUserType: userType,
        notificationType: AppNotificationType.announcement,
      );
    }
    for (final role in ['Admin', 'Librarian', 'Over All Admin']) {
      await NotificationStorage.instance.addAudienceNotification(
        title: notificationTitle,
        subtitle: notificationSubtitle,
        recipientRole: role,
        notificationType: AppNotificationType.announcement,
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

    final assignableLibraries = kLibraryOptions
        .where(
          (library) =>
              library != 'Subscribed Database' &&
              library != 'Perpectual ebook collection',
        )
        .toList(growable: false);

    var selectedRole = account.role;
    final unitController = TextEditingController(text: account.unit ?? '');
    String? selectedLibrary = assignableLibraries.contains(account.unit)
        ? account.unit
        : null;
    if ((selectedRole.toLowerCase() == 'librarian' ||
            selectedRole.toLowerCase() == 'admin') &&
        selectedLibrary == null &&
        assignableLibraries.isNotEmpty) {
      selectedLibrary = assignableLibraries.first;
    }
    String? dialogError;
    final result = await showDialog<_AccountEditResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final normalizedRole = selectedRole.toLowerCase();
            final requiresUnit =
                normalizedRole == 'admin' || normalizedRole == 'librarian';
            final requiresLibrary =
                normalizedRole == 'librarian' || normalizedRole == 'admin';
            final selectedLibraryValue =
                assignableLibraries.contains(selectedLibrary)
                ? selectedLibrary
                : (assignableLibraries.isNotEmpty
                      ? assignableLibraries.first
                      : null);
            return AlertDialog(
              title: Text('Edit account for ${account.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
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
                            final roleKey = value.toLowerCase();
                            if (roleKey == 'user') {
                              unitController.clear();
                              selectedLibrary = null;
                            }
                            if ((roleKey == 'librarian' ||
                                    roleKey == 'admin') &&
                                selectedLibrary == null &&
                                assignableLibraries.isNotEmpty) {
                              selectedLibrary = assignableLibraries.first;
                            }
                            dialogError = null;
                          });
                        }
                      },
                    ),
                    if (requiresUnit) ...[
                      const SizedBox(height: 12),
                      if (requiresLibrary)
                        DropdownButtonFormField<String>(
                          key: ValueKey<String?>(selectedLibraryValue),
                          isExpanded: true,
                          initialValue: selectedLibraryValue,
                          decoration: const InputDecoration(
                            labelText: 'Library Assignment',
                          ),
                          selectedItemBuilder: (context) => assignableLibraries
                              .map(
                                (library) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    library,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          items: assignableLibraries
                              .map(
                                (library) => DropdownMenuItem(
                                  value: library,
                                  child: Text(
                                    library,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedLibrary = value;
                                dialogError = null;
                              });
                            }
                          },
                        )
                      else
                        TextField(
                          controller: unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            hintText: 'Enter office/unit for this account',
                          ),
                        ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          dialogError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (requiresLibrary &&
                        (selectedLibrary == null ||
                            selectedLibrary!.trim().isEmpty)) {
                      setDialogState(() {
                        dialogError =
                            'Please assign a library for this account.';
                      });
                      return;
                    }

                    final selectedUnit = requiresLibrary
                        ? selectedLibrary!.trim()
                        : unitController.text.trim();
                    Navigator.of(context).pop(
                      _AccountEditResult(
                        role: selectedRole,
                        unit: selectedUnit.isEmpty ? null : selectedUnit,
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

    if (result == null) {
      return;
    }

    final roleUnchanged = result.role == account.role;
    final currentUnit = (account.unit ?? '').trim();
    final nextUnit = (result.unit ?? '').trim();
    final unitUnchanged = currentUnit == nextUnit;
    if (roleUnchanged && unitUnchanged) {
      return;
    }

    final updated = await AccountStorage.instance.updateAccountRole(
      account.email,
      result.role,
      unit: result.unit,
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
            'Could not update role. Only signed-in Over All Admin can assign roles, or the account was changed.',
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Updated ${account.name} to ${result.role}${result.unit != null ? ' (${result.unit})' : ''}.',
        ),
      ),
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
      final accountRole = account.role.toLowerCase();
      final accountIsSuperAdmin =
          accountRole == 'over all admin' || accountRole == 'super admin';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accountIsSuperAdmin
                ? 'Cannot delete the only Over All Admin account.'
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

  // Collection Request Methods
  Future<void> requestCollection({
    required BuildContext context,
    required String collectionName,
    required String collectionDescription,
    required String requestReason,
    required int desiredQuantity,
  }) async {
    try {
      final collectionRequest = ReservationItem(
        type: ReservationType.collection,
        title: collectionName,
        createdAt: DateTime.now(),
        requesterEmail: creatorEmail ?? '',
        requesterName: creatorName ?? '',
        collectionName: collectionName,
        collectionDescription: collectionDescription,
        requestReason: requestReason,
        desiredQuantity: desiredQuantity,
      );

      await ReservationStorage.instance.addReservation(collectionRequest);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collection request submitted successfully!'),
        ),
      );
      reloadReservations();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit collection request: $e')),
      );
    }
  }

  Future<List<ReservationItem>> getCollectionRequests() async {
    final allReservations = await ReservationStorage.instance.getReservations();
    return allReservations
        .where((r) => r.type == ReservationType.collection)
        .toList();
  }

  Future<List<ReservationItem>> getUserCollectionRequests(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final allReservations = await ReservationStorage.instance.getReservations();
    return allReservations
        .where(
          (r) =>
              r.type == ReservationType.collection &&
              r.requesterEmail.toLowerCase() == normalizedEmail,
        )
        .toList();
  }

  Future<void> updateCollectionRequestStatus(
    BuildContext context,
    ReservationItem collectionRequest,
    ReservationStatus newStatus,
  ) async {
    try {
      final updated = collectionRequest;
      updated.status = newStatus;

      await ReservationStorage.instance.updateReservation(updated);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Collection request status updated to ${newStatus.label}',
          ),
        ),
      );
      reloadReservations();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update collection request: $e')),
      );
    }
  }

  Future<void> respondToCollectionRequest(
    BuildContext context,
    ReservationItem collectionRequest,
    bool isAccepted,
    String adminMessage,
  ) async {
    try {
      final updated = collectionRequest;
      updated.status = isAccepted
          ? ReservationStatus.accepted
          : ReservationStatus.declined;
      updated.adminMessage = adminMessage;

      await ReservationStorage.instance.updateReservation(updated);

      // Send approval notification if accepted
      if (isAccepted) {
        await ReservationNotificationHelper.notifyReservationApproved(
          updated,
          userEmail: updated.requesterEmail,
        );
      }

      if (!context.mounted) return;
      final status = isAccepted ? 'accepted' : 'declined';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Collection request $status')));
      reloadReservations();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to respond to collection request: $e')),
      );
    }
  }

  @override
  void dispose() {
    announcementBodyController.dispose();
    super.dispose();
  }
}
