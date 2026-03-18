import 'package:flutter/material.dart';
import 'custom_button.dart';

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final VoidCallback onReserve;

  const BookCard({
    super.key,
    required this.title,
    required this.author,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(author),
                ],
              ),
            ),
            CustomButton(
              label: 'Reserve',
              icon: const Icon(Icons.book),
              onPressed: onReserve,
            ),
          ],
        ),
      ),
    );
  }
}
