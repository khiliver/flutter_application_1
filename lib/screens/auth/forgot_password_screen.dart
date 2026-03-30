import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/account_storage.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  Future<void> _sendReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

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

    setState(() {
      _isSending = true;
    });

    try {
      final account = await AccountStorage.instance.findByEmail(email);
      if (!mounted) return;

      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found for that email')),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password reset link sent')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send reset link: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
                  label: _isSending ? 'Sending...' : 'Send Reset Link',
                  onPressed: _isSending ? null : _sendReset,
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
