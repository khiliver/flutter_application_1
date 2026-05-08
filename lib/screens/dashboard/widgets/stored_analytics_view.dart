import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../../services/analytics_storage.dart';

class StoredAnalyticsView extends StatefulWidget {
  final Future<void> Function(String snapshotId) onDeleteSnapshot;
  final Future<void> Function() onClearAll;

  const StoredAnalyticsView({
    super.key,
    required this.onDeleteSnapshot,
    required this.onClearAll,
  });

  @override
  State<StoredAnalyticsView> createState() => _StoredAnalyticsViewState();
}

class _StoredAnalyticsViewState extends State<StoredAnalyticsView> {
  late Future<List<AnalyticsSnapshot>> _snapshotsFuture;

  @override
  void initState() {
    super.initState();
    _refreshSnapshots();
  }

  void _refreshSnapshots() {
    setState(() {
      _snapshotsFuture = AnalyticsStorage.instance.getAllSnapshots();
    });
  }

  Future<void> _deleteSnapshot(String snapshotId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete snapshot?'),
        content: const Text(
          'This analytics snapshot will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await widget.onDeleteSnapshot(snapshotId);
      _refreshSnapshots();
    }
  }

  Future<void> _clearAllSnapshots() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all analytics?'),
        content: const Text(
          'All stored analytics snapshots will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await widget.onClearAll();
      _refreshSnapshots();
    }
  }

  Future<void> _downloadSnapshot(AnalyticsSnapshot snapshot) async {
    try {
      // Create Excel workbook
      final workbook = xlsio.Workbook();
      final summarySheet = workbook.worksheets[0];
      summarySheet.name = 'Summary';

      // Add summary data
      summarySheet.getRangeByIndex(1, 1).setText('Metric');
      summarySheet.getRangeByIndex(1, 2).setText('Value');

      summarySheet.getRangeByIndex(2, 1).setText('College Filter');
      summarySheet.getRangeByIndex(2, 2).setText(snapshot.collegeFilter);

      summarySheet.getRangeByIndex(3, 1).setText('Snapshot Date');
      summarySheet
          .getRangeByIndex(3, 2)
          .setText(
            '${snapshot.snapshotDate.year}-${snapshot.snapshotDate.month.toString().padLeft(2, '0')}-${snapshot.snapshotDate.day.toString().padLeft(2, '0')}',
          );

      summarySheet.getRangeByIndex(4, 1).setText('Total Records');
      summarySheet
          .getRangeByIndex(4, 2)
          .setNumber(snapshot.reservationDetails.length.toDouble());

      summarySheet.getRangeByIndex(5, 1).setText('Created At');
      summarySheet
          .getRangeByIndex(5, 2)
          .setText(
            '${snapshot.createdAt.year}-${snapshot.createdAt.month.toString().padLeft(2, '0')}-${snapshot.createdAt.day.toString().padLeft(2, '0')} ${snapshot.createdAt.hour.toString().padLeft(2, '0')}:${snapshot.createdAt.minute.toString().padLeft(2, '0')}',
          );

      // Add detailed data sheet if there are records
      if (snapshot.reservationDetails.isNotEmpty) {
        final detailSheet = workbook.worksheets.addWithName('Details');

        // Get all keys from the first record to create headers
        final firstRecord = snapshot.reservationDetails.first;
        final headers = firstRecord.keys.toList();

        for (var i = 0; i < headers.length; i++) {
          detailSheet.getRangeByIndex(1, i + 1).setText(headers[i]);
        }

        // Add data rows
        for (var i = 0; i < snapshot.reservationDetails.length; i++) {
          final record = snapshot.reservationDetails[i];
          for (var j = 0; j < headers.length; j++) {
            final value = record[headers[j]];
            if (value is num) {
              detailSheet
                  .getRangeByIndex(i + 2, j + 1)
                  .setNumber(value.toDouble());
            } else {
              detailSheet
                  .getRangeByIndex(i + 2, j + 1)
                  .setText(value.toString());
            }
          }
        }
      }

      final bytes = workbook.saveAsStream();
      workbook.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory(
        '${directory.path}${Platform.pathSeparator}analytics_exports',
      );

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final now = DateTime.now();
      final fileName =
          'analytics_${snapshot.collegeFilter}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.xlsx';
      final file = File(
        '${downloadDir.path}${Platform.pathSeparator}$fileName',
      );

      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analytics downloaded to ${file.path}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month $day, $year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AnalyticsSnapshot>>(
      future: _snapshotsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final snapshots = snapshot.data ?? [];

        if (snapshots.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No stored analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Export analytics to save snapshots locally',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stored Snapshots: ${snapshots.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      FutureBuilder<Map<String, dynamic>>(
                        future: AnalyticsStorage.instance.getMetadata(),
                        builder: (context, metaSnapshot) {
                          if (metaSnapshot.hasData) {
                            final bytes = snapshots.fold<int>(
                              0,
                              (sum, s) => sum + s.toJson().toString().length,
                            );
                            return Text(
                              'Storage: ${_formatBytes(bytes)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _clearAllSnapshots,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshots.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final snapshot = snapshots[index];
                  final createdAtText = _formatDateTime(snapshot.createdAt);
                  final reservationCount = snapshot.reservationDetails.length;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.assessment, color: Colors.blue[400]),
                      title: Text(
                        'Analytics - ${snapshot.collegeFilter}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Saved: $createdAtText',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Records: $reservationCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: SizedBox(
                        width: 48,
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteSnapshot(snapshot.id);
                            } else if (value == 'download') {
                              _downloadSnapshot(snapshot);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem<String>(
                              value: 'download',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.download,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Download'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      isThreeLine: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
