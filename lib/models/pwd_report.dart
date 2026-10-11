import 'dart:typed_data';

//complaint statuses.
enum ReportStatus {
  submitted,
  underReview,
  workAssigned,
  inProgress,
  completed,
  rejected,
}

//displayed for each status.
extension ReportStatusLabel on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.submitted:
        return 'Submitted';
      case ReportStatus.underReview:
        return 'Under review';
      case ReportStatus.workAssigned:
        return 'Work assigned';
      case ReportStatus.inProgress:
        return 'In progress';
      case ReportStatus.completed:
        return 'Completed';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }
}

// A photo or video selected by the citizen or officer.
class ReportAttachment {
  const ReportAttachment({
    required this.name,
    required this.bytes,
    required this.isVideo,
    this.path,
  });

  final String name;
  final Uint8List bytes;
  final bool isVideo;
  final String? path;
}

// A single entry in the complaint's progress history.
class ReportUpdate {
  const ReportUpdate({
    required this.status,
    required this.note,
    required this.officerId,
    required this.createdAt,
    this.officerName = '',
    this.attachments = const [],
  });

  final ReportStatus status;
  final String note;
  final String officerId;
  final String officerName;
  final DateTime createdAt;
  final List<ReportAttachment> attachments;
}

// One complaint submitted by a citizen.
class PwdReport {
  PwdReport({
    required this.id,
    required this.category,
    required this.description,
    required this.location,
    required this.urgency,
    required this.createdAt,
    this.status = ReportStatus.submitted,
    this.assignedOfficerId = '',
    this.assignedOfficerName = 'Awaiting assignment',
    int mediaCount = 0,
  }) : _initialMediaCount = mediaCount {
    updates.add(
      ReportUpdate(
        status: status,
        note: status == ReportStatus.submitted
            ? 'Complaint submitted by the citizen.'
            : 'Recorded report status.',
        officerId: status == ReportStatus.submitted
            ? 'Citizen'
            : 'Department',
        createdAt: createdAt,
      ),
    );
  }

  final String id;
  final String category;
  final String description;
  final String location;
  final String urgency;
  final DateTime createdAt;

  // The assigned officer's ID controls who receives the complaint.
  final String assignedOfficerId;
  final String assignedOfficerName;

  ReportStatus status;

  final int _initialMediaCount;

  // Citizen's uploaded evidence.
  final List<ReportAttachment> attachments = [];

  // Officer updates, including work photos.
  final List<ReportUpdate> updates = [];

  int get mediaCount {
    return attachments.isNotEmpty
        ? attachments.length
        : _initialMediaCount;
  }
}