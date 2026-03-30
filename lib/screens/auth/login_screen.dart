import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants.dart';
import '../../services/account_storage.dart';
import '../../services/notification_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<ShadFormState>();

  String _signUpCategory = 'Student';
  String _signUpRole = 'User';
  bool _canCreateSuperAdmin = false;
  bool _isSignIn = true;
  bool _obscurePassword = true;

  List<String> get _signUpRoleOptions =>
      _canCreateSuperAdmin ? const ['User', 'Super Admin'] : const ['User'];

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
        name: _nameController.text.trim(),
        role: _signUpRole,
        userType: isUserRole ? _signUpCategory : null,
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

    // ignore: unnecessary_cast
    final Account account = createdAccount as Account;

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
    _nameController.clear();
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
    _nameController.clear();
    _obscurePassword = true;
    setState(() {
      _isSignIn = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ShadForm(
          key: _formKey,
          child: Center(
            child: ShadCard(
              width: kFormElementWidth + 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Research and Information Search Assistant',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 8),
                  Image.asset('assets/Risa_logo.png', height: 78),
                  const SizedBox(height: 24),
                  ToggleButtons(
                    isSelected: [_isSignIn, !_isSignIn],
                    onPressed: (index) {
                      _emailController.clear();
                      _passwordController.clear();
                      _nameController.clear();
                      _signUpCategory = 'Student';
                      _signUpRole = 'User';
                      _obscurePassword = true;
                      setState(() {
                        _isSignIn = index == 0;
                      });
                      if (index == 1) {
                        _refreshSuperAdminAvailability();
                      }
                    },
                    selectedColor: Colors.white,
                    fillColor: Colors.blue,
                    borderColor: Colors.blue,
                    selectedBorderColor: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Sign In'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Sign Up'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Column(
                      key: ValueKey<bool>(_isSignIn),
                      children: [
                        if (!_isSignIn) ...[
                          SizedBox(
                            width: kFormElementWidth,
                            child: ShadInputFormField(
                              controller: _nameController,
                              placeholder: const Text('Full Name'),
                              validator: (v) {
                                if (v.trim().isEmpty) {
                                  return 'Please enter full name';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: kFormElementWidth,
                            child: DropdownButtonFormField<String>(
                              initialValue: _signUpRole,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                              ),
                              items: _signUpRoleOptions
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _signUpRole = v;
                                    if (_signUpRole.toLowerCase() != 'user') {
                                      _signUpCategory = 'Student';
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_signUpRole.toLowerCase() == 'user') ...[
                            SizedBox(
                              width: kFormElementWidth,
                              child: DropdownButtonFormField<String>(
                                initialValue: _signUpCategory,
                                decoration: const InputDecoration(
                                  labelText: 'User Type',
                                ),
                                items: ['Student', 'Faculty', 'Visitor']
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(u),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _signUpCategory = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                        SizedBox(
                          width: kFormElementWidth,
                          child: ShadInputFormField(
                            controller: _emailController,
                            placeholder: const Text('Email'),
                            validator: (v) {
                              if (v.trim().isEmpty) {
                                return 'Please enter email';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: kFormElementWidth,
                          child: Stack(
                            children: [
                              ShadInputFormField(
                                controller: _passwordController,
                                placeholder: const Text('Password'),
                                obscureText: _obscurePassword,
                                validator: (v) {
                                  final password = v.trim();
                                  if (password.isEmpty) {
                                    return 'Please enter password';
                                  }
                                  if (!_isSignIn && password.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isSignIn) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ShadButton.link(
                              onPressed: _goToForgotPassword,
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else
                          const SizedBox(height: 24),
                        ShadButton.outline(
                          onPressed: _attemptLogin,
                          leading: Icon(
                            _isSignIn ? Icons.login : Icons.app_registration,
                          ),
                          child: Text(_isSignIn ? 'Login' : 'Register'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
