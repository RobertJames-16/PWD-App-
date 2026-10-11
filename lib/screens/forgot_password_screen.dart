import 'package:flutter/material.dart';

import '../widgets/pwd_widgets.dart';

// This is a front-end demo. Firebase must be connected before it can send or verify OTPs.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _showNewPassword = false;

  @override
  void dispose() {
    // Dispose controllers when leaving this screen to release their resources.
    _contactController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    // Stop if any field is empty or too short.
    if (!_formKey.currentState!.validate()) return;

    // Demo only: no OTP is really sent or checked yet.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo only: connect Firebase to reset your password.'),
      ),
    );

    // Return to the sign-in screen.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PwdPage(
      title: 'Forgot password',
      back: () => Navigator.pop(context),
      child: Center(
        // Scroll and max width keep the form usable on small and large screens.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.key_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Forgot Password?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your registered mobile number or email, then enter the OTP and a new password.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _contactController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number or email',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your mobile number or email'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: '4-digit OTP (demo)',
                      prefixIcon: Icon(Icons.password),
                      counterText: '',
                    ),
                    validator: (value) => value == null || value.trim().length != 4
                        ? 'Enter the 4-digit OTP'
                        : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      // Real resend behavior needs an OTP service such as Firebase.
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo only: OTP sending is not connected.')),
                      ),
                      child: const Text('Resend code'),
                    ),
                  ),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_showNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _showNewPassword ? 'Hide password' : 'Show password',
                        onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                        icon: Icon(_showNewPassword ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                    validator: (value) => value == null || value.length < 4
                        ? 'Use at least 4 characters'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  PwdButton('Reset password', onPressed: _resetPassword),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to login'),
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