import 'package:flutter/material.dart';

import '../../services/announcement_storage.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/app_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> _dummyAnnouncements = const [
    {
      'title': 'Welcome to RISA',
      'subtitle': 'Your research assistant is ready.',
    },
    {
      'title': 'Update',
      'subtitle': 'New books have been added to the library.',
    },
    {
      'title': 'Maintenance',
      'subtitle': 'System maintenance scheduled for tonight.',
    },
  ];

  bool _isLoading = true;
  List<Announcement> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
    });

    final announcements = await AnnouncementStorage.instance.getAnnouncements();

    if (!mounted) return;

    setState(() {
      _announcements = announcements;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: RefreshIndicator(
        onRefresh: _loadAnnouncements,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final allAnnouncements = [
      ..._announcements.map((a) => {'title': a.title, 'subtitle': a.body}),
      ..._dummyAnnouncements,
    ];

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _AnnouncementsHeaderDelegate(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                'Announcements',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        if (allAnnouncements.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No announcements yet.')),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = allAnnouncements[index];
              return AnnouncementCard(
                title: item['title']!,
                subtitle: item['subtitle']!,
              );
            }, childCount: allAnnouncements.length),
          ),
      ],
    );
  }
}

class _AnnouncementsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _AnnouncementsHeaderDelegate({required this.child});

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _AnnouncementsHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
