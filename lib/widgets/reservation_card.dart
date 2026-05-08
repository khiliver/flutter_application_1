import 'package:flutter/material.dart';

import '../models/reservation.dart';

class ReservationCard extends StatelessWidget {
  final String title;
  final ReservationType type;
  final DateTime createdAt;
  final ReservationStatus status;
  final List<Widget> actions;
  final String adminMessage;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? requesterName;

  const ReservationCard({
    super.key,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.status,
    this.requesterName,
    this.actions = const [],
    this.adminMessage = '',
    this.startTime,
    this.endTime,
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
                  if (requesterName != null &&
                      requesterName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Requested by: ${requesterName!}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(_subtitle),
                  if (adminMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Message:',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            adminMessage,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (startTime != null && endTime != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Timeslot: ${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')} - ${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
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
