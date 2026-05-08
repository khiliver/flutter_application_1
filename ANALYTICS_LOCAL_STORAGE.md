# Analytics Local Storage Implementation

## Overview
This implementation adds local device storage for analytics data, allowing users to:
- Automatically cache analytics snapshots when exporting to Excel
- View all stored analytics snapshots
- Delete individual or all analytics snapshots
- Track storage usage
- Retrieve cached analytics data without needing server connection

## Files Created/Modified

### 1. **AnalyticsStorage Service** (`lib/services/analytics_storage.dart`)
A singleton service for managing analytics snapshots in local storage.

**Key Classes:**
- `AnalyticsSnapshot`: Represents a single analytics data snapshot
  - `id`: Unique identifier
  - `createdAt`: When the snapshot was saved
  - `snapshotDate`: The date the analytics were for
  - `collegeFilter`: Which college filter was applied
  - `summaryData`: Daily summary of reservations by type
  - `reservationDetails`: Detailed reservation records

**Key Methods:**
```dart
// Save a new snapshot
Future<void> saveAnalyticsSnapshot(AnalyticsSnapshot snapshot)

// Retrieve all snapshots
Future<List<AnalyticsSnapshot>> getAllSnapshots()

// Get specific snapshot by ID
Future<AnalyticsSnapshot?> getSnapshotById(String id)

// Filter snapshots by date range
Future<List<AnalyticsSnapshot>> getSnapshotsByDateRange(DateTime start, DateTime end)

// Filter snapshots by college
Future<List<AnalyticsSnapshot>> getSnapshotsByCollege(String college)

// Delete specific snapshot
Future<void> deleteSnapshot(String id)

// Clear all snapshots
Future<void> deleteAllSnapshots()

// Delete snapshots older than date
Future<void> deleteSnapshotsOlderThan(DateTime date)

// Get metadata (count, last saved, max allowed)
Future<Map<String, dynamic>> getMetadata()

// Get storage usage in bytes
Future<int> getStorageUsage()
```

### 2. **StoredAnalyticsView Widget** (`lib/screens/dashboard/widgets/stored_analytics_view.dart`)
A reusable UI component to display and manage stored analytics snapshots.

**Features:**
- List all stored snapshots with creation date and record count
- Shows storage usage
- Delete individual snapshots with confirmation
- Clear all snapshots with warning
- Empty state message when no snapshots exist
- Formatted dates and storage sizes

### 3. **DashboardController Updates** (`lib/screens/dashboard/dashboard_controller.dart`)
Enhanced the controller with analytics storage integration:

**New Methods:**
```dart
// Automatically saves snapshot after export (called internally)
Future<void> _saveAnalyticsSnapshot(...)

// Get all stored analytics snapshots
Future<List<AnalyticsSnapshot>> getStoredAnalyticsSnapshots()

// Delete a specific snapshot
Future<void> deleteAnalyticsSnapshot(String snapshotId)

// Clear all analytics
Future<void> clearAllAnalytics()

// Delete analytics older than N days
Future<void> deleteOldAnalytics(int daysOld)

// Get storage metadata and usage
Future<Map<String, dynamic>> getAnalyticsStorageInfo()
```

## Integration Guide

### Basic Setup
The analytics storage is automatically integrated with the export feature. When a user exports analytics to Excel, it automatically saves a snapshot to local storage.

### Using StoredAnalyticsView in Dashboard
To display stored analytics in your dashboard, add this to your dashboard screen:

```dart
import 'package:flutter_application_1/screens/dashboard/widgets/stored_analytics_view.dart';

// In your dashboard build method:
StoredAnalyticsView(
  onDeleteSnapshot: (id) => _controller.deleteAnalyticsSnapshot(id),
  onClearAll: () => _controller.clearAllAnalytics(),
)
```

### Example: Creating a Tab for Stored Analytics

```dart
DefaultTabController(
  length: 2,
  child: Column(
    children: [
      const TabBar(
        tabs: [
          Tab(text: 'Current Analytics'),
          Tab(text: 'Stored Snapshots'),
        ],
      ),
      Expanded(
        child: TabBarView(
          children: [
            // Current analytics view
            ReservationLineChart(...),
            
            // Stored snapshots
            StoredAnalyticsView(
              onDeleteSnapshot: (id) => _controller.deleteAnalyticsSnapshot(id),
              onClearAll: () => _controller.clearAllAnalytics(),
            ),
          ],
        ),
      ),
    ],
  ),
)
```

## Data Persistence Details

### Storage Mechanism
- Uses `SharedPreferences` for local device storage
- Snapshots stored as JSON strings
- Maximum of 50 recent snapshots kept (configurable via `_maxStoredSnapshots`)

### Storage Keys
- `analytics_snapshots_v1`: Stores all snapshot data
- `analytics_metadata_v1`: Stores metadata (count, last saved date)

### Default Limits
- **Max Snapshots**: 50 (oldest removed automatically)
- **Data Fields Stored**:
  - Summary data (daily breakdown by reservation type)
  - Detailed reservation records
  - Filter information (college filter applied)
  - Timestamps

## Usage Examples

### Get all stored snapshots
```dart
final snapshots = await AnalyticsStorage.instance.getAllSnapshots();
snapshots.forEach((snapshot) {
  print('${snapshot.collegeFilter}: ${snapshot.reservationDetails.length} records');
});
```

### Get snapshots from last 7 days
```dart
final startDate = DateTime.now().subtract(Duration(days: 7));
final recentSnapshots = await AnalyticsStorage.instance.getSnapshotsByDateRange(
  startDate,
  DateTime.now(),
);
```

### Clean up old analytics (keep only last 30 days)
```dart
final cutoffDate = DateTime.now().subtract(Duration(days: 30));
await AnalyticsStorage.instance.deleteSnapshotsOlderThan(cutoffDate);
```

### Check storage usage
```dart
final info = await _controller.getAnalyticsStorageInfo();
print('Snapshots: ${info['totalSnapshots']}');
print('Storage: ${(info['storageUsageBytes'] / 1024).toStringAsFixed(2)} KB');
```

## Flow Diagram

```
User Exports Analytics
        ↓
exportAnalyticsToExcel() executes
        ↓
Creates Excel file & saves to device
        ↓
_saveAnalyticsSnapshot() called
        ↓
AnalyticsStorage.saveAnalyticsSnapshot()
        ↓
Data stored in SharedPreferences
        ↓
User can now view/download from StoredAnalyticsView
```

## Automatic Cleanup

The system automatically:
1. Removes duplicate snapshots (by ID)
2. Keeps only the 50 most recent snapshots
3. Updates metadata timestamp when saved

## Benefits

✅ **Offline Access**: Users can view exported analytics without internet  
✅ **Quick Retrieval**: No need to re-generate analytics reports  
✅ **Storage Management**: Automatic cleanup of old snapshots  
✅ **Easy Access**: Dedicated UI for viewing and managing snapshots  
✅ **Data Integrity**: Proper serialization and error handling  
✅ **Performance**: Efficient JSON-based storage  

## Future Enhancements

- Export snapshot data back to Excel
- Share snapshots via email or other apps
- Archive old snapshots to external storage
- Search/filter stored snapshots
- Compare multiple snapshots side-by-side
