import 'package:flutter/material.dart';

import '../../services/announcement_storage.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/app_header.dart';

class HomeScreen extends StatefulWidget {
  final String? userEmail;
  final String? userName;
  final String? userRole;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onLogoPressed;

  const HomeScreen({
    super.key,
    this.userEmail,
    this.userName,
    this.userRole,
    this.onProfilePressed,
    this.onLogoPressed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  bool _canModifyAnnouncement(Announcement item) {
    return AnnouncementStorage.instance.canModifyAnnouncement(
      item,
      currentEmail: widget.userEmail,
      currentRole: widget.userRole,
    );
  }

  Future<void> _showAnnouncementActions(Announcement item) async {
    if (!_canModifyAnnouncement(item)) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'edit') {
      await _editAnnouncement(item);
    } else if (action == 'delete') {
      await _deleteAnnouncement(item);
    }
  }

  Future<void> _editAnnouncement(Announcement item) async {
    final controller = TextEditingController(text: item.body);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit announcement'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Announcement text',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await AnnouncementStorage.instance.updateAnnouncement(
      Announcement(
        id: item.id,
        title: item.title,
        body: controller.text.trim(),
        createdAt: item.createdAt,
        imagePath: item.imagePath,
        gifUrl: item.gifUrl,
        emoji: item.emoji,
        sticker: item.sticker,
        postedByEmail: item.postedByEmail,
        postedByName: item.postedByName,
        postedByRole: item.postedByRole,
      ),
    );

    await _loadAnnouncements();
  }

  Future<void> _deleteAnnouncement(Announcement item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete announcement?'),
          content: const Text('This announcement will be removed permanently.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || item.id == null || !mounted) return;

    await AnnouncementStorage.instance.deleteAnnouncement(item.id!);
    await _loadAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        onProfilePressed: widget.onProfilePressed,
        onLogoPressed: widget.onLogoPressed,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnnouncements,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
        if (_isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_announcements.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No announcements yet.')),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = _announcements[index];
              return AnnouncementCard(
                text: item.body,
                imagePath: item.imagePath,
                feeling: item.emoji,
                onLongPress: () => _showAnnouncementActions(item),
              );
            }, childCount: _announcements.length),
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
