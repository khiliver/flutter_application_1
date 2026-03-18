import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';

class ProfileScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialRole;
  final String? initialUserType;

  const ProfileScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialRole,
    this.initialUserType,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _name;
  late String _email;
  String? _role;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _name = widget.initialName ?? 'John Appleseed';
    _email = widget.initialEmail ?? 'john@example.com';
    _role = widget.initialRole;
    _userType = widget.initialUserType;
  }

  void _signOut(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _editProfile() async {
    final result = await Navigator.of(
      context,
    ).pushNamed('/editProfile', arguments: {'name': _name, 'email': _email});
    if (result is Map<String, String>) {
      setState(() {
        _name = result['name'] ?? _name;
        _email = result['email'] ?? _email;
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
            'question': 'How do I reserve a book?',
            'answer':
                'Navigate to the Books section, select a book, and tap the "Reserve" button.',
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
                'About BU East Campus Library',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'BU East Campus Library (BUECL) is the official library hub serving the Bicol University East Campus community in Legazpi City.',
              ),
              SizedBox(height: 10),
              Text(
                'The East Campus library is located at the East Wing of the RS Building and supports learning and research for the Colleges of Engineering, Industrial Technology, and the Institute of Design and Architecture.',
              ),
              SizedBox(height: 10),
              Text(
                'In this app, reservation services are available for students, BU faculty/staff, and visitors from partner campuses or schools.',
              ),
              SizedBox(height: 16),
              Text(
                'Official Pages',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('Facebook: https://www.facebook.com/BUECL'),
              Text('Bicol University: https://www.bicol-u.edu.ph'),
              Text(
                'BU Library (East Campus): https://sites.google.com/bicol-u.edu.ph/buls/about-us/libraries/east-campus',
              ),
              SizedBox(height: 12),
              Text(
                'Note: Details are based on publicly available BU and BUECL pages and may be updated by the university.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
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
            leading: const Icon(Icons.book),
            title: const Text('Books'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('FAQ'),
            onTap: _showFAQ,
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
    );
  }
}
