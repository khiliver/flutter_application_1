import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/ejournal_storage.dart';
import '../../widgets/app_header.dart';

class EJournalScreen extends StatefulWidget {
  final String? userRole;
  final String? userType;

  const EJournalScreen({super.key, this.userRole, this.userType});

  @override
  State<EJournalScreen> createState() => _EJournalScreenState();
}

class _EJournalScreenState extends State<EJournalScreen> {
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  List<EJournalEntry> _entries = [];

  String _normalizeRole(String? role) {
    return (role ?? '').trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  }

  bool get _canManageEntries {
    final normalizedRole = _normalizeRole(widget.userRole);
    return normalizedRole == 'admin' ||
        normalizedRole == 'librarian' ||
        normalizedRole == 'overalladmin' ||
        normalizedRole == 'superadmin';
  }

  bool get _canViewEntries {
    if (_canManageEntries) return true;
    final type = (widget.userType ?? '').toLowerCase();
    return type == 'student' || type == 'non-bu';
  }

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('www.')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final entries = await EJournalStorage.instance.getEntries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load e-journal entries.')),
      );
    }
  }

  Future<void> _openEntry(EJournalEntry entry) async {
    final normalized = _normalizeUrl(entry.link);
    final uri = Uri.tryParse(normalized);
    if (uri == null || !_isValidUrl(normalized)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The saved link is invalid.')),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
  }

  Future<void> _showEntryDialog({EJournalEntry? entry}) async {
    _titleController.text = entry?.title ?? '';
    _linkController.text = entry?.link ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(entry == null ? 'Add Facility' : 'Edit Facility'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Journal of Engineering',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Link',
                    hintText: 'https://example.com/journal',
                  ),
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final title = _titleController.text.trim();
    final normalizedLink = _normalizeUrl(_linkController.text);

    if (title.isEmpty || normalizedLink.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and link are required.')),
      );
      return;
    }

    if (!_isValidUrl(normalizedLink)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (entry == null) {
        await EJournalStorage.instance.addEntry(
          title: title,
          link: normalizedLink,
        );
      } else {
        await EJournalStorage.instance.updateEntry(
          id: entry.id,
          title: title,
          link: normalizedLink,
        );
      }
      await _loadEntries();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save e-journal entry.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteEntry(EJournalEntry entry) async {
    try {
      await EJournalStorage.instance.deleteEntry(entry.id);
      await _loadEntries();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete e-journal entry.')),
      );
    }
  }

  Widget _buildRefreshableBody() {
    if (!_canViewEntries) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(
            child: Text(
              'Facilities are available for students and Non-BU users.',
            ),
          ),
        ],
      );
    }

    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: Text('No facilities added yet.')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(entry.title),
            subtitle: Text(entry.link),
            onTap: () => _openEntry(entry),
            trailing: _canManageEntries
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEntryDialog(entry: entry);
                      } else if (value == 'delete') {
                        _deleteEntry(entry);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(showBack: true),
      floatingActionButton: _canManageEntries
          ? FloatingActionButton(
              onPressed: _isSaving ? null : () => _showEntryDialog(),
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: _buildRefreshableBody(),
      ),
    );
  }
}
