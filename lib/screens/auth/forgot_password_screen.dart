import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _sendReset() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: wire up to your auth backend
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password reset link sent')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: kFormElementWidth,
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: kFormElementWidth,
                child: CustomButton(
                  label: 'Send Reset Link',
                  onPressed: _sendReset,
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
