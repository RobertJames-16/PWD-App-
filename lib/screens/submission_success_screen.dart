import 'package:flutter/material.dart';

import '../models/pwd_report.dart';
import '../theme/pwd_theme.dart';
import '../widgets/pwd_widgets.dart';
import 'citizen_dashboard_screen.dart';
import 'report_progress_screen.dart';

class SubmissionSuccessScreen extends StatelessWidget {
  const SubmissionSuccessScreen({
    required this.report,
    super.key,
  });

  final PwdReport report;

  void _goToDashboard(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const CitizenDashboardScreen(),
      ),
      (route) => false,
    );
  }

  void _trackComplaint(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportProgressScreen(
          report: report,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PwdPage(
      title: 'Complaint registered',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
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
                      'We have successfully registered your complaint!',
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
                    const Text(
                      'Keep your tracking ID to follow the progress '
                      'of your complaint.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: PwdColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: PwdColors.softOrange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'TRACKING ID',
                            style: TextStyle(
                              color: PwdColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            report.id,
                            style: const TextStyle(
                              color: PwdColors.navy,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.badge_outlined,
                      color: PwdColors.darkOrange,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Assigned officer',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: PwdColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.assignedOfficerName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: PwdColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PwdButton(
                      'Track complaint',
                      icon: Icons.assignment_outlined,
                      onPressed: () => _trackComplaint(context),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => _goToDashboard(context),
                      child: const Text('Go to dashboard'),
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