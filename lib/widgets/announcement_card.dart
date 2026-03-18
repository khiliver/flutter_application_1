// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/permission_storage.dart';

class AnnouncementCard extends StatelessWidget {
  final String? text;
  final String? imagePath;
  final String? feeling;

  const AnnouncementCard({super.key, this.text, this.imagePath, this.feeling});

  @override
  Widget build(BuildContext context) {
    final hasText = text != null && text!.trim().isNotEmpty;
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;
    final hasFeeling = feeling != null && feeling!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasText)
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: _linkifiedTextSpans(text!, context),
                ),
              ),
            if (hasImage) ...[
              if (hasText) const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: const Text('Image is no longer available.'),
                    );
                  },
                ),
              ),
            ],
            if (hasFeeling) ...[
              if (hasText || hasImage) const SizedBox(height: 12),
              Chip(label: Text(feeling!)),
            ],
            if (!hasText && !hasImage && !hasFeeling) const Text('No content.'),
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
