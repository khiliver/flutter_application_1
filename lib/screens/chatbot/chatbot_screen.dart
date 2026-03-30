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

  Future<void> _openFacebookChat() async {
    if (_isOpening) return;

    setState(() {
      _isOpening = true;
    });

    final messengerUri = Uri.parse(kFacebookMessengerUrl);
    final pageUri = Uri.parse(kFacebookPageUrl);

    var opened = await launchUrl(
      messengerUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      opened = await launchUrl(pageUri, mode: LaunchMode.externalApplication);
    }

    if (!mounted) return;
    setState(() {
      _isOpening = false;
    });

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Facebook chat. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: Center(
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
                    const Icon(Icons.forum_outlined, size: 44),
                    const SizedBox(height: 12),
                    const Text(
                      'Chat With Us on Facebook',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isFacebookConfigured
                          ? 'You will be redirected to our Facebook Page chat.'
                          : 'Facebook chat is not configured yet. Set kFacebookPageHandle in lib/constants.dart.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: !_isFacebookConfigured || _isOpening
                          ? null
                          : _openFacebookChat,
                      icon: _isOpening
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.open_in_new),
                      label: Text(
                        _isOpening ? 'Opening...' : 'Open Facebook Chat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
