# Local Analytics Storage - Quick Start Guide

## What Was Added

I've implemented a complete local storage system for your analytics data that allows you to:

### 🎯 Key Features
- **Auto-save on export**: Analytics snapshots are automatically saved when you export to Excel
- **Local cache**: Store up to 50 recent analytics snapshots on the device
- **Offline access**: View analytics without internet connection
- **Easy management**: Delete individual or all snapshots
- **Storage tracking**: See how much space analytics are using

## Files Added

1. **`lib/services/analytics_storage.dart`** - Core storage service
2. **`lib/screens/dashboard/widgets/stored_analytics_view.dart`** - UI widget for managing snapshots
3. **`ANALYTICS_LOCAL_STORAGE.md`** - Detailed documentation

## Files Modified

1. **`lib/screens/dashboard/dashboard_controller.dart`** - Added analytics saving integration

## How to Use

### Option 1: Show Stored Analytics in a Tab

```dart
// In your dashboard or admin screen
DefaultTabController(
  length: 2,
  child: Column(
    children: [
      const TabBar(
        tabs: [
          Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          Tab(text: 'History', icon: Icon(Icons.history)),
        ],
      ),
      Expanded(
        child: TabBarView(
          children: [
            // Current analytics view
            ReservationLineChart(...),
            
            // Stored analytics snapshots
            StoredAnalyticsView(
              onDeleteSnapshot: (id) => _dashboardController.deleteAnalyticsSnapshot(id),
              onClearAll: () => _dashboardController.clearAllAnalytics(),
            ),
          ],
        ),
      ),
    ],
  ),
)
```

### Option 2: Standalone View

```dart
Scaffold(
  appBar: AppBar(title: const Text('Analytics History')),
  body: StoredAnalyticsView(
    onDeleteSnapshot: (id) => _dashboardController.deleteAnalyticsSnapshot(id),
    onClearAll: () => _dashboardController.clearAllAnalytics(),
  ),
)
```

### Option 3: Programmatic Access

```dart
// Get all snapshots
final snapshots = await _dashboardController.getStoredAnalyticsSnapshots();

// Delete a snapshot
await _dashboardController.deleteAnalyticsSnapshot(snapshotId);

// Clear all
await _dashboardController.clearAllAnalytics();

// Get storage info
final info = await _dashboardController.getAnalyticsStorageInfo();
print('Total snapshots: ${info['totalSnapshots']}');
print('Storage used: ${info['storageUsageBytes']} bytes');

// Delete old snapshots (older than 30 days)
await _dashboardController.deleteOldAnalytics(30);
```

## What Happens When You Export

```
User clicks "Export Analytics"
    ↓
Excel file is generated and saved
    ↓
Snapshot automatically saved to device storage
    ↓
User can later view/download from "Stored Analytics" view
```

## Data Stored Per Snapshot

Each snapshot includes:
- ✅ Unique ID (timestamp-based)
- ✅ Date created
- ✅ Which week's analytics
- ✅ College filter applied
- ✅ Daily summary (counts by type)
- ✅ All reservation details

## Storage Limits

- **Maximum snapshots**: 50 (oldest auto-deleted)
- **Storage key**: `analytics_snapshots_v1` in SharedPreferences
- **Format**: JSON-encoded for efficiency

## Example Integration in Dashboard

Here's how to add it to your existing admin dashboard:

```dart
class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = DashboardController(role: widget.role);
    _controller.loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Snapshots', icon: Icon(Icons.history)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Current analytics
          ReservationLineChart(...),
          
          // Stored analytics snapshots
          StoredAnalyticsView(
            onDeleteSnapshot: (id) => _controller.deleteAnalyticsSnapshot(id),
            onClearAll: () => _controller.clearAllAnalytics(),
          ),
          
          // Settings
          SettingsView(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }
}
```

## Common Tasks

### Check storage usage
```dart
final info = await AnalyticsStorage.instance.getMetadata();
final usageBytes = await AnalyticsStorage.instance.getStorageUsage();
print('Using ${(usageBytes / 1024).toStringAsFixed(2)} KB');
print('${info['totalSnapshots']} snapshots stored');
```

### Get analytics from specific date
```dart
final start = DateTime(2024, 5, 1);
final end = DateTime(2024, 5, 7);
final snapshots = await AnalyticsStorage.instance.getSnapshotsByDateRange(start, end);
```

### Find snapshots for specific college
```dart
final collegeSnapshots = await AnalyticsStorage.instance.getSnapshotsByCollege('All Colleges');
```

### Auto-cleanup old data (run periodically)
```dart
// Keep only last 60 days of data
final cutoff = DateTime.now().subtract(Duration(days: 60));
await AnalyticsStorage.instance.deleteSnapshotsOlderThan(cutoff);
```

## No Additional Setup Required!

✅ Everything is already integrated
✅ No new dependencies needed (uses existing SharedPreferences)
✅ Automatically saves when exporting
✅ Ready to use in your dashboard

## Next Steps

1. Import the `StoredAnalyticsView` widget in your dashboard
2. Add it to your UI (as shown in examples above)
3. Users can now export and manage analytics locally
4. Snapshots persist even after app restart

Happy analytics tracking! 📊
