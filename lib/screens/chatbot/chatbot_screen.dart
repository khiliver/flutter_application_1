import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../widgets/app_header.dart';

class ChatbotScreen extends StatefulWidget {
  final VoidCallback? onProfilePressed;
  final VoidCallback? onLogoPressed;

  const ChatbotScreen({super.key, this.onProfilePressed, this.onLogoPressed});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  bool _isOpening = false;
  String _openingLibrary = '';

  bool get _isFacebookConfigured => kFacebookPageHandle != 'YOUR_PAGE_HANDLE';

  // Library contact information
  final List<({String name, String url})> _libraries = const [
    (
      name: 'BUCEILS Children and Highschool Library',
      url: kBuceailsChildrenLibraryFacebookUrl,
    ),
    (name: 'University Library', url: kUniversityLibraryFacebookUrl),
    (name: 'College of Law', url: kCollegeOfLawFacebookUrl),
    (name: 'Health and Science Library', url: kHealthScienceLibraryFacebookUrl),
    (name: 'East Campus', url: kEastCampusLibraryFacebookUrl),
    (name: 'Tabaco Campus', url: kTabacoCampusLibraryFacebookUrl),
    (name: 'Guinobatan Campus', url: kGuinoatanCampusLibraryFacebookUrl),
    (name: 'Polangui Campus', url: kPolanguiCampusLibraryFacebookUrl),
    (name: 'Gubat Campus', url: kGubatCampusLibraryFacebookUrl),
  ];

  Future<void> _refreshScreen() {
    if (mounted) {
      setState(() {});
    }
    return Future<void>.value();
  }

  Future<void> _openLibraryPage(String libraryName, String url) async {
    if (_isOpening) return;
    setState(() {
      _isOpening = true;
      _openingLibrary = libraryName;
    });

    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;
    setState(() {
      _isOpening = false;
      _openingLibrary = '';
    });

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $libraryName page. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        onProfilePressed: widget.onProfilePressed,
        onLogoPressed: widget.onLogoPressed,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshScreen,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 4),
                                const Text(
                                  'Library Contact',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._libraries.map((library) {
                                  final isLoadingThis =
                                      _isOpening &&
                                      _openingLibrary == library.name;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          !_isFacebookConfigured || _isOpening
                                          ? null
                                          : () => _openLibraryPage(
                                              library.name,
                                              library.url,
                                            ),
                                      icon: isLoadingThis
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.local_library_outlined,
                                            ),
                                      label: Text(
                                        isLoadingThis
                                            ? 'Opening...'
                                            : library.name,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
