// ignore_for_file: use_build_context_synchronously

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/permission_storage.dart';

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: _linkifiedTextSpans(subtitle, context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _linkifiedTextSpans(String text, BuildContext context) {
    final urlRegExp = RegExp(
      r'((?:https?:\/\/|www\.)[\w\-]+(?:\.[\w\-]+)+(?:[\w\-\.,@?^=%&:/~\+#]*[\w\-@?^=%&/~\+#])?)',
      caseSensitive: false,
    );

    final spans = <TextSpan>[];
    var start = 0;

    for (final match in urlRegExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final url = text.substring(match.start, match.end);
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(_normalizeUrl(url));
              final currentContext = context;

              final allowed =
                  await PermissionStorage.instance.allowExternalLinks;
              if (!allowed) {
                final granted = await showDialog<bool>(
                  context: currentContext,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Open external link?'),
                      content: const Text(
                        'This app can open external links in another app. Do you want to allow this?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Allow'),
                        ),
                      ],
                    );
                  },
                );

                if (granted != true) {
                  return;
                }

                await PermissionStorage.instance.setAllowExternalLinks(true);
              }

              final messenger = ScaffoldMessenger.of(currentContext);

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Could not open link.')),
                );
              }
            },
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  String _normalizeUrl(String url) {
    if (url.startsWith('www.')) {
      return 'https://$url';
    }
    return url;
  }
}
