import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../services/account_storage.dart';
import '../../services/notification_storage.dart';
import 'auth_form_card.dart';

class _SavedLoginProfile {
  final String email;
  final String password;
  final String name;

  const _SavedLoginProfile({
    required this.email,
    required this.password,
    required this.name,
  });

  String get displayName => name.trim().isEmpty ? email : name;

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'name': name,
  };

  factory _SavedLoginProfile.fromJson(Map<String, dynamic> json) {
    return _SavedLoginProfile(
      email: (json['email'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _kSavedLoginEmailKey = 'saved_login_email_v1';
  static const _kSavedLoginPasswordKey = 'saved_login_password_v1';
  static const _kSavedLoginNameKey = 'saved_login_name_v1';
  static const _genderOptions = [
    'Male',
    'Female',
    'Cisgender',
    'Transgender',
    'Gender Queer',
    'Non-Binary',
    'Prefer not to say',
  ];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _courseController = TextEditingController();
  final _schoolIdController = TextEditingController();
  final _collegeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _addressController = TextEditingController();
  final _institutionOrSchoolController = TextEditingController();
  final _formKey = GlobalKey<ShadFormState>();
  final _picker = ImagePicker();

  String _signUpCategory = 'Student';
  String _signUpNonBuType = 'Student';
  String _signUpPersonelType = 'Faculty';
  String _signUpRole = 'User';
  String _signUpGender = 'Prefer not to say';
  String? _signUpAvatarPath;
  bool _canCreateSuperAdmin = false;
  bool _isSignIn = true;
  bool _obscurePassword = true;
  String? _savedLoginEmail;
  String? _savedLoginPassword;
  String? _savedLoginName;
  bool _showManualSignIn = false;
  bool _isQuickLoginInProgress = false;

  String get _normalizedSignUpGender {
    return _genderOptions.contains(_signUpGender)
        ? _signUpGender
        : 'Prefer not to say';
  }

  String get _composedName {
    final parts = [
      _firstNameController.text.trim(),
      _middleNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(' ');
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _refreshSuperAdminAvailability();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kSavedLoginEmailKey);
    final savedPassword = prefs.getString(_kSavedLoginPasswordKey);
    final savedName = prefs.getString(_kSavedLoginNameKey);
    if (!mounted) return;
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _savedLoginEmail = savedEmail;
        _savedLoginPassword = savedPassword;
        _savedLoginName = savedName;
      });
    }
  }

  Future<void> _saveCredentials({
    required Account account,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedLoginEmailKey, account.email);
    await prefs.setString(_kSavedLoginPasswordKey, password);
    await prefs.setString(_kSavedLoginNameKey, account.name);
    if (!mounted) return;
    setState(() {
      _savedLoginEmail = account.email;
      _savedLoginPassword = password;
      _savedLoginName = account.name;
    });
  }

  Future<void> _clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSavedLoginEmailKey);
    await prefs.remove(_kSavedLoginPasswordKey);
    await prefs.remove(_kSavedLoginNameKey);
    if (!mounted) return;
    setState(() {
      _savedLoginEmail = null;
      _savedLoginPassword = null;
      _savedLoginName = null;
    });
  }

  Future<bool> _promptSavePassword() async {
    if (!mounted) return false;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save password?'),
        content: const Text('Do you want to save your password now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return shouldSave ?? false;
  }

  bool get _hasSavedLogin {
    return (_savedLoginEmail?.trim().isNotEmpty ?? false) &&
        (_savedLoginPassword?.trim().isNotEmpty ?? false);
  }

  Future<void> _goToMain(Account account) async {
    final normalizedRole = account.role.toLowerCase() == 'super admin'
        ? 'Over All Admin'
        : account.role;
    if (!mounted) return;
    await Navigator.of(context).pushReplacementNamed(
      '/main',
      arguments: {
        'email': account.email,
        'name': account.name,
        'role': normalizedRole,
        if (account.userType != null) 'userType': account.userType!,
        if (account.avatarPath != null) 'avatarPath': account.avatarPath!,
      },
    );
  }

  Future<void> _continueWithSavedProfile() async {
    final savedEmail = _savedLoginEmail?.trim() ?? '';
    final savedPassword = _savedLoginPassword ?? '';
    if (savedEmail.isEmpty || savedPassword.isEmpty) return;

    if (!AccountStorage.instance.isReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Firebase is not initialized. Please check your Google Services setup.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isQuickLoginInProgress = true;
    });

    try {
      final authenticated = await AccountStorage.instance.authenticate(
        savedEmail,
        savedPassword,
      );
      if (!authenticated) {
        await _clearSavedCredentials();
        if (!mounted) return;
        setState(() {
          _showManualSignIn = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved login expired. Please sign in.')),
        );
        return;
      }

      final account = await AccountStorage.instance.findByEmail(savedEmail);
      if (account == null) {
        await _clearSavedCredentials();
        if (!mounted) return;
        setState(() {
          _showManualSignIn = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved account not found. Please sign in.')),
        );
        return;
      }

      await _goToMain(account);
    } finally {
      if (mounted) {
        setState(() {
          _isQuickLoginInProgress = false;
        });
      }
    }
  }

  Future<void> _refreshSuperAdminAvailability() async {
    final canCreate = await AccountStorage.instance.canCreateSuperAdmin();
    if (!mounted) return;
    setState(() {
      _canCreateSuperAdmin = canCreate;
      if (!_canCreateSuperAdmin &&
          _signUpRole.toLowerCase() == 'over all admin') {
        _signUpRole = 'User';
      }
    });
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSignUpAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (file == null || !mounted) return;
    setState(() {
      _signUpAvatarPath = file.path;
    });
  }

  void _resetSignUpFields() {
    _emailController.clear();
    _passwordController.clear();
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _contactNumberController.clear();
    _birthdateController.clear();
    _courseController.clear();
    _schoolIdController.clear();
    _collegeController.clear();
    _departmentController.clear();
    _addressController.clear();
    _institutionOrSchoolController.clear();
    _signUpCategory = 'Student';
    _signUpNonBuType = 'Student';
    _signUpPersonelType = 'Faculty';
    _signUpRole = 'User';
    _signUpAvatarPath = null;
    _signUpGender = 'Prefer not to say';
    _obscurePassword = true;
  }

  Future<void> _attemptLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!AccountStorage.instance.isReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Firebase is not initialized. Please check your Google Services setup.',
          ),
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    Account? createdAccount;

    try {
      if (_isSignIn) {
        final authenticated = await AccountStorage.instance.authenticate(
          email,
          password,
        );
        if (!authenticated) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
          return;
        }

        final account = await AccountStorage.instance.findByEmail(email);
        if (account == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Account not found')));
          return;
        }

        final shouldSavePassword = await _promptSavePassword();
        if (shouldSavePassword) {
          await _saveCredentials(account: account, password: password);
        } else {
          await _clearSavedCredentials();
        }

        await _goToMain(account);
        return;
      }

      final isUserRole = _signUpRole.toLowerCase() == 'user';
      if (_birthdateController.text.trim().isEmpty) {
        await _showResultDialog(
          title: 'Registration failed',
          message: 'Please select your birthdate.',
        );
        return;
      }

      final existingAccount = await AccountStorage.instance.findByEmail(email);
      if (existingAccount != null) {
        await _showResultDialog(
          title: 'Registration failed',
          message: 'An account with that email already exists.',
        );
        return;
      }

      if (!isUserRole) {
        final canCreateSuperAdmin = await AccountStorage.instance
            .canCreateSuperAdmin();
        if (!canCreateSuperAdmin) {
          await _showResultDialog(
            title: 'Registration failed',
            message: 'An Over All Admin account already exists.',
          );
          return;
        }
      }

      final account = Account(
        email: email,
        password: password,
        name: _composedName,
        role: _signUpRole,
        userType: isUserRole ? _signUpCategory : null,
        avatarPath: _signUpAvatarPath,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        birthdate: _birthdateController.text.trim(),
        gender: _signUpGender,
        course:
            _signUpRole.toLowerCase() == 'user' &&
                _signUpCategory.toLowerCase() == 'student'
            ? _courseController.text.trim()
            : null,
        schoolId:
            _signUpRole.toLowerCase() == 'user' &&
                _signUpCategory.toLowerCase() == 'student'
            ? _schoolIdController.text.trim()
            : null,
        college:
            _signUpRole.toLowerCase() == 'user' &&
                (_signUpCategory.toLowerCase() == 'student' ||
                    _signUpCategory.toLowerCase() == 'personel')
            ? _collegeController.text.trim()
            : null,
        department:
            _signUpRole.toLowerCase() == 'user' &&
                (_signUpCategory.toLowerCase() == 'student' ||
                    _signUpCategory.toLowerCase() == 'personel')
            ? _departmentController.text.trim()
            : null,
        personelType:
            _signUpRole.toLowerCase() == 'user' &&
                _signUpCategory.toLowerCase() == 'personel'
            ? _signUpPersonelType
            : null,
        nonBuType:
            _signUpRole.toLowerCase() == 'user' &&
                _signUpCategory.toLowerCase() == 'non-bu'
            ? _signUpNonBuType
            : null,
        address:
            _signUpRole.toLowerCase() == 'user' &&
                _signUpCategory.toLowerCase() == 'non-bu'
            ? _addressController.text.trim()
            : null,
        institutionOrSchool:
            _signUpRole.toLowerCase() == 'user' &&
                _signUpCategory.toLowerCase() == 'non-bu'
            ? _institutionOrSchoolController.text.trim()
            : null,
      );

      final wasAdded = await AccountStorage.instance.addAccount(account);
      if (!wasAdded) {
        await _showResultDialog(
          title: 'Registration failed',
          message: 'Could not create account. Please try again.',
        );
        return;
      }

      createdAccount = account;
    } catch (e) {
      await _showResultDialog(
        title: 'Registration failed',
        message: 'Signup failed: $e',
      );
      return;
    }

    final Account account = createdAccount;

    await NotificationStorage.instance.addNotification(
      AppNotification(
        title: 'New user registered',
        subtitle:
            '${account.name} (${account.role}${account.userType != null ? ' - ${account.userType}' : ''})',
        createdAt: DateTime.now(),
      ),
    );

    await _showResultDialog(
      title: 'Registration successful',
      message: 'Account created for ${account.email}. You can now sign in.',
    );

    if (!mounted) return;
    _passwordController.clear();
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _contactNumberController.clear();
    _birthdateController.clear();
    _courseController.clear();
    _schoolIdController.clear();
    _collegeController.clear();
    _departmentController.clear();
    _addressController.clear();
    _institutionOrSchoolController.clear();
    _signUpAvatarPath = null;
    _signUpGender = 'Prefer not to say';
    _signUpNonBuType = 'Student';
    _signUpPersonelType = 'Faculty';
    _obscurePassword = true;
    setState(() {
      _isSignIn = true;
    });
  }

  Future<void> _goToForgotPassword() async {
    await Navigator.of(context).pushNamed('/forgotPassword');
    if (!mounted) return;

    _emailController.clear();
    _passwordController.clear();
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _contactNumberController.clear();
    _birthdateController.clear();
    _courseController.clear();
    _schoolIdController.clear();
    _collegeController.clear();
    _departmentController.clear();
    _addressController.clear();
    _institutionOrSchoolController.clear();
    _signUpAvatarPath = null;
    _signUpGender = 'Prefer not to say';
    _signUpNonBuType = 'Student';
    _signUpPersonelType = 'Faculty';
    _obscurePassword = true;
    setState(() {
      _isSignIn = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _birthdateController.dispose();
    _courseController.dispose();
    _schoolIdController.dispose();
    _collegeController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    _institutionOrSchoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSignIn && _hasSavedLogin && !_showManualSignIn) {
      final displayName = (_savedLoginName?.trim().isNotEmpty ?? false)
          ? _savedLoginName!
          : _savedLoginEmail!;
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: SizedBox(
                  height: constraints.maxHeight - 36,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: _isQuickLoginInProgress
                                  ? null
                                  : _continueWithSavedProfile,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: Image.asset(
                                        'assets/AskRisaavatarwelcomeback.png',
                                        width: 62,
                                        height: 62,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const SizedBox(
                                                  width: 62,
                                                  height: 62,
                                                  child: Icon(
                                                    Icons.support_agent,
                                                    size: 36,
                                                    color: Color(0xFF2D73E0),
                                                  ),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 31,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    _isQuickLoginInProgress
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.chevron_right_rounded,
                                            color: Color(0xFF4B5563),
                                            size: 30,
                                          ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF0F2F5),
                              side: const BorderSide(color: Color(0xFFD0D5DD)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isQuickLoginInProgress
                                ? null
                                : () {
                                    setState(() {
                                      _showManualSignIn = true;
                                    });
                                  },
                            child: const Text(
                              'Use another profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: AuthFormCard(
                  formKey: _formKey,
                  isSignIn: _isSignIn,
                  obscurePassword: _obscurePassword,
                  canCreateSuperAdmin: _canCreateSuperAdmin,
                  signUpCategory: _signUpCategory,
                  signUpNonBuType: _signUpNonBuType,
                  signUpPersonelType: _signUpPersonelType,
                  signUpRole: _signUpRole,
                  signUpGender: _normalizedSignUpGender,
                  signUpAvatarPath: _signUpAvatarPath,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  firstNameController: _firstNameController,
                  middleNameController: _middleNameController,
                  lastNameController: _lastNameController,
                  contactNumberController: _contactNumberController,
                  birthdateController: _birthdateController,
                  courseController: _courseController,
                  collegeController: _collegeController,
                  departmentController: _departmentController,
                  schoolIdController: _schoolIdController,
                  addressController: _addressController,
                  institutionOrSchoolController: _institutionOrSchoolController,
                  onForgotPassword: _goToForgotPassword,
                  onToggleObscurePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  onPickAvatar: _pickSignUpAvatar,
                  onModeChanged: (index) {
                    _resetSignUpFields();
                    setState(() {
                      _isSignIn = index == 0;
                    });
                    if (index == 1) {
                      _refreshSuperAdminAvailability();
                    }
                  },
                  onRoleChanged: (value) {
                    setState(() {
                      _signUpRole = value;
                      if (_signUpRole.toLowerCase() != 'user') {
                        _signUpCategory = 'Student';
                        _signUpNonBuType = 'Student';
                        _signUpPersonelType = 'Faculty';
                        _courseController.clear();
                        _schoolIdController.clear();
                        _collegeController.clear();
                        _departmentController.clear();
                        _addressController.clear();
                        _institutionOrSchoolController.clear();
                      }
                    });
                  },
                  onCategoryChanged: (value) {
                    setState(() {
                      _signUpCategory = value;
                      if (_signUpCategory.toLowerCase() != 'student') {
                        _courseController.clear();
                        _schoolIdController.clear();
                      }
                      if (_signUpCategory.toLowerCase() != 'personel') {
                        _signUpPersonelType = 'Faculty';
                        _collegeController.clear();
                        _departmentController.clear();
                      }
                      if (_signUpCategory.toLowerCase() != 'non-bu') {
                        _signUpNonBuType = 'Student';
                        _addressController.clear();
                        _institutionOrSchoolController.clear();
                      }
                    });
                  },
                  onNonBuTypeChanged: (value) {
                    setState(() {
                      _signUpNonBuType = value;
                    });
                  },
                  onPersonelTypeChanged: (value) {
                    setState(() {
                      _signUpPersonelType = value;
                    });
                  },
                  onGenderChanged: (value) {
                    setState(() {
                      _signUpGender = value;
                    });
                  },
                  onSubmit: _attemptLogin,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
