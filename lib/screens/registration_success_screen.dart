import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/pwd_theme.dart';
import '../widgets/pwd_widgets.dart';
import 'citizen_dashboard_screen.dart';
import 'officer_dashboard_screen.dart';

class RegistrationSuccessScreen extends StatefulWidget {
  const RegistrationSuccessScreen({
    required this.name,
    required this.isOfficer,
    super.key,
  });

  final String name;
  final bool isOfficer;

  @override
  State<RegistrationSuccessScreen> createState() =>
      _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState
    extends State<RegistrationSuccessScreen> {
  Timer? _timer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Show the success message, then open the dashboard.
    _timer = Timer(
      const Duration(seconds: 3),
      _openDashboard,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openDashboard() {
    // Prevent the timer and button from opening two dashboards.
    if (!mounted || _hasNavigated) {
      return;
    }

    _hasNavigated = true;
    _timer?.cancel();

    final Widget dashboard = widget.isOfficer
        ? const OfficerDashboardScreen()
        : const CitizenDashboardScreen();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => dashboard,
      ),

      // Back cannot return to registration or sign-in.
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PwdPage(
      title: 'Registration successful',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(
                        Icons.check_rounded,
                        size: 50,
                        color: PwdColors.statusGreen,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'You have successfully registered!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: PwdColors.navy,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome, ${widget.name}.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Opening your dashboard...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: PwdColors.muted,
                      ),
                    ),
                    const SizedBox(height: 26),
                    PwdButton(
                      'Go to dashboard',
                      icon: Icons.arrow_forward,
                      onPressed: _openDashboard,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}