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
  late final TextEditingController _emailController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _contactNumberController;
  final _birthdateController = TextEditingController();
  final _courseController = TextEditingController();
  final _schoolIdController = TextEditingController();
  final _collegeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _institutionOrSchoolController = TextEditingController();
  final _picker = ImagePicker();

  static const _genderOptions = [
    'Male',
    'Female',
    'Cisgender',
    'Transgender',
    'Gender Queer',
    'Non-Binary',
    'Prefer not to say',
  ];

  static const _userTypeOptions = ['Student', 'Personel', 'Non-BU'];
  static const _personelTypeOptions = ['Faculty', 'Non-teaching Personel'];
  static const _nonBuTypeOptions = [
    'Student',
    'Non-academic Based',
    'Out of School Youth',
  ];

  late String _initialEmail;
  String _role = 'User';
  String _userType = 'Student';
  String _personelType = 'Faculty';
  String _nonBuType = 'Student';
  String _gender = 'Prefer not to say';
  String? _avatarPath;
  bool _isSaving = false;
  bool _isInitialized = false;
  bool _isLoadingAccount = false;

  bool get _isUserRole => _role.trim().toLowerCase() == 'user';

  bool get _requiresCourseDetails =>
      _isUserRole && _userType.toLowerCase() == 'student';

  bool get _requiresDepartmentDetails =>
      _isUserRole && _userType.toLowerCase() == 'personel';

  bool get _requiresNonBuDetails =>
      _isUserRole && _userType.toLowerCase() == 'non-bu';

  String get _composedName {
    final parts = [
      _firstNameController.text.trim(),
      _middleNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(' ');
  }

  InputDecoration _inputDecoration({required String hint, String? label}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2D73E0), width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF1F4FA),
      isDense: true,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? label,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: _inputDecoration(
        hint: hint,
        label: label,
      ).copyWith(suffixIcon: suffixIcon),
    );
  }

  void _applyUserTypeDefaults(String value) {
    _userType = value;
    if (_userType.toLowerCase() != 'student') {
      _courseController.clear();
      _schoolIdController.clear();
    }
    if (_userType.toLowerCase() != 'personel') {
      _personelType = 'Faculty';
      _collegeController.clear();
      _departmentController.clear();
      _employeeIdController.clear();
    }
    if (_userType.toLowerCase() != 'non-bu') {
      _nonBuType = 'Student';
      _addressController.clear();
      _institutionOrSchoolController.clear();
    }
  }

  Future<void> _loadLatestAccountDetails() async {
    if (_initialEmail.trim().isEmpty) return;

    setState(() {
      _isLoadingAccount = true;
    });

    try {
      final account = await AccountStorage.instance.findByEmail(_initialEmail);
      if (!mounted || account == null) {
        return;
      }

      _emailController.text = account.email;
      _firstNameController.text = account.firstName ?? '';
      _middleNameController.text = account.middleName ?? '';
      _lastNameController.text = account.lastName ?? '';
      _contactNumberController.text = account.contactNumber ?? '';
      _birthdateController.text = account.birthdate ?? '';
      _courseController.text = account.course ?? '';
      _schoolIdController.text = account.schoolId ?? '';
      _collegeController.text = account.college ?? '';
      _departmentController.text = account.department ?? '';
      _employeeIdController.text = account.employeeId ?? '';
      _addressController.text = account.address ?? '';
      _institutionOrSchoolController.text = account.institutionOrSchool ?? '';

      setState(() {
        _initialEmail = account.email;
        _role = account.role;
        _avatarPath = account.avatarPath;

        final normalizedUserType = (account.userType ?? 'Student').trim();
        _userType = _userTypeOptions.contains(normalizedUserType)
            ? normalizedUserType
            : 'Student';

        final normalizedGender = (account.gender ?? 'Prefer not to say').trim();
        _gender = _genderOptions.contains(normalizedGender)
            ? normalizedGender
            : 'Prefer not to say';

        final normalizedPersonelType = (account.personelType ?? 'Faculty')
            .trim();
        _personelType = _personelTypeOptions.contains(normalizedPersonelType)
            ? normalizedPersonelType
            : 'Faculty';

        final normalizedNonBuType = (account.nonBuType ?? 'Student').trim();
        _nonBuType = _nonBuTypeOptions.contains(normalizedNonBuType)
            ? normalizedNonBuType
            : 'Student';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load latest account data.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAccount = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    final args = rawArgs is Map ? rawArgs : const <String, dynamic>{};

    final initialEmail = args['email'] ?? 'john@example.com';
    final initialFirstName = args['firstName']?.toString() ?? '';
    final initialMiddleName = args['middleName']?.toString() ?? '';
    final initialLastName = args['lastName']?.toString() ?? '';
    _initialEmail = initialEmail.toString();
    _avatarPath = args['avatarPath']?.toString();

    _emailController = TextEditingController(text: _initialEmail);
    _firstNameController = TextEditingController(text: initialFirstName);
    _middleNameController = TextEditingController(text: initialMiddleName);
    _lastNameController = TextEditingController(text: initialLastName);
    _contactNumberController = TextEditingController(
      text: args['contactNumber']?.toString() ?? '',
    );

    final roleArg = args['role']?.toString() ?? '';
    if (roleArg.trim().isNotEmpty) {
      _role = roleArg.trim();
    }

    final userTypeArg = args['userType']?.toString() ?? '';
    if (_userTypeOptions.contains(userTypeArg.trim())) {
      _userType = userTypeArg.trim();
    }

    _isInitialized = true;
    _loadLatestAccountDetails();
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

    final normalizedEmail = _emailController.text.trim().toLowerCase();
    final composedName = _composedName;
    if (composedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your name fields.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await AccountStorage.instance.updateAccountProfile(
        email: _initialEmail,
        updatedEmail: normalizedEmail,
        name: composedName,
        avatarPath: _avatarPath,
        userType: _isUserRole ? _userType : null,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        birthdate: _birthdateController.text.trim(),
        gender: _gender,
        course: _requiresCourseDetails ? _courseController.text.trim() : null,
        college: _requiresDepartmentDetails
            ? _collegeController.text.trim()
            : null,
        department: _requiresDepartmentDetails
            ? _departmentController.text.trim()
            : null,
        schoolId: _requiresCourseDetails
            ? _schoolIdController.text.trim()
            : null,
        employeeId: _requiresDepartmentDetails
            ? _employeeIdController.text.trim()
            : null,
        personelType: _requiresDepartmentDetails ? _personelType : null,
        nonBuType: _requiresNonBuDetails ? _nonBuType : null,
        address: _requiresNonBuDetails ? _addressController.text.trim() : null,
        institutionOrSchool: _requiresNonBuDetails
            ? _institutionOrSchoolController.text.trim()
            : null,
      );

      if (!updated) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save profile. That email may already be in use.',
            ),
          ),
        );
        return;
      }

      _initialEmail = normalizedEmail;
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
      'name': composedName,
      'email': normalizedEmail,
      'avatarPath': _avatarPath,
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _birthdateController.dispose();
    _courseController.dispose();
    _schoolIdController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _employeeIdController.dispose();
    _addressController.dispose();
    _institutionOrSchoolController.dispose();
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
                    if (_isLoadingAccount)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(),
                      ),
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
                      child: _buildTextField(
                        controller: _firstNameController,
                        hint: 'First name',
                        validator: (v) {
                          if ((v?.trim() ?? '').isEmpty) {
                            return 'Please enter first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: kFormElementWidth,
                      ),
                      child: _buildTextField(
                        controller: _middleNameController,
                        hint: 'Middle name (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: kFormElementWidth,
                      ),
                      child: _buildTextField(
                        controller: _lastNameController,
                        hint: 'Last name',
                        validator: (v) {
                          if ((v?.trim() ?? '').isEmpty) {
                            return 'Please enter last name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: kFormElementWidth,
                      ),
                      child: _buildTextField(
                        controller: _contactNumberController,
                        hint: 'Contact number',
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if ((v?.trim() ?? '').isEmpty) {
                            return 'Please enter contact number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: kFormElementWidth,
                      ),
                      child: _buildTextField(
                        controller: _birthdateController,
                        hint: 'Birthdate',
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            _birthdateController.text =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          }
                        },
                        suffixIcon: const Icon(
                          Icons.calendar_month_outlined,
                          size: 20,
                        ),
                        validator: (v) {
                          if ((v?.trim() ?? '').isEmpty) {
                            return 'Please select birthdate';
                          }
                          return null;
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
                        decoration: _inputDecoration(
                          hint: 'Gender',
                          label: 'Gender',
                        ),
                        items: _genderOptions
                            .map(
                              (gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _gender = v;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(
                        maxWidth: kFormElementWidth,
                      ),
                      child: _buildTextField(
                        controller: _emailController,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Please enter email';
                          if (!value.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                    ),
                    if (_isUserRole) ...[
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: kFormElementWidth,
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _userType,
                          decoration: _inputDecoration(
                            hint: 'User type',
                            label: 'User Type',
                          ),
                          items: _userTypeOptions
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _applyUserTypeDefaults(v);
                            });
                          },
                        ),
                      ),
                    ],
                    if (_requiresNonBuDetails) ...[
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: kFormElementWidth,
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _nonBuType,
                          decoration: _inputDecoration(
                            hint: 'Non-BU type',
                            label: 'Non-BU Type',
                          ),
                          items: _nonBuTypeOptions
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _nonBuType = v;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: kFormElementWidth,
                        ),
                        child: _buildTextField(
                          controller: _addressController,
                          hint: 'Address',
                          validator: (v) {
                            if ((v?.trim() ?? '').isEmpty) {
                              return 'Please enter address';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: kFormElementWidth,
                        ),
                        child: _buildTextField(
                          controller: _institutionOrSchoolController,
                          hint: 'Institution or school',
                          validator: (v) {
                            if ((v?.trim() ?? '').isEmpty) {
                              return 'Please enter institution or school';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                    if (_requiresCourseDetails) ...[
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: kFormElementWidth,
                        ),
                        child: _buildTextField(
                          controller: _courseController,
                          hint: 'Course',
                          validator: (v) {
                            if ((v?.trim() ?? '').isEmpty) {
                              return 'Please enter course';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: kFormElementWidth,
                        ),
                        child: _buildTextField(
                          controller: _schoolIdController,
                          hint: 'School ID',
                          validator: (v) {
                            if ((v?.trim() ?? '').isEmpty) {
                              return 'Please enter school ID';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                    if (_requiresDepartmentDetails) ...[
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: kFormElementWidth,
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _personelType,
                          decoration: _inputDecoration(
                            hint: 'Personel type',
                            label: 'Personel Type',
                          ),
                          items: _personelTypeOptions
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _personelType = v;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: kFormElementWidth,
                        ),
                        child: _buildTextField(
                          controller: _collegeController,
                          hint: _personelType == 'Faculty'
                              ? 'College'
                              : 'Unit/Auxiliary',
                          validator: (v) {
                            if ((v?.trim() ?? '').isEmpty) {
                              final fieldName = _personelType == 'Faculty'
                                  ? 'college'
                                  : 'unit/auxiliary';
                              return 'Please enter $fieldName';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: kFormElementWidth,
                        ),
                        child: _buildTextField(
                          controller: _departmentController,
                          hint: _personelType == 'Faculty'
                              ? 'Department'
                              : 'Offices',
                          validator: (v) {
                            if ((v?.trim() ?? '').isEmpty) {
                              final fieldName = _personelType == 'Faculty'
                                  ? 'department'
                                  : 'offices';
                              return 'Please enter $fieldName';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(
                          maxWidth: kFormElementWidth,
                        ),
                        child: _buildTextField(
                          controller: _employeeIdController,
                          hint: 'Employee ID',
                          validator: (v) {
                            if ((v?.trim() ?? '').isEmpty) {
                              return 'Please enter employee ID';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
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
