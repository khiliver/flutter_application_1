import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../services/account_storage.dart';
import '../../services/notification_storage.dart';
import 'auth_form_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _courseController = TextEditingController();
  final _collegeController = TextEditingController();
  final _departmentController = TextEditingController();
  final _formKey = GlobalKey<ShadFormState>();
  final _picker = ImagePicker();

  String _signUpCategory = 'Student';
  String _signUpRole = 'User';
  String _signUpGender = 'Male';
  String? _signUpAvatarPath;
  bool _canCreateSuperAdmin = false;
  bool _isSignIn = true;
  bool _obscurePassword = true;

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
    _refreshSuperAdminAvailability();
  }

  Future<void> _refreshSuperAdminAvailability() async {
    final canCreate = await AccountStorage.instance.canCreateSuperAdmin();
    if (!mounted) return;
    setState(() {
      _canCreateSuperAdmin = canCreate;
      if (!_canCreateSuperAdmin && _signUpRole.toLowerCase() == 'super admin') {
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
    _collegeController.clear();
    _departmentController.clear();
    _signUpCategory = 'Student';
    _signUpRole = 'User';
    _signUpAvatarPath = null;
    _signUpGender = 'Male';
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

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          '/main',
          arguments: {
            'email': account.email,
            'name': account.name,
            'role': account.role,
            if (account.userType != null) 'userType': account.userType!,
            if (account.avatarPath != null) 'avatarPath': account.avatarPath!,
          },
        );
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
            message: 'A Super Admin account already exists.',
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
    _collegeController.clear();
    _departmentController.clear();
    _signUpAvatarPath = null;
    _signUpGender = 'Male';
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
    _collegeController.clear();
    _departmentController.clear();
    _signUpAvatarPath = null;
    _signUpGender = 'Male';
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
    _collegeController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: AuthFormCard(
                  formKey: _formKey,
                  isSignIn: _isSignIn,
                  obscurePassword: _obscurePassword,
                  canCreateSuperAdmin: _canCreateSuperAdmin,
                  signUpCategory: _signUpCategory,
                  signUpRole: _signUpRole,
                  signUpGender: _signUpGender,
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
                      }
                    });
                  },
                  onCategoryChanged: (value) {
                    setState(() {
                      _signUpCategory = value;
                      if (_signUpCategory.toLowerCase() != 'student') {
                        _courseController.clear();
                      }
                      if (_signUpCategory.toLowerCase() == 'user') {
                        _collegeController.clear();
                        _departmentController.clear();
                      }
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
