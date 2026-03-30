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
        children: ReservationType.values.map((type) {
          return ListTile(
            leading: Icon(type.icon),
            title: Text('Reserve ${type.label}'),
            onTap: () => Navigator.of(context).pop(type),
          );
        }).toList(),
      ),
    );
  }
}
