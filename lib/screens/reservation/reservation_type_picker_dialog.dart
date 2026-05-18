import 'package:flutter/material.dart';

import '../../models/reservation.dart';

/// Dialog to pick a reservation type.
class ReservationTypePickerDialog extends StatelessWidget {
  const ReservationTypePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ReservationType.values
            .where((type) => type != ReservationType.collection)
            .map((type) {
              final actionLabel = switch (type) {
                ReservationType.scannedCopy => 'Document Delivery',
                _ => 'Reserve ${type.label}',
              };
              return ListTile(
                leading: Icon(type.icon),
                title: Text(actionLabel),
                onTap: () => Navigator.of(context).pop(type),
              );
            })
            .toList(),
      ),
    );
  }
}
