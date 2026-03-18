import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/account_storage.dart';
import '../../services/announcement_storage.dart';
import '../../widgets/app_header.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// A simple dashboard used for librarian and admin roles.
///
/// Demonstrates analytics sections and, for admin, a user management list.
class DashboardScreen extends StatefulWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final bool isManager =
      widget.role.toLowerCase() == 'admin' ||
      widget.role.toLowerCase() == 'librarian';
  late Future<List<Account>> _accountsFuture;

  // Announcement post state (only shown to admins)
  final TextEditingController _announcementBodyController =
      TextEditingController();
  bool _isPostingAnnouncement = false;
  DateTime _selectedGraphDate = DateTime.now();

  // Media and feeling state
  File? _selectedMedia;
  String? _selectedMediaType; // 'image' or 'video'
  String? _selectedFeeling;

  final List<Map<String, dynamic>> _feelings = [
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

  @override
  void initState() {
    super.initState();
    _reloadAccounts();
  }

  void _reloadAccounts() {
    _accountsFuture = AccountStorage.instance.getAccounts();
  }

  static const _topBooks = [
    {'title': 'Introduction to Flutter', 'count': 28},
    {'title': 'Data Structures in Dart', 'count': 22},
    {'title': 'Design Patterns for Mobile', 'count': 19},
  ];

  static const _hourlyStudents = [
    {'hour': '08:00', 'count': 14},
    {'hour': '10:00', 'count': 22},
    {'hour': '12:00', 'count': 18},
    {'hour': '14:00', 'count': 26},
    {'hour': '16:00', 'count': 17},
  ];

  static const _dailyStudents = [
    {'day': 'Mon', 'count': 72},
    {'day': 'Tue', 'count': 84},
    {'day': 'Wed', 'count': 63},
    {'day': 'Thu', 'count': 90},
    {'day': 'Fri', 'count': 78},
  ];

  @override
  Widget build(BuildContext context) {
    final title = '${widget.role} Dashboard';

    if (!isManager) {
      return Scaffold(
        appBar: AppBar(title: Text(title), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            _buildSectionTitle('Top Reserved Books'),
            ..._topBooks.map(_buildBookTile),
            const SizedBox(height: 24),
            _buildSectionTitle('Reservation Activity (per hour)'),
            _buildStatRow(_hourlyStudents, 'hour'),
            const SizedBox(height: 24),
            _buildSectionTitle('Reservation Activity (per day)'),
            _buildStatRow(_dailyStudents, 'day'),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const AppHeader(),
      body: Column(
        children: [
          // Sticky post section (always visible while scrolling below)
          _buildAnnouncementsSection(),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTrendHeader(),
                  const SizedBox(height: 8),
                  _buildLineChart(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('User Management'),
                  FutureBuilder<List<Account>>(
                    future: _accountsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final accounts = snapshot.data ?? [];
                      if (accounts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No created accounts yet.'),
                        );
                      }
                      return Column(
                        children: accounts
                            .map((a) => _buildAccountTile(context, a))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildBookTile(Map<String, Object> book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(book['title'] as String),
        trailing: Text('${book['count']} reservations'),
      ),
    );
  }

  Widget _buildStatRow(List<Map<String, Object>> data, String labelKey) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: data.map((entry) {
        return SizedBox(
          width: 140,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry[labelKey] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry['count']} users (students/faculty/staff/visitors)',
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChart() {
    // Multi-series chart showing all available dashboard counts.
    // Ensure all series span the same X range so lines don't appear "cut".
    final maxLength = _dailyStudents.length;

    final dateSeed =
        _selectedGraphDate.year * 10000 +
        _selectedGraphDate.month * 100 +
        _selectedGraphDate.day;
    final weekDates = List<DateTime>.generate(
      maxLength,
      (index) =>
          _selectedGraphDate.subtract(Duration(days: maxLength - 1 - index)),
    );

    final dailySpots = _dailyStudents.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final baseCount = (entry.value['count'] as int);
      final adjustedCount = (baseCount + ((dateSeed + entry.key * 3) % 11) - 5)
          .clamp(5, 120);
      final count = adjustedCount.toDouble();
      return FlSpot(index, count);
    }).toList();

    final hourlyCounts = _hourlyStudents.asMap().entries.map((entry) {
      final baseCount = _hourlyStudents[entry.key]['count'] as int;
      final adjustedCount = (baseCount + ((dateSeed + entry.key * 5) % 9) - 4)
          .clamp(4, 60);
      return adjustedCount.toDouble();
    }).toList();
    while (hourlyCounts.length < maxLength) {
      hourlyCounts.add(hourlyCounts.isNotEmpty ? hourlyCounts.last : 0);
    }
    final hourlySpots = hourlyCounts.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final bookCounts = _topBooks.asMap().entries.map((entry) {
      final baseCount = _topBooks[entry.key]['count'] as int;
      final adjustedCount = (baseCount + ((dateSeed + entry.key * 7) % 10) - 4)
          .clamp(3, 80);
      return adjustedCount.toDouble();
    }).toList();
    while (bookCounts.length < maxLength) {
      bookCounts.add(bookCounts.isNotEmpty ? bookCounts.last : 0);
    }
    final bookSpots = bookCounts.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final maxY = [
      ...dailySpots.map((s) => s.y),
      ...hourlyCounts,
      ...bookCounts,
    ].fold<double>(0, (prev, v) => v > prev ? v : prev);
    final chartMaxY = maxY < 10 ? 10.0 : maxY;

    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: chartMaxY / 5,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: chartMaxY / 5,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= weekDates.length) {
                        return const SizedBox.shrink();
                      }
                      final date = weekDates[index];
                      return Text(
                        '${date.month}/${date.day}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    interval: 1,
                  ),
                ),
              ),
              minX: 0,
              maxX: (_dailyStudents.length - 1).toDouble(),
              minY: 0,
              maxY: chartMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: dailySpots,
                  isCurved: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withAlpha((0.2 * 255).round()),
                  ),
                  color: Colors.blue,
                  barWidth: 3,
                ),
                LineChartBarData(
                  spots: hourlySpots,
                  isCurved: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withAlpha((0.2 * 255).round()),
                  ),
                  color: Colors.green,
                  barWidth: 3,
                ),
                LineChartBarData(
                  spots: bookSpots,
                  isCurved: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.orange.withAlpha((0.2 * 255).round()),
                  ),
                  color: Colors.orange,
                  barWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Reservation Activity (trend)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: _pickGraphDate,
          icon: const Icon(Icons.calendar_today),
          tooltip: 'Select date',
        ),
      ],
    );
  }

  Future<void> _pickGraphDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedGraphDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        _selectedGraphDate = picked;
      });
    }
  }

  Future<void> _postAnnouncement() async {
    final body = _announcementBodyController.text.trim();
    final hasMedia = _selectedMedia != null;
    final hasFeeling = _selectedFeeling != null;

    if (body.isEmpty && !hasMedia && !hasFeeling) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add text, photo, or feeling before posting.'),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isPostingAnnouncement = true;
    });

    await AnnouncementStorage.instance.addAnnouncement(
      Announcement(
        title: '',
        body: body,
        createdAt: DateTime.now(),
        imagePath: _selectedMedia?.path,
        emoji: _selectedFeeling,
      ),
    );

    if (!mounted) return;

    setState(() {
      _announcementBodyController.clear();
      _selectedMedia = null;
      _selectedMediaType = null;
      _selectedFeeling = null;
      _isPostingAnnouncement = false;
    });

    messenger.showSnackBar(
      const SnackBar(content: Text('Announcement posted.')),
    );
  }

  Future<void> _pickMedia() async {
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
    if (source == null) return;

    final media = await picker.pickImage(source: source);
    if (media != null) {
      setState(() {
        _selectedMedia = File(media.path);
        _selectedMediaType = 'image';
      });
    }
    // For video support, you can add picker.pickVideo similarly
  }

  Future<void> _pickFeeling() async {
    final feeling = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _feelings
              .map(
                (f) => ListTile(
                  leading: Icon(f['icon'], color: f['color'] as Color),
                  title: Text(f['label']),
                  onTap: () => Navigator.pop(context, f['label'] as String),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (feeling != null) {
      setState(() {
        _selectedFeeling = feeling;
      });
    }
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 18, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _announcementBodyController,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedMedia != null || _selectedFeeling != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        if (_selectedMedia != null &&
                            _selectedMediaType == 'image')
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedMedia!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _selectedMedia = null;
                                  _selectedMediaType = null;
                                }),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (_selectedFeeling != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Chip(
                              label: Text(_selectedFeeling!),
                              avatar: Icon(
                                _feelings.firstWhere(
                                  (f) => f['label'] == _selectedFeeling,
                                )['icon'],
                                color: _feelings.firstWhere(
                                  (f) => f['label'] == _selectedFeeling,
                                )['color'],
                              ),
                              onDeleted: () =>
                                  setState(() => _selectedFeeling = null),
                            ),
                          ),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _isPostingAnnouncement ? null : _pickMedia,
                      icon: const Icon(Icons.photo),
                      label: const Text('Photo'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _isPostingAnnouncement ? null : _pickFeeling,
                      icon: const Icon(Icons.emoji_emotions),
                      label: const Text('Feeling'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isPostingAnnouncement
                          ? null
                          : _postAnnouncement,
                      child: _isPostingAnnouncement
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _announcementBodyController.dispose();
    _selectedMedia = null;
    _selectedFeeling = null;
    super.dispose();
  }

  Widget _buildAccountTile(BuildContext context, Account account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(account.name),
        subtitle: Text(
          '${account.role}${account.userType != null ? ' • ${account.userType}' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Remove user',
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            await AccountStorage.instance.removeAccount(account.email);
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(content: Text('Removed ${account.name}')),
            );
            setState(() {
              _reloadAccounts();
            });
          },
        ),
      ),
    );
  }
}
