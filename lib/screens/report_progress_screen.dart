import 'package:flutter/material.dart';

import '../models/pwd_report.dart';
import '../services/report_store.dart';
import '../theme/pwd_theme.dart';
import '../widgets/pwd_widgets.dart';
import '../widgets/report_attachments.dart';

class ReportProgressScreen extends StatelessWidget {
  const ReportProgressScreen({
    required this.report,
    super.key,
  });

  final PwdReport report;

  static const List<ReportStatus> _stages = [
    ReportStatus.submitted,
    ReportStatus.underReview,
    ReportStatus.workAssigned,
    ReportStatus.inProgress,
    ReportStatus.completed,
  ];

  String _stageDescription(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return 'The department has received your report.';
      case ReportStatus.underReview:
        return 'The department is reviewing the reported issue.';
      case ReportStatus.workAssigned:
        return 'The issue has been assigned to a department team.';
      case ReportStatus.inProgress:
        return 'Work on the reported issue is in progress.';
      case ReportStatus.completed:
        return 'The reported work has been marked as completed.';
      case ReportStatus.rejected:
        return 'The department could not proceed with this report.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ReportStoreScope.of(context);

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        // Read the current report whenever the store changes.
        final currentReport = store.findReport(report.id) ?? report;
        final currentStatus = currentReport.status;
        final currentStageIndex = _stages.indexOf(currentStatus);
        final wasRejected = currentStatus == ReportStatus.rejected;

        // Most recent note and photos appear first.
        final updates = currentReport.updates.reversed.toList();

        return PwdPage(
          title: 'Track report',
          back: () => Navigator.pop(context),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 6),
                      Text(
                        currentReport.id,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: PwdColors.navy,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Current status',
                        style: TextStyle(color: PwdColors.muted),
                      ),
                      const SizedBox(height: 8),
                      StatusPill(currentStatus),
                      const SizedBox(height: 10),
                      Text(_stageDescription(currentStatus)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Existing progress timeline.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report progress',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: PwdColors.navy,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wasRejected
                            ? 'This report was not approved.'
                            : 'Follow each step as the department '
                                'handles your report.',
                        style: const TextStyle(
                          color: PwdColors.muted,
                        ),
                      ),
                      const SizedBox(height: 18),

                      for (var index = 0;
                          index < _stages.length;
                          index++)
                        _ProgressTimelineStep(
                          title: _stages[index].label,
                          description: _stageDescription(_stages[index]),
                          isComplete: wasRejected
                              ? currentReport.updates.any(
                                  (update) =>
                                      update.status == _stages[index],
                                )
                              : index <= currentStageIndex,
                          isCurrent:
                              !wasRejected && index == currentStageIndex,
                          isLast: index == _stages.length - 1,
                        ),

                      if (wasRejected) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: PwdColors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Status: Rejected. Read the officer’s '
                            'explanation in the updates below.',
                            style: TextStyle(
                              color: PwdColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report details',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: PwdColors.navy,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _ReportDetailRow(
                        label: 'Issue',
                        value: currentReport.category,
                      ),
                      _ReportDetailRow(
                        label: 'Assigned officer',
                        value: currentReport.assignedOfficerName,
                      ),
                      _ReportDetailRow(
                        label: 'Location',
                        value: currentReport.location,
                      ),
                      _ReportDetailRow(
                        label: 'Urgency',
                        value: currentReport.urgency,
                      ),
                      _ReportDetailRow(
                        label: 'Submitted',
                        value: _formatDate(currentReport.createdAt),
                      ),
                      _ReportDetailRow(
                        label: 'Description',
                        value: currentReport.description,
                      ),
                      if (currentReport.mediaCount > 0)
                        _ReportDetailRow(
                          label: 'Citizen photos/videos',
                          value: '${currentReport.mediaCount} item(s)',
                        ),
                    ],
                  ),
                ),
              ),

              // Original citizen evidence stays separate.
              if (currentReport.attachments.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionHeading('Your submitted photos/videos'),
                const SizedBox(height: 12),
                ReportAttachments(
                  attachments: currentReport.attachments,
                ),
              ],

              const SizedBox(height: 24),
              const SectionHeading('Work updates and photos'),
              const SizedBox(height: 8),

              const Text(
                'View the department’s notes and photos '
                'as your complaint progresses.',
                style: TextStyle(color: PwdColors.muted),
              ),

              const SizedBox(height: 12),

              if (updates.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No work updates yet.'),
                  ),
                )
              else
                for (final update in updates)
                  _WorkUpdateCard(update: update),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// Shows when each update was posted.
String _formatDate(DateTime date) {
  final local = date.toLocal();

  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';

  return '${local.day}/${local.month}/${local.year} '
      'at $hour:$minute $period';
}

// Each card keeps the status, note and photos together.
class _WorkUpdateCard extends StatelessWidget {
  const _WorkUpdateCard({
    required this.update,
  });

  final ReportUpdate update;

  @override
  Widget build(BuildContext context) {
    final author = update.officerName.trim().isNotEmpty
        ? update.officerName
        : update.officerId;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Wrap keeps the heading responsive on small phones.
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(update.status),
                Text(
                  _formatDate(update.createdAt),
                  style: const TextStyle(
                    color: PwdColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              author,
              style: const TextStyle(
                color: PwdColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (update.officerName.trim().isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                update.officerId,
                style: const TextStyle(
                  color: PwdColors.muted,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 10),
            Text(update.note),

            if (update.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Work photos (${update.attachments.length})',
                style: const TextStyle(
                  color: PwdColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // Tap a photo to open the existing zoom preview.
              ReportAttachments(
                attachments: update.attachments,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressTimelineStep extends StatelessWidget {
  const _ProgressTimelineStep({
    required this.title,
    required this.description,
    required this.isComplete,
    required this.isCurrent,
    required this.isLast,
  });

  final String title;
  final String description;
  final bool isComplete;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color stepColor;

    if (isCurrent) {
      stepColor = PwdColors.darkOrange;
    } else if (isComplete) {
      stepColor = PwdColors.statusGreen;
    } else {
      stepColor = PwdColors.outline;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isComplete || isCurrent
                        ? stepColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: stepColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isCurrent
                        ? Icons.circle
                        : isComplete
                            ? Icons.check
                            : Icons.circle_outlined,
                    size: isCurrent ? 12 : 16,
                    color: stepColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isComplete
                          ? PwdColors.statusGreen.withValues(alpha: 0.55)
                          : PwdColors.outline,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 2,
                bottom: isLast ? 0 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isCurrent
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isComplete || isCurrent
                          ? PwdColors.navy
                          : PwdColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: PwdColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDetailRow extends StatelessWidget {
  const _ReportDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PwdColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
  }
}