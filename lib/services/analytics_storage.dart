import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class AnalyticsSnapshot {
  final String id;
  final DateTime createdAt;
  final DateTime snapshotDate;
  final String collegeFilter;
  final Map<String, dynamic> summaryData;
  final List<Map<String, dynamic>> reservationDetails;

  AnalyticsSnapshot({
    required this.id,
    required this.createdAt,
    required this.snapshotDate,
    required this.collegeFilter,
    required this.summaryData,
    required this.reservationDetails,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'snapshotDate': snapshotDate.toIso8601String(),
    'collegeFilter': collegeFilter,
    'summaryData': summaryData,
    'reservationDetails': reservationDetails,
  };

  factory AnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    return AnalyticsSnapshot(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      snapshotDate: DateTime.parse(json['snapshotDate'] as String),
      collegeFilter: json['collegeFilter'] as String,
      summaryData: Map<String, dynamic>.from(json['summaryData'] as Map),
      reservationDetails: List<Map<String, dynamic>>.from(
        (json['reservationDetails'] as List).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      ),
    );
  }

  String get fileName => 'analytics_snapshot_$id.json';
}

/// Storage service for analytics data saved to device file storage.
/// Saves snapshots as JSON files in the app's Documents directory.
/// Location: /Documents/Analytics/
class AnalyticsStorage {
  AnalyticsStorage._();

  static final AnalyticsStorage instance = AnalyticsStorage._();

  static const String _analyticsFolderName = 'Analytics';
  static const String _metadataFileName = 'analytics_metadata.json';

  /// Get the analytics folder path on the device storage
  Future<Directory> _getAnalyticsDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final analyticsDir = Directory(
      '${documentsDir.path}/$_analyticsFolderName',
    );

    if (!await analyticsDir.exists()) {
      await analyticsDir.create(recursive: true);
    }

