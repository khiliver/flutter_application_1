import 'dart:io';
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
  final String? avatarPath;

  const _SavedLoginProfile({
    required this.email,
    required this.password,
    required this.name,
    this.avatarPath,
  });

  String get displayName => name.trim().isEmpty ? email : name;

  String? get normalizedAvatarPath {
    final value = avatarPath?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'name': name,
    if (normalizedAvatarPath != null) 'avatarPath': normalizedAvatarPath,
  };

  factory _SavedLoginProfile.fromJson(Map<String, dynamic> json) {
    final rawAvatarPath = json['avatarPath'];
    return _SavedLoginProfile(
      email: (json['email'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatarPath: rawAvatarPath?.toString(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _kSavedLoginProfilesKey = 'saved_login_profiles_v2';
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
  final _employeeIdController = TextEditingController();
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
  List<_SavedLoginProfile> _savedLoginProfiles = const [];
  bool _showManualSignIn = false;
  bool _isQuickLoginInProgress = false;
  String? _quickLoginInProgressEmail;

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

  ImageProvider<Object>? _resolveProfileImage(String? avatarPath) {
    final normalizedPath = avatarPath?.trim() ?? '';
    if (normalizedPath.isEmpty) {
      return null;
    }

    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return NetworkImage(normalizedPath);
    }

    if (normalizedPath.startsWith('assets/')) {
      return AssetImage(normalizedPath);
    }

    final file = File(normalizedPath);
    if (file.existsSync()) {
      return FileImage(file);
    }

    return null;
  }

  bool _areSavedProfilesEqual(
    List<_SavedLoginProfile> a,
    List<_SavedLoginProfile> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if (left.email != right.email ||
          left.password != right.password ||
          left.name != right.name ||
          left.normalizedAvatarPath != right.normalizedAvatarPath) {
        return false;
      }
    }

    return true;
  }

  Future<List<_SavedLoginProfile>> _hydrateSavedProfiles(
    List<_SavedLoginProfile> profiles,
  ) async {
    if (!AccountStorage.instance.isReady || profiles.isEmpty) {
      return profiles;
    }

    final hydrated = <_SavedLoginProfile>[];
    for (final profile in profiles) {
      try {
        final account = await AccountStorage.instance.findByEmail(
          profile.email,
        );
        if (account == null) {
          hydrated.add(profile);
          continue;
        }

        hydrated.add(
          _SavedLoginProfile(
            email: profile.email,
            password: profile.password,
            name: account.name.trim().isEmpty
                ? profile.name
                : account.name.trim(),
            avatarPath: (account.avatarPath?.trim().isNotEmpty ?? false)
                ? account.avatarPath!.trim()
                : profile.normalizedAvatarPath,
          ),
        );
      } catch (_) {
        hydrated.add(profile);
      }
    }

    return hydrated;
  }

  List<_SavedLoginProfile> _decodeSavedProfiles(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                _SavedLoginProfile.fromJson(Map<String, dynamic>.from(item)),
          )
          .where(
            (profile) =>
                profile.email.trim().isNotEmpty &&
                profile.password.trim().isNotEmpty,
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persistSavedProfiles(List<_SavedLoginProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();

    if (profiles.isEmpty) {
      await prefs.remove(_kSavedLoginProfilesKey);
      await prefs.remove(_kSavedLoginEmailKey);
      await prefs.remove(_kSavedLoginPasswordKey);
      await prefs.remove(_kSavedLoginNameKey);
      return;
    }

    final encodedProfiles = jsonEncode(
      profiles.map((profile) => profile.toJson()).toList(growable: false),
    );
    await prefs.setString(_kSavedLoginProfilesKey, encodedProfiles);

    // Keep legacy keys aligned so previous app versions can still read the latest account.
    final latestProfile = profiles.first;
    await prefs.setString(_kSavedLoginEmailKey, latestProfile.email);
    await prefs.setString(_kSavedLoginPasswordKey, latestProfile.password);
    await prefs.setString(_kSavedLoginNameKey, latestProfile.name);
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedProfiles = prefs.getString(_kSavedLoginProfilesKey);

    List<_SavedLoginProfile> profiles = const [];
    if (encodedProfiles != null && encodedProfiles.trim().isNotEmpty) {
      profiles = _decodeSavedProfiles(encodedProfiles);
    }

    if (profiles.isEmpty) {
      final savedEmail = prefs.getString(_kSavedLoginEmailKey);
      final savedPassword = prefs.getString(_kSavedLoginPasswordKey);
      final savedName = prefs.getString(_kSavedLoginNameKey);
      if ((savedEmail?.trim().isNotEmpty ?? false) &&
          (savedPassword?.trim().isNotEmpty ?? false)) {
        profiles = [
          _SavedLoginProfile(
            email: savedEmail!.trim(),
            password: savedPassword!,
            name: (savedName ?? '').trim(),
          ),
        ];
        await _persistSavedProfiles(profiles);
      }
    }

    final hydratedProfiles = await _hydrateSavedProfiles(profiles);
    if (!_areSavedProfilesEqual(profiles, hydratedProfiles)) {
      await _persistSavedProfiles(hydratedProfiles);
    }
    profiles = hydratedProfiles;

    if (!mounted) return;
    setState(() {
      _savedLoginProfiles = profiles;
    });
  }

  Future<void> _saveCredentials({
    required Account account,
    required String password,
  }) async {
    final normalizedEmail = account.email.trim().toLowerCase();
    final updatedProfiles = [
      ..._savedLoginProfiles.where(
        (profile) => profile.email.trim().toLowerCase() != normalizedEmail,
      ),
    ];

    updatedProfiles.insert(
      0,
      _SavedLoginProfile(
        email: account.email.trim(),
        password: password,
        name: account.name.trim(),
        avatarPath: account.avatarPath?.trim(),
      ),
    );

    final profilesToPersist = updatedProfiles.take(6).toList(growable: false);
    await _persistSavedProfiles(profilesToPersist);

    if (!mounted) return;
    setState(() {
      _savedLoginProfiles = profilesToPersist;
      _showManualSignIn = false;
    });
  }

  Future<void> _removeSavedCredentialsForEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final remainingProfiles = _savedLoginProfiles
        .where(
          (profile) => profile.email.trim().toLowerCase() != normalizedEmail,
        )
        .toList(growable: false);

    await _persistSavedProfiles(remainingProfiles);

    if (!mounted) return;
    setState(() {
      _savedLoginProfiles = remainingProfiles;
      if (remainingProfiles.isEmpty) {
        _showManualSignIn = true;
      }
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
    return _savedLoginProfiles.isNotEmpty;
  }

  bool _isCredentialAlreadySaved(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    return _savedLoginProfiles.any(
      (profile) =>
          profile.email.trim().toLowerCase() == normalizedEmail &&
          profile.password == password,
    );
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

  Future<void> _continueWithSavedProfile(_SavedLoginProfile profile) async {
    final savedEmail = profile.email.trim();
    final savedPassword = profile.password;
    final normalizedSavedEmail = savedEmail.toLowerCase();
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
      _quickLoginInProgressEmail = normalizedSavedEmail;
    });

    try {
      final account = await _continueWithLegacySavedProfile(
        savedEmail,
        savedPassword,
      );
      if (account == null) {
        await _removeSavedCredentialsForEmail(savedEmail);
        if (!mounted) return;
        setState(() {
          _showManualSignIn = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved account not found. Please sign in.'),
          ),
        );
        return;
      }

      await _goToMain(account);
    } finally {
      if (mounted) {
        setState(() {
          _isQuickLoginInProgress = false;
          _quickLoginInProgressEmail = null;
        });
      }
    }
  }

  Future<Account?> _continueWithLegacySavedProfile(
    String savedEmail,
    String savedPassword,
  ) async {
    final authenticated = await AccountStorage.instance.authenticate(
      savedEmail,
      savedPassword,
    );
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved login expired. Please sign in.')),
        );
      }
      return null;
    }

    return AccountStorage.instance.findByEmail(savedEmail);
  }

  Future<void> _refreshSuperAdminAvailability() async {
    // Only check if Firebase is initialized
    if (!AccountStorage.instance.isReady) {
      return;
    }

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
    _employeeIdController.clear();
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
        final account = await _continueWithLegacySavedProfile(email, password);
        if (account == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
          return;
        }

        final alreadySaved = _isCredentialAlreadySaved(email, password);
        if (alreadySaved) {
          await _saveCredentials(account: account, password: password);
        } else {
          final shouldSavePassword = await _promptSavePassword();
          if (shouldSavePassword) {
            await _saveCredentials(account: account, password: password);
          } else {
            await _removeSavedCredentialsForEmail(email);
          }
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
        employeeId:
            _signUpRole.toLowerCase() == 'user' &&
                _signUpCategory.toLowerCase() == 'personel'
            ? _employeeIdController.text.trim()
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
          message: 'Could not create the account. Please try again.',
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
        type: AppNotificationType.account,
      ),
    );

    // Show success message and return to sign in
    if (mounted) {
      await _showResultDialog(
        title: 'Registration successful',
        message: 'Account created successfully! You can now sign in.',
      );
    }

    // Clear fields and go back to sign in
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
    if (mounted) {
      setState(() {
        _isSignIn = true;
      });
    }
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
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: SizedBox(
                          height: constraints.maxHeight - 36,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFDFD),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFDCE2EA),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      height: 190,
                                      color: Colors.transparent,
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        'assets/AskRisaavatarwelcomeback.png',
                                        fit: BoxFit.scaleDown,
                                        filterQuality: FilterQuality.high,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.support_agent,
                                                size: 72,
                                                color: Color(0xFF1E40AF),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Welcome back',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Select an account with saved password.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF475467),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: _savedLoginProfiles.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final profile =
                                            _savedLoginProfiles[index];
                                        final normalizedEmail = profile.email
                                            .trim()
                                            .toLowerCase();
                                        final isCurrentProfile =
                                            _isQuickLoginInProgress &&
                                            normalizedEmail ==
                                                _quickLoginInProgressEmail;
                                        final initialSource =
                                            profile.displayName.trim().isEmpty
                                            ? profile.email.trim()
                                            : profile.displayName.trim();
                                        final initial = initialSource.isEmpty
                                            ? '?'
                                            : initialSource
                                                  .substring(0, 1)
                                                  .toUpperCase();
                                        final profileImage =
                                            _resolveProfileImage(
                                              profile.normalizedAvatarPath,
                                            );

                                        return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            onTap: _isQuickLoginInProgress
                                                ? null
                                                : () =>
                                                      _continueWithSavedProfile(
                                                        profile,
                                                      ),
                                            child: Ink(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isCurrentProfile
                                                      ? const Color(0xFF2D73E0)
                                                      : const Color(0xFFD0D5DD),
                                                  width: isCurrentProfile
                                                      ? 1.4
                                                      : 1,
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 23,
                                                      backgroundColor:
                                                          profileImage != null
                                                          ? Colors.transparent
                                                          : const Color(
                                                              0xFFE3EDFF,
                                                            ),
                                                      foregroundColor:
                                                          const Color(
                                                            0xFF1E40AF,
                                                          ),
                                                      foregroundImage:
                                                          profileImage,
                                                      child: Text(
                                                        initial,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            profile.displayName,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color(
                                                                    0xFF111827,
                                                                  ),
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            profile.email,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Color(
                                                                    0xFF6B7280,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (isCurrentProfile)
                                                      const SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2.2,
                                                            ),
                                                      )
                                                    else ...[
                                                      IconButton(
                                                        tooltip:
                                                            'Remove saved account',
                                                        onPressed:
                                                            _isQuickLoginInProgress
                                                            ? null
                                                            : () =>
                                                                  _removeSavedCredentialsForEmail(
                                                                    profile
                                                                        .email,
                                                                  ),
                                                        icon: const Icon(
                                                          Icons
                                                              .remove_circle_outline_rounded,
                                                          size: 22,
                                                          color: Color(
                                                            0xFF6B7280,
                                                          ),
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons
                                                            .chevron_right_rounded,
                                                        color: Color(
                                                          0xFF4B5563,
                                                        ),
                                                        size: 30,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF8FAFD),
                                      side: const BorderSide(
                                        color: Color(0xFFD0D5DD),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: _isQuickLoginInProgress
                                        ? null
                                        : () {
                                            setState(() {
                                              _showManualSignIn = true;
                                            });
                                          },
                                    icon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF1F2937),
                                    ),
                                    label: const Text(
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
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Opacity(
                opacity: 0.4,
                child: Text(
                  'Developed by Leenard A. Asejo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: !(_isSignIn && _showManualSignIn && _hasSavedLogin),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSignIn && _showManualSignIn && _hasSavedLogin) {
          setState(() {
            _showManualSignIn = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Stack(
          children: [
            SafeArea(
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
                        employeeIdController: _employeeIdController,
                        addressController: _addressController,
                        institutionOrSchoolController:
                            _institutionOrSchoolController,
                        onForgotPassword: _goToForgotPassword,
                        onBackPressed: () {
                          if (_isSignIn &&
                              _showManualSignIn &&
                              _hasSavedLogin) {
                            setState(() {
                              _showManualSignIn = false;
                            });
                            return;
                          }

                          if (!_isSignIn) {
                            _resetSignUpFields();
                            setState(() {
                              _isSignIn = true;
                            });
                            return;
                          }

                          Navigator.of(context).maybePop();
                        },
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
            Positioned(
              bottom: 16,
              right: 16,
              child: Opacity(
                opacity: 0.4,
                child: Text(
                  'Developed by Leenard A. Asejo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
