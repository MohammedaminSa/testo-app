import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../widgets/gradient_button.dart';
import 'auth_layout.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final response = await AuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Supabase may require email confirmation. If a session was returned the
      // user is signed in immediately; otherwise they must confirm their email.
      if (response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created. Check your email to confirm.'),
          ),
        );
      }
      context.go('/');
    } on Exception {
      if (mounted) {
        setState(() => _error = 'Sign up failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      eyebrow: 'GCSE ACE',
      title: 'Create your account',
      subtitle: 'Free access to mock exams, past papers and AI explanations.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@school.edu',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Enter your email';
                  if (!email.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: 'At least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Show' : 'Hide',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                  ),
                ),
                validator: (value) {
                  final password = value ?? '';
                  if (password.isEmpty) return 'Enter a password';
                  if (password.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
            ],
          ),
        ),
        if (_error != null) AuthError(message: _error!),
        const SizedBox(height: 26),
        GradientButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : const Text('Create account'),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 22),
        GlassButton(
          onPressed: _submitting ? null : () => context.go('/signin'),
          icon: Icons.arrow_back_rounded,
          child: const Text('I already have an account'),
        ),
      ],
    );
  }
}
