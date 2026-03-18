import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/account_storage.dart';
import '../../services/notification_storage.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // signup-specific state
  String _signUpRole = 'User'; // User, Librarian, Admin
  String _signUpCategory =
      'Student'; // for regular users: Student/Faculty/Visitor

  // toggles between sign in and sign up
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

    // register
    final account = Account(
      email: email,
      password: password,
      name: _nameController.text.trim(),
      role: _signUpRole,
      userType: _signUpRole == 'User' ? _signUpCategory : null,
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

    // Notify admins when a new account is created.
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

    // when returned, reset form and ensure sign-in mode
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    setState(() {
      _isSignIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // no appbar on login; show logo instead
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // meaning subtitle above the logo
              const Text(
                'Research and Information Search Assistant',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.blueAccent),
              ),
              const SizedBox(height: 8),
              // app logo at top (slightly smaller)
              Image.asset('assets/Risa_logo.png', height: 78),
              const SizedBox(height: 24),
              // toggle between sign in / sign up
              ToggleButtons(
                isSelected: [_isSignIn, !_isSignIn],
                onPressed: (index) {
                  // clear controllers when switching modes so values don't carry over
                  _emailController.clear();
                  _passwordController.clear();
                  _nameController.clear();
                  // reset signup selectors
                  _signUpRole = 'User';
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
              // fields and button animated when toggling
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Column(
                  key: ValueKey<bool>(_isSignIn),
                  children: [
                    if (!_isSignIn) ...[
                      Align(
                        alignment: Alignment.center,
                        child: CustomTextField(
                          controller: _nameController,
                          labelText: 'Full Name',
                          width: kFormElementWidth,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please enter full name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: kFormElementWidth,
                          child: DropdownButtonFormField<String>(
                            initialValue: _signUpRole,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                            ),
                            items: ['User', 'Librarian', 'Admin']
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _signUpRole = v;
                                  // if role changes away from regular user,
                                  // reset category to default
                                  if (_signUpRole != 'User') {
                                    _signUpCategory = 'Student';
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      if (_signUpRole == 'User') ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
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
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                    Align(
                      alignment: Alignment.center,
                      child: CustomTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        width: kFormElementWidth,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: CustomTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        width: kFormElementWidth,
                        obscureText: true, // toggle handled inside widget
                        validator: (v) {
                          if (v == null || v.length < 6) {
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
                        child: TextButton(
                          onPressed: _goToForgotPassword,
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else
                      const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.center,
                      child: CustomButton(
                        label: _isSignIn ? 'Login' : 'Register',
                        icon: Icon(
                          _isSignIn ? Icons.login : Icons.app_registration,
                        ),
                        onPressed: _attemptLogin,
                        fullWidth: false,
                        outlined: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
