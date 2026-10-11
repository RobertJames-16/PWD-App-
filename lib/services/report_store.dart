import 'package:flutter/material.dart';

import '../models/pwd_notification.dart';
import '../models/pwd_report.dart';
import 'citizen_location_store.dart';
import 'demo_account_store.dart';

class ReportStore extends ChangeNotifier {
  ReportStore(this.reports) {
    for (final report in reports) {
      final number = int.tryParse(report.id.split('-').last);

      if (number != null && number >= _nextReportId) {
        _nextReportId = number + 1;
      }

      if (report.assignedOfficerId.isNotEmpty) {
        ReportAreaStore.assignOfficer(
          report.id,
          report.assignedOfficerId,
        );
      }
    }
  }

  final List<PwdReport> reports;

  final List<PwdNotification> _notifications = [];

  // Remember which citizen submitted each complaint.
  // Account objects remain the same when switching accounts.
  final Map<String, DemoAccount> _reportOwners = {};

  int _nextReportId = 1;
  int _nextNotificationId = 1;
  int _nextOfficerIndex = 0;

  static const _testOfficerIds = [
    'PWD-TN-CHN-0001',
    'PWD-TN-MDU-0001',
  ];

  // Old callers can still use this factory.
  // It now creates an EMPTY store.
  factory ReportStore.demo() {
    return ReportStore([]);
  }

  // Existing auth code calls this method.
  // It intentionally creates nothing.
  void seedOfficerExamples(OfficerRecord officer) {}

  // Reports belonging to the currently signed-in citizen.
  List<PwdReport> get citizenReports {
    final account = PwdDemoSession.current;

    if (account == null || account.officer != null) {
      return [];
    }

    return reports.where((report) {
      return identical(_reportOwners[report.id], account);
    }).toList();
  }

  // Reports assigned to one specific officer.
  List<PwdReport> reportsForOfficer(String officerId) {
    final cleanId = officerId.trim().toUpperCase();

    return reports.where((report) {
      return report.assignedOfficerId == cleanId;
    }).toList();
  }

  bool _canSeeReport(PwdReport report) {
    final account = PwdDemoSession.current;

    if (account == null) return false;

    if (account.officer != null) {
      return report.assignedOfficerId == account.officer!.id;
    }

    return identical(_reportOwners[report.id], account);
  }

  List<PwdReport> get _visibleReports {
    return reports.where(_canSeeReport).toList();
  }

  List<PwdNotification> get notifications {
    final visibleReportIds =
        _visibleReports.map((report) => report.id).toSet();

    return _notifications.where((notification) {
      return visibleReportIds.contains(notification.reportId);
    }).toList();
  }

  int get unreadNotificationCount {
    return notifications.where((item) => !item.isRead).length;
  }

  List<PwdReport> get activeReports {
    return _visibleReports.where((report) {
      return report.status != ReportStatus.completed &&
          report.status != ReportStatus.rejected;
    }).toList();
  }

  int get completedCount {
    return _visibleReports.where((report) {
      return report.status == ReportStatus.completed;
    }).length;
  }

  int get pendingCount => activeReports.length;

  PwdReport? findReport(String id) {
    for (final report in reports) {
      if (report.id == id) return report;
    }

    return null;
  }

  // Called when a citizen presses Submit report.
  PwdReport addReport({
    required String category,
    required String description,
    required String location,
    required String urgency,
    required int mediaCount,
    CitizenPlace? place,
  }) {
    final citizen = PwdDemoSession.current;

    if (citizen == null || citizen.officer != null) {
      throw const FormatException(
        'Sign in as a citizen to submit a complaint.',
      );
    }

    // First complaint -> Kumar.
    // Second complaint -> Meena.
    // Third complaint -> Kumar, and so on.
    final officerId = _testOfficerIds[_nextOfficerIndex];

    final officer = OfficerDirectory.find(officerId);

    if (officer == null) {
      throw StateError('The assigned officer could not be found.');
    }

    final report = PwdReport(
      id: 'PWD-${_nextReportId.toString().padLeft(4, '0')}',
      category: category,
      description: description.trim(),
      location: location,
      urgency: urgency,
      createdAt: DateTime.now(),
      mediaCount: mediaCount,
      assignedOfficerId: officer.id,
      assignedOfficerName: officer.name,
    );

    _nextReportId++;

    _nextOfficerIndex =
        (_nextOfficerIndex + 1) % _testOfficerIds.length;

    reports.insert(0, report);
    _reportOwners[report.id] = citizen;

    // Keep the citizen's actual complaint location.
    if (place != null) {
      ReportAreaStore.save(report.id, place);
    }

    // Store assignment separately from the complaint location.
    ReportAreaStore.assignOfficer(report.id, officer.id);

    report.updates.add(
      ReportUpdate(
        status: ReportStatus.submitted,
        note: 'Assigned for review to ${officer.name}.',
        officerId: 'Department',
        officerName: 'Department',
        createdAt: DateTime.now(),
      ),
    );

    _addNotification(
      report,
      note: 'Assigned officer: ${officer.name}.',
      statusChanged: true,
    );

    notifyListeners();
    return report;
  }

