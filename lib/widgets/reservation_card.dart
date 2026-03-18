import 'package:flutter/material.dart';

import '../models/reservation.dart';

class ReservationCard extends StatelessWidget {
  final String title;
  final ReservationType type;
  final DateTime createdAt;
  final ReservationStatus status;
  final List<Widget> actions;

  const ReservationCard({
    super.key,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.status,
    this.actions = const [],
  });

  String get _subtitle {
    final formattedDate =
        '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    return '${type.label} • $formattedDate • ${status.label}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(type.icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(_subtitle),
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
