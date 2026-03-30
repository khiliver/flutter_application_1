import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class BookTile extends StatelessWidget {
  const BookTile({super.key, required this.book});

  final Map<String, Object> book;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        padding: const EdgeInsets.all(12),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(book['title'] as String),
          trailing: Text('${book['count']} reservations'),
        ),
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.data, required this.labelKey});

  final List<Map<String, Object>> data;
  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: data
          .map(
            (entry) => SizedBox(
              width: 140,
              child: ShadCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry[labelKey] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry['count']} users (students/faculty/staff/visitors)',
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