  // Called when the assigned officer saves progress or work photos.
  void updateStatus(
    String id,
    ReportStatus newStatus, {
    String note = '',
    String officerId = 'Department',
    String officerName = '',
    List<ReportAttachment> attachments = const [],
  }) {
    final report = findReport(id);

    if (report == null) {
      throw StateError('Report $id could not be found.');
    }

    final account = PwdDemoSession.current;
    final signedInOfficer = account?.officer;

    if (signedInOfficer == null ||
        report.assignedOfficerId != signedInOfficer.id) {
      throw const FormatException(
        'Only the assigned officer can update this complaint.',
      );
    }

    final cleanNote = note.trim();
    final statusChanged = report.status != newStatus;

    if (!statusChanged &&
        cleanNote.isEmpty &&
        attachments.isEmpty) {
      return;
    }

    final savedAttachments =
        List<ReportAttachment>.unmodifiable(attachments);

    report.status = newStatus;

    final updateNote = cleanNote.isNotEmpty
        ? cleanNote
        : statusChanged
            ? 'Status changed to ${newStatus.label}.'
            : 'Added work photos.';

    report.updates.add(
      ReportUpdate(
        status: newStatus,
        note: updateNote,
        // Use the signed-in account, not an editable field.
        officerId: signedInOfficer.id,
        officerName: signedInOfficer.name,
        createdAt: DateTime.now(),
        attachments: savedAttachments,
      ),
    );

    final notificationNote = savedAttachments.isEmpty
        ? updateNote
        : '$updateNote\n'
            '${savedAttachments.length} work attachment(s) added.';

    _addNotification(
      report,
      note: notificationNote,
      statusChanged: statusChanged,
    );

    notifyListeners();
  }

  String _statusMessage(PwdReport report) {
    switch (report.status) {
      case ReportStatus.submitted:
        return 'Your complaint ${report.id} has been registered.';
      case ReportStatus.underReview:
        return 'The department is reviewing complaint ${report.id}.';
      case ReportStatus.workAssigned:
        return 'A team has been assigned to complaint ${report.id}.';
      case ReportStatus.inProgress:
        return 'Work is in progress for complaint ${report.id}.';
      case ReportStatus.completed:
        return 'Work for complaint ${report.id} has been completed.';
      case ReportStatus.rejected:
        return 'The department could not proceed with '
            'complaint ${report.id}.';
    }
  }

  void _addNotification(
    PwdReport report, {
    required String note,
    required bool statusChanged,
  }) {
    final title = statusChanged
        ? '${report.id}: ${report.status.label}'
        : '${report.id}: New work update';

    final message = note.isEmpty
        ? _statusMessage(report)
        : '${_statusMessage(report)}\n\n$note';

    _notifications.insert(
      0,
      PwdNotification(
        id: 'NOTIF-${_nextNotificationId++}',
        reportId: report.id,
        title: title,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
  }

  void markNotificationRead(String notificationId) {
    for (final notification in notifications) {
      if (notification.id == notificationId) {
        if (!notification.isRead) {
          notification.isRead = true;
          notifyListeners();
        }

        return;
      }
    }
  }

  void markAllNotificationsRead() {
    var changed = false;

    for (final notification in notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }
}

// Shares one report store with all screens.
class ReportStoreScope extends InheritedNotifier<ReportStore> {
  const ReportStoreScope({
    required ReportStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static ReportStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ReportStoreScope>();

    assert(scope != null, 'ReportStoreScope not found in widget tree');

    return scope!.notifier!;
  }
}