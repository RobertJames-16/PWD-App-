import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pwd_report.dart';
import '../services/report_store.dart';
import '../widgets/pwd_widgets.dart';
import '../widgets/report_attachments.dart';
import 'update_status_screen.dart';

class OfficerComplaintDetailsScreen extends StatelessWidget {
  const OfficerComplaintDetailsScreen({
    required this.report,
    this.officerId = '',
    super.key,
  });

  final PwdReport report;
  final String officerId;

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final store = ReportStoreScope.of(context);

    // Rebuilds when the officer updates the complaint status.
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return PwdPage(
          title: 'Complaint details',
          back: () => Navigator.pop(context),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                report.id,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerLeft,
                child: StatusPill(report.status),
              ),
              const SizedBox(height: 20),

              const SectionHeading('Citizen complaint'),
              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Shows the citizen's full complaint.
                      SelectableText(report.description),
                      const SizedBox(height: 16),

                      Text('Urgency: ${report.urgency}'),
                      const SizedBox(height: 6),
                      Text(
                        'Submitted: ${_formatDate(report.createdAt)}',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Assigned officer: ${report.assignedOfficerName}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const SectionHeading('Reported location'),
              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SelectableText(report.location),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextButton.icon(
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy location'),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: report.location),
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location copied.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const SectionHeading('Citizen photos and videos'),
              const SizedBox(height: 10),

              // Shows the files selected by the citizen.
              // No remove button appears on the officer screen.
              ReportAttachments(
                attachments: report.attachments,
              ),
              const SizedBox(height: 20),

              const SectionHeading('Work history'),
              const SizedBox(height: 10),

              // Latest work update appears first.
              ...report.updates.reversed.map((update) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update.status.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(update.note),
                        const SizedBox(height: 8),
                        Text(
                          '${update.officerId} · '
                          '${_formatDate(update.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Opens the existing status-update screen.
              PwdButton(
                'Update complaint status',
                icon: Icons.edit_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UpdateStatusScreen(
                        report: report,
                        officerId: officerId,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}