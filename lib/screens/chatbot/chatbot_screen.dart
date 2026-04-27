import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../widgets/app_header.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  bool _isOpening = false;

  bool get _isFacebookConfigured => kFacebookPageHandle != 'YOUR_PAGE_HANDLE';

  Future<void> _refreshScreen() {
    if (mounted) {
      setState(() {});
    }
    return Future<void>.value();
  }

  Future<void> _openUniversityLibraryPage() async {
    if (_isOpening) return;
    setState(() {
      _isOpening = true;
    });

    final opened = await launchUrl(
      Uri.parse(kUniversityLibraryFacebookUrl),
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) return;
    setState(() {
      _isOpening = false;
    });

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open University Library page. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _openBuEastCampusLibraryPage() async {
    if (_isOpening) return;

    setState(() {
      _isOpening = true;
    });

    final pageUri = Uri.parse(kFacebookPageUrl);
    final opened = await launchUrl(pageUri, mode: LaunchMode.externalApplication);

    if (!mounted) return;
    setState(() {
      _isOpening = false;
    });

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open BU East Campus Library page. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
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
                                ElevatedButton.icon(
                                  onPressed:
                                      !_isFacebookConfigured || _isOpening
                                      ? null
                                      : _openBuEastCampusLibraryPage,
                                  icon: _isOpening
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.local_library_outlined),
                                  label: Text(
                                    _isOpening ? 'Opening...' : 'BU East Campus Library',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed:
                                      _isOpening
                                      ? null
                                      : _openUniversityLibraryPage,
                                  icon: const Icon(Icons.local_library_outlined),
                                  label: const Text('University Library'),
                                ),
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