    return analyticsDir;
  }

  /// Save analytics snapshot as a JSON file to device storage
  Future<String> saveAnalyticsSnapshot(AnalyticsSnapshot snapshot) async {
    try {
      final analyticsDir = await _getAnalyticsDirectory();
      final file = File('${analyticsDir.path}/${snapshot.fileName}');

      // Write snapshot to file
      await file.writeAsString(jsonEncode(snapshot.toJson()));

      // Update metadata
      await _updateMetadata();

      return file.path;
    } catch (e) {
      debugPrint('Error saving analytics snapshot: $e');
      rethrow;
    }
  }

  /// Get all analytics snapshots from device storage
  Future<List<AnalyticsSnapshot>> getAllSnapshots() async {
    try {
      final analyticsDir = await _getAnalyticsDirectory();

      if (!await analyticsDir.exists()) {
        return [];
      }

      final files = analyticsDir.listSync();
      final snapshots = <AnalyticsSnapshot>[];

      for (final file in files) {
        if (file is File &&
            file.path.endsWith('.json') &&
            !file.path.contains(_metadataFileName)) {
          try {
            final content = await file.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            snapshots.add(AnalyticsSnapshot.fromJson(json));
          } catch (e) {
            debugPrint('Error reading snapshot file ${file.path}: $e');
          }
        }
      }

      // Sort by created date, newest first
      snapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return snapshots;
    } catch (e) {
      debugPrint('Error getting all snapshots: $e');
      return [];
    }
  }

  /// Get specific snapshot by ID
  Future<AnalyticsSnapshot?> getSnapshotById(String id) async {
    try {
      final analyticsDir = await _getAnalyticsDirectory();
      final file = File('${analyticsDir.path}/analytics_snapshot_$id.json');

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return AnalyticsSnapshot.fromJson(json);
    } catch (e) {
      debugPrint('Error getting snapshot by ID: $e');
      return null;
    }
  }

  /// Get snapshots within a date range
  Future<List<AnalyticsSnapshot>> getSnapshotsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshots = await getAllSnapshots();
    return snapshots
        .where(
          (s) =>
              s.snapshotDate.isAfter(startDate) &&
              s.snapshotDate.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  /// Get snapshots by college filter
  Future<List<AnalyticsSnapshot>> getSnapshotsByCollege(String college) async {
    final snapshots = await getAllSnapshots();
    return snapshots.where((s) => s.collegeFilter == college).toList();
  }

  /// Delete specific snapshot file from device storage
  Future<void> deleteSnapshot(String id) async {
    try {
      final analyticsDir = await _getAnalyticsDirectory();
      final file = File('${analyticsDir.path}/analytics_snapshot_$id.json');

      if (await file.exists()) {
        await file.delete();
        await _updateMetadata();
      }
    } catch (e) {
      debugPrint('Error deleting snapshot: $e');
    }
  }

  /// Delete all analytics snapshot files
  Future<void> deleteAllSnapshots() async {
    try {
      final analyticsDir = await _getAnalyticsDirectory();

      if (await analyticsDir.exists()) {
        final files = analyticsDir.listSync();
        for (final file in files) {
          if (file is File && file.path.endsWith('.json')) {
            await file.delete();
          }
        }
        await _updateMetadata();
      }
    } catch (e) {
      debugPrint('Error deleting all snapshots: $e');
    }
  }

  /// Delete snapshots older than specified date
  Future<void> deleteSnapshotsOlderThan(DateTime date) async {
    try {
      final snapshots = await getAllSnapshots();
      final oldSnapshots = snapshots
          .where((s) => s.createdAt.isBefore(date))
          .toList();

      for (final snapshot in oldSnapshots) {
        await deleteSnapshot(snapshot.id);
      }
    } catch (e) {
      debugPrint('Error deleting old snapshots: $e');
    }
  }

  /// Get analytics folder path (user-accessible location on device)
  Future<String> getAnalyticsFolderPath() async {
    final dir = await _getAnalyticsDirectory();
    return dir.path;
  }

  /// Get metadata about stored analytics
  Future<Map<String, dynamic>> getMetadata() async {
    try {
      final analyticsDir = await _getAnalyticsDirectory();
      final metadataFile = File('${analyticsDir.path}/$_metadataFileName');

      if (!await metadataFile.exists()) {
        return {
          'totalSnapshots': 0,
          'lastSavedAt': null,
          'folderPath': analyticsDir.path,
          'totalStorageSize': 0,
        };
      }

      final content = await metadataFile.readAsString();
      return Map<String, dynamic>.from(jsonDecode(content));
    } catch (e) {
      debugPrint('Error reading metadata: $e');
      return {
        'totalSnapshots': 0,
        'lastSavedAt': null,
        'folderPath': (await _getAnalyticsDirectory()).path,
        'totalStorageSize': 0,
      };
    }
  }

  /// Update metadata file with current statistics
  Future<void> _updateMetadata() async {
    try {
      final snapshots = await getAllSnapshots();
      final analyticsDir = await _getAnalyticsDirectory();

      // Calculate total storage size
      int totalSize = 0;
      for (final snapshot in snapshots) {
        final file = File('${analyticsDir.path}/${snapshot.fileName}');
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }

      final metadata = {
        'totalSnapshots': snapshots.length,
        'lastSavedAt': DateTime.now().toIso8601String(),
        'folderPath': analyticsDir.path,
        'totalStorageSize': totalSize,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final metadataFile = File('${analyticsDir.path}/$_metadataFileName');
      await metadataFile.writeAsString(jsonEncode(metadata));
    } catch (e) {
      debugPrint('Error updating metadata: $e');
    }
  }

  /// Get total storage usage in bytes
  Future<int> getStorageUsage() async {
    try {
      final analyticsDir = await _getAnalyticsDirectory();
      int totalSize = 0;

      final files = analyticsDir.listSync();
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating storage usage: $e');
      return 0;
    }
  }

  /// Get list of analytics files with their info
  Future<List<FileSystemEntity>> getAnalyticsFiles() async {
    try {
      final analyticsDir = await _getAnalyticsDirectory();

      if (!await analyticsDir.exists()) {
        return [];
      }

      final files = analyticsDir
          .listSync()
          .where((file) => file is File && file.path.endsWith('.json'))
          .toList();

      return files;
    } catch (e) {
      debugPrint('Error getting analytics files: $e');
      return [];
    }
  }
}
