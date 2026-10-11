import 'package:flutter/material.dart';

import '../models/pwd_notification.dart';
import '../models/pwd_report.dart';
import '../services/report_store.dart';
import '../theme/pwd_theme.dart';
import '../widgets/pwd_widgets.dart';
import 'report_progress_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Display the notification date and time.
  String _formatTime(DateTime date) {
    final localDate = date.toLocal();
    final hour = localDate.hour % 12 == 0 ? 12 : localDate.hour % 12;
    final minute = localDate.minute.toString().padLeft(2, '0');
    final period = localDate.hour < 12 ? 'AM' : 'PM';

    return '${localDate.day}/${localDate.month}/${localDate.year} '
        'at $hour:$minute $period';
  }

  // Find the report linked to the selected notification.
  void _openNotification(
    BuildContext context,
    ReportStore store,
    PwdNotification notification,
  ) {
    store.markNotificationRead(notification.id);

    PwdReport? matchingReport;

    for (final report in store.reports) {
      if (report.id == notification.reportId) {
        matchingReport = report;
        break;
      }
    }

    // Use a final variable so it can safely be passed to the next page.
    final selectedReport = matchingReport;

    if (selectedReport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This report could not be found.'),
        ),
      );
      return;
    }

    // Open the progress page for this report.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportProgressScreen(report: selectedReport),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ReportStoreScope.of(context);

    // Refresh the page when notifications change.
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final notifications = store.notifications;

        return PwdPage(
          title: 'Notifications',
          back: () => Navigator.pop(context),
          child: notifications.isEmpty
              ? const EmptyState(
                  title: 'No notifications yet',
                  message: 'Report updates will appear here.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        SectionHeading(
                          '${notifications.length} updates',
                        ),
                        if (store.unreadNotificationCount > 0)
                          TextButton(
                            onPressed: store.markAllNotificationsRead,
                            child: const Text('Mark all as read'),
                          ),
                      ],
                    ),
                    ...notifications.map(
                      (notification) => _NotificationCard(
                        notification: notification,
                        formattedTime: _formatTime(notification.createdAt),
                        onTap: () => _openNotification(
                          context,
                          store,
                          notification,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// One notification card.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.formattedTime,
    required this.onTap,
  });

  final PwdNotification notification;
  final String formattedTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead ? Colors.white : PwdColors.softOrange,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                notification.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active_outlined,
                color: PwdColors.darkOrange,
              ),
              const SizedBox(width: 12),

              // Let the text wrap on smaller phones.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        color: PwdColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(notification.message),
                    const SizedBox(height: 8),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        color: PwdColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap to track this report',
                      style: TextStyle(
                        color: PwdColors.darkOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Show a dot when the notification is unread.
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 5,
                  backgroundColor: PwdColors.darkOrange,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}