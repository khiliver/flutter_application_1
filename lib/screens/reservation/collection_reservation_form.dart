import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/reservation.dart';
import '../../services/account_storage.dart';
import 'reservation_form_user_info.dart';

/// Form for users to request a collection.
/// Collects: collection name, description, reason, and desired quantity.
class CollectionReservationForm extends StatefulWidget {
  final String? userEmail;
  final String? userName;
  final String? selectedLibrary;
  final Account? userAccount;

  const CollectionReservationForm({
    super.key,
    this.userEmail,
    this.userName,
    this.selectedLibrary,
    this.userAccount,
  });

  @override
  State<CollectionReservationForm> createState() =>
      _CollectionReservationFormState();
}

class _CollectionReservationFormState extends State<CollectionReservationForm> {
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final surnameController = TextEditingController();
  final schoolIdController = TextEditingController();
  final cellphoneController = TextEditingController();
  final collegeController = TextEditingController();
  final schoolOriginController = TextEditingController();

  String? errorText;
  final formKey = GlobalKey<ShadFormState>();

  @override
  void initState() {
    super.initState();

    final userInfo = ReservationFormUserInfo.fromAccount(
      widget.userAccount,
      fallbackEmail: widget.userEmail,
      fallbackName: widget.userName,
    );

    firstNameController.text = userInfo.firstName;
    middleNameController.text = userInfo.middleName;
    surnameController.text = userInfo.surname;
    schoolIdController.text = userInfo.schoolId;
    cellphoneController.text = userInfo.cellphone;
    collegeController.text = userInfo.college;
    schoolOriginController.text = userInfo.schoolOrigin;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    surnameController.dispose();
    schoolIdController.dispose();
    cellphoneController.dispose();
    collegeController.dispose();
    schoolOriginController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstName = firstNameController.text.trim();
    final middleName = middleNameController.text.trim();
    final surname = surnameController.text.trim();

    if (firstName.isEmpty || surname.isEmpty) {
      setState(() {
        errorText = 'Please provide at least first name and surname.';
      });
      return;
    }

    final baseUserInfo = ReservationFormUserInfo.fromAccount(
      widget.userAccount,
      fallbackEmail: widget.userEmail,
      fallbackName: widget.userName,
    );
    final fullNameParts = [
      firstName,
      middleName,
      surname,
    ].where((value) => value.isNotEmpty).toList();
    final requesterName = fullNameParts.join(' ').trim();

    try {
      Navigator.of(context).pop(
        ReservationItem(
          type: ReservationType.collection,
          title: 'Request List of Collection',
          createdAt: DateTime.now(),
          requesterEmail: baseUserInfo.requesterEmail,
          requesterName: requesterName.isEmpty
              ? baseUserInfo.requesterName
              : requesterName,
          firstName: firstName,
          middleName: middleName,
          surname: surname,
          schoolId: schoolIdController.text.trim(),
          cellphone: cellphoneController.text.trim(),
          college: collegeController.text.trim(),
          schoolOrigin: schoolOriginController.text.trim(),
          library: widget.selectedLibrary ?? '',
          service: 'Request List of Collection',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ReservationFormUserInfo.fromAccount(
      widget.userAccount,
      fallbackEmail: widget.userEmail,
      fallbackName: widget.userName,
    );

    return AlertDialog(
      title: const Text('Request List of Collection'),
      content: SingleChildScrollView(
        child: ShadCard(
          padding: const EdgeInsets.all(12),
          child: ShadForm(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Email: ${userInfo.requesterEmail}'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Account name: ${userInfo.requesterName}'),
                ),
                const SizedBox(height: 12),
                if ((widget.selectedLibrary ?? '').isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Library: ${widget.selectedLibrary}'),
                  ),
                  const SizedBox(height: 12),
                ],
                ShadInput(
                  controller: firstNameController,
                  placeholder: const Text('First name'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: middleNameController,
                  placeholder: const Text('Middle name (optional)'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: surnameController,
                  placeholder: const Text('Surname'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: schoolIdController,
                  placeholder: const Text('School ID (optional)'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: cellphoneController,
                  placeholder: const Text('Cellphone (optional)'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: collegeController,
                  placeholder: const Text('College (optional)'),
                ),
                const SizedBox(height: 12),
                ShadInput(
                  controller: schoolOriginController,
                  placeholder: const Text('From School (optional)'),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Reserve')),
      ],
    );
  }
}
