import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants.dart';
import '../../widgets/app_header.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _birthdateController = TextEditingController();
  String _gender = 'Male';
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final initialName = args?['name'] ?? 'John Appleseed';
    final initialEmail = args?['email'] ?? 'john@example.com';
    _nameController = TextEditingController(text: initialName);
    _emailController = TextEditingController(text: initialEmail);
    _isInitialized = true;
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(
        context,
      ).pop({'name': _nameController.text, 'email': _emailController.text});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ShadForm(
          key: _formKey,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: kFormElementWidth + 80,
              ),
              child: ShadCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: kFormElementWidth,
                      ),
                      child: ShadInputFormField(
                        controller: _nameController,
                        placeholder: const Text('Name'),
                        validator: (v) {
                          if (v.isEmpty) return 'Enter name';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: kFormElementWidth,
                      ),
                      child: ShadInputFormField(
                        controller: _emailController,
                        placeholder: const Text('Email'),
                        validator: (v) {
                          if (v.isEmpty) return 'Enter email';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: kFormElementWidth,
                      ),
                      child: ShadInput(
                        controller: _birthdateController,
                        placeholder: const Text('Birthdate'),
                        readOnly: true,
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(1990),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            _birthdateController.text = date
                                .toLocal()
                                .toString()
                                .split(' ')[0];
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: kFormElementWidth,
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: ['Male', 'Female', 'Other']
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          if (v != null) _gender = v;
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.center,
                      child: ShadButton.outline(
                        onPressed: _save,
                        leading: const Icon(Icons.save),
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
