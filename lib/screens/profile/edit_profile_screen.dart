import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants.dart';
import '../../services/account_storage.dart';
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
  late String _initialEmail;
  final _birthdateController = TextEditingController();
  final _picker = ImagePicker();
  String _gender = 'Male';
  String? _avatarPath;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is Map ? rawArgs : const <String, dynamic>{};
    final initialName = args['name'] ?? 'John Appleseed';
    final initialEmail = args['email'] ?? 'john@example.com';
    _initialEmail = initialEmail.toString();
    _avatarPath = args['avatarPath']?.toString();
    _nameController = TextEditingController(text: initialName.toString());
    _emailController = TextEditingController(text: _initialEmail);
    _isInitialized = true;
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (file == null || !mounted) return;
    setState(() {
      _avatarPath = file.path;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
    });

    try {
      await AccountStorage.instance.updateAccountProfile(
        email: _initialEmail,
        name: _nameController.text.trim(),
        avatarPath: _avatarPath,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save to cloud profile.')),
      );
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'avatarPath': _avatarPath,
    });
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
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundImage:
                                _avatarPath != null && _avatarPath!.isNotEmpty
                                ? FileImage(File(_avatarPath!))
                                : null,
                            child: _avatarPath == null || _avatarPath!.isEmpty
                                ? const Icon(Icons.person, size: 42)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          ShadButton.ghost(
                            onPressed: _pickAvatar,
                            leading: const Icon(Icons.photo_library),
                            child: const Text('Upload Avatar'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        onPressed: _isSaving ? null : _save,
                        leading: const Icon(Icons.save),
                        child: Text(_isSaving ? 'Saving...' : 'Submit'),
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
