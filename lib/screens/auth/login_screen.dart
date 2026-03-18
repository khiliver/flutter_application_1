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
  bool _isSignIn = true;

  Future<void> _attemptLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

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
        },
      );
      return;
    }

    final account = Account(
      email: email,
      password: password,
      name: _nameController.text.trim(),
      role: 'User',
      userType: _signUpCategory,
    );

    final wasAdded = await AccountStorage.instance.addAccount(account);
    if (!wasAdded) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An account with that email already exists'),
        ),
      );
      return;
    }

    await NotificationStorage.instance.addNotification(
      AppNotification(
        title: 'New user registered',
        subtitle:
            '${account.name} (${account.role}${account.userType != null ? ' - ${account.userType}' : ''})',
        createdAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/main',
      arguments: {
        'email': account.email,
        'name': account.name,
        'role': account.role,
        if (account.userType != null) 'userType': account.userType!,
      },
    );
  }

  Future<void> _goToForgotPassword() async {
    await Navigator.of(context).pushNamed('/forgotPassword');
    if (!mounted) return;

    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
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
                      setState(() {
                        _isSignIn = index == 0;
                      });
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
                                if (v.isEmpty) {
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
                        SizedBox(
                          width: kFormElementWidth,
                          child: ShadInputFormField(
                            controller: _emailController,
                            placeholder: const Text('Email'),
                            validator: (v) {
                              if (v.isEmpty) {
                                return 'Please enter email';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: kFormElementWidth,
                          child: ShadInputFormField(
                            controller: _passwordController,
                            placeholder: const Text('Password'),
                            obscureText: true,
                            validator: (v) {
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
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
