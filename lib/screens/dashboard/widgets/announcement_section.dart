import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AnnouncementSection extends StatelessWidget {
  const AnnouncementSection({
    super.key,
    required this.bodyController,
    required this.isPostingAnnouncement,
    required this.selectedMedia,
    required this.selectedMediaType,
    required this.selectedFeeling,
    required this.feelings,
    required this.onPickMedia,
    required this.onPickFeeling,
    required this.onPost,
    required this.onRemoveMedia,
    required this.onRemoveFeeling,
  });

  final TextEditingController bodyController;
  final bool isPostingAnnouncement;
  final File? selectedMedia;
  final String? selectedMediaType;
  final String? selectedFeeling;
  final List<Map<String, dynamic>> feelings;
  final VoidCallback onPickMedia;
  final VoidCallback onPickFeeling;
  final VoidCallback onPost;
  final VoidCallback onRemoveMedia;
  final VoidCallback onRemoveFeeling;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShadCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 18, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShadInput(
                        controller: bodyController,
                        maxLines: 1,
                        placeholder: const Text("What's on your mind?"),
                      ),
                    ),
                  ],
                ),
                if (selectedMedia != null || selectedFeeling != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        if (selectedMedia != null &&
                            selectedMediaType == 'image')
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  selectedMedia!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              GestureDetector(
                                onTap: onRemoveMedia,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (selectedFeeling != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Chip(
                              label: Text(selectedFeeling!),
                              avatar: Icon(
                                _iconFor(selectedFeeling!, feelings),
                                color: _colorFor(selectedFeeling!, feelings),
                              ),
                              onDeleted: onRemoveFeeling,
                            ),
                          ),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                Row(
                  children: [
                    ShadButton.outline(
                      onPressed: isPostingAnnouncement ? null : onPickMedia,
                      leading: const Icon(Icons.photo),
                      child: const Text('Photo'),
                    ),
                    const SizedBox(width: 8),
                    ShadButton.outline(
                      onPressed: isPostingAnnouncement ? null : onPickFeeling,
                      leading: const Icon(Icons.emoji_emotions),
                      child: const Text('Feeling'),
                    ),
                    const Spacer(),
                    ShadButton(
                      onPressed: isPostingAnnouncement ? null : onPost,
                      child: isPostingAnnouncement
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(String feeling, List<Map<String, dynamic>> options) {
    final match = options.firstWhere((option) => option['label'] == feeling);
    return match['icon'] as IconData;
  }

  Color _colorFor(String feeling, List<Map<String, dynamic>> options) {
    final match = options.firstWhere((option) => option['label'] == feeling);
    return match['color'] as Color;
  }
}
