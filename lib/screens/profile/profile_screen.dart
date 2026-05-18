import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../services/account_storage.dart';
import '../../services/reservation_notification_helper.dart';
import '../../widgets/app_header.dart';

class ProfileScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialRole;
  final String? initialUserType;
  final String? initialAvatarPath;

  const ProfileScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialRole,
    this.initialUserType,
    this.initialAvatarPath,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _name;
  late String _email;
  String? _role;
  String? _userType;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName ?? 'John Appleseed';
    _email = widget.initialEmail ?? 'john@example.com';
    _role = widget.initialRole;
    _userType = widget.initialUserType;
    _avatarPath = widget.initialAvatarPath;
    _loadLatestProfile();
  }

  Future<void> _loadLatestProfile() async {
    if (_email.isEmpty) return;
    try {
      final account = await AccountStorage.instance.findByEmail(_email);
      if (!mounted || account == null) return;
      setState(() {
        _name = account.name;
        _email = account.email;
        _role = account.role;
        _userType = account.userType;
        _avatarPath = account.avatarPath;
      });
    } catch (_) {
      // Keep fallback values when remote profile load fails.
    }
  }

  void _signOut(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _openFeedbackForm() async {
    final uri = Uri.parse('http://tinyurl.com/BULS-CSMsurveyform');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the feedback form.')),
      );
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.of(context).pushNamed(
      '/editProfile',
      arguments: {
        'name': _name,
        'email': _email,
        'role': _role,
        'userType': _userType,
        'avatarPath': _avatarPath,
      },
    );
    if (result is Map) {
      setState(() {
        _name = result['name']?.toString() ?? _name;
        _email = result['email']?.toString() ?? _email;
        _avatarPath = result['avatarPath']?.toString();
      });
    }
  }

  void _showFAQ() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final List<Map<String, String>> faqs = [
          {
            'question': 'How do I reset my password?',
            'answer':
                'Go to the login screen, tap "Forgot Password?", and follow the instructions sent to your email.',
          },
          {
            'question': 'How can I contact support?',
            'answer':
                'You can contact support via the "Contact Us" section in the app or email ec-library@bicol-u.edu.ph.',
          },

          {
            'question': 'Can I update my profile information?',
            'answer':
                'Yes, tap on "Edit Profile" in your profile screen to update your information.',
          },
          {
            'question': 'What should I do if I find a bug?',
            'answer':
                'Please report bugs via the feedback form in the app or email us directly.',
          },
        ];

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      final faq = faqs[index];
                      return ExpansionTile(
                        title: Text(faq['question'] ?? ''),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(faq['answer'] ?? ''),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutUs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: const [
              Text(
                'About Bicol University Library System',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'The Bicol University Library serves as the central knowledge hub of Bicol University, providing students, faculty, and researchers with access to quality academic resources and information services. The library supports excellence in education, research, and community engagement through its diverse collection of print and digital materials.',
              ),
              SizedBox(height: 10),
              Text(
                'The library offers books, journals, research databases, e-library resources, and modern learning spaces designed to support academic and professional growth. As part of a multi-campus library system, it ensures accessible and user-centered services for the entire Bicol University community.',
              ),
              SizedBox(height: 10),
              Text(
                'With a commitment to innovation and lifelong learning, the Bicol University Library continues to evolve as a dynamic center for knowledge and discovery.',
              ),
              SizedBox(height: 16),
              Text(
                'For more details, visit our official website: sites.google.com/bicol-u.edu.ph/buls',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCollectionsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'List of Collection',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...kLibraryOptions.map((library) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: () async {
                      final driveUrl =
                          ReservationNotificationHelper.getCollectionDriveUrl(
                            library,
                          );
                      if (await canLaunchUrl(Uri.parse(driveUrl))) {
                        await launchUrl(
                          Uri.parse(driveUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open link for $library'),
                          ),
                        );
                      }
                    },
                    child: Text(library),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: RefreshIndicator(
        onRefresh: _loadLatestProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        _avatarPath != null && _avatarPath!.isNotEmpty
                        ? FileImage(File(_avatarPath!))
                        : null,
                    child: _avatarPath == null || _avatarPath!.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_email, style: const TextStyle(color: Colors.grey)),
                  if (_role != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Role: $_role',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  if (_userType != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Type: $_userType',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: _editProfile,
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('List of Collection'),
              onTap: _showCollectionsList,
            ),
            ListTile(
              leading: const Icon(Icons.question_answer),
              title: const Text('FAQ'),
              onTap: _showFAQ,
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              onTap: _openFeedbackForm,
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About Us'),
              onTap: _showAboutUs,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Sign Out'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}
