import 'package:flutter/material.dart';

import '../theme/pwd_theme.dart';
import '../widgets/pwd_widgets.dart';
import 'auth_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background colours come from your theme.
        decoration: const BoxDecoration(
          gradient: PwdColors.pageGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                // Prevents the card becoming too wide on Chrome.
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Your exported emblem image.
                        Center(
                          child: Image.asset(
                            'assets/images/emblem.png',
                            height: 140,
                            width: 140,
                            fit: BoxFit.contain,
                            semanticLabel: 'Emblem',
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'PWD Portal',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: PwdColors.navy,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 10),

                        const Text(
                          'Public Works Department',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: PwdColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text(
                          'Report an issue. Follow its progress.\n'
                          'Help build a better neighbourhood.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: PwdColors.muted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Opens the sign-in screen.
                        PwdButton(
                          'Get started',
                          icon: Icons.arrow_forward,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AuthScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}