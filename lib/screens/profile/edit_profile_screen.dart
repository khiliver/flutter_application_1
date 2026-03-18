import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/app_header.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _birthdateController = TextEditingController();
  String _gender = 'Male';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final initialName = args?['name'] ?? 'John Appleseed';
    final initialEmail = args?['email'] ?? 'john@example.com';
    _nameController = TextEditingController(text: initialName);
    _emailController = TextEditingController(text: initialEmail);
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(
        context,
      ).pop({'name': _nameController.text, 'email': _emailController.text});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(showBack: true, title: 'Edit Profile'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(
                width: kFormElementWidth,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter name' : null,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: kFormElementWidth,
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: kFormElementWidth,
                child: TextFormField(
                  controller: _birthdateController,
                  decoration: const InputDecoration(labelText: 'Birthdate'),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
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
              SizedBox(
                width: kFormElementWidth,
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    if (v != null) _gender = v;
                  }),
                ),
              ),
              const SizedBox(height: 24),
              // use custom button for consistent labels/styles
              Align(
                alignment: Alignment.center,
                child: CustomButton(
                  label: 'Submit',
                  icon: const Icon(Icons.save),
                  onPressed: _save,
                  fullWidth: false,
                  outlined: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
