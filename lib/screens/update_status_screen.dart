import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/pwd_report.dart';
import '../services/citizen_location_store.dart';
import '../services/demo_account_store.dart';
import '../services/report_store.dart';
import '../theme/pwd_theme.dart';
import '../widgets/pwd_widgets.dart';
import '../widgets/report_attachments.dart';

class UpdateStatusScreen extends StatefulWidget {
  const UpdateStatusScreen({
    required this.report,
    this.officerId = '',
    super.key,
  });

  final PwdReport report;

  // Kept so existing navigation calls still work.
  // The saved ID comes from the signed-in account.
  final String officerId;

  @override
  State<UpdateStatusScreen> createState() {
    return _UpdateStatusScreenState();
  }
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  final List<ReportAttachment> _photos = [];

  late final TextEditingController _officerIdController;
  late ReportStatus _selectedStatus;

  bool _saving = false;
  bool _picking = false;

  static const int _maxPhotos = 5;
  static const int _maxPhotoBytes = 5 * 1024 * 1024;

  bool get _busy => _saving || _picking;

  @override
  void initState() {
    super.initState();

    _selectedStatus = widget.report.status;

    _officerIdController = TextEditingController(
      text: PwdDemoSession.officerId,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _officerIdController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickPhotos() async {
    if (_busy) return;

    if (_photos.length >= _maxPhotos) {
      _showMessage('You can add up to five photos per update.');
      return;
    }

    setState(() => _picking = true);

    final skipped = <String>[];

    try {
      // file_picker 13 returns a List<PlatformFile>.
      // An empty list means the picker was cancelled.
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (!mounted) return;

      for (final file in files) {
        if (!mounted) return;

        if (_photos.length >= _maxPhotos) {
          skipped.add('Maximum of five photos reached.');
          break;
        }

        final extension = file.name.split('.').last.toLowerCase();

        if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
          skipped.add('${file.name}: choose JPG, PNG or WebP.');
          continue;
        }

        try {
          // Check the size before reading the file into memory.
          final length = await file.length();

          if (!mounted) return;

          if (length == null ||
              length <= 0 ||
              length > _maxPhotoBytes) {
            skipped.add(
              '${file.name}: file must be readable and under 5 MB.',
            );
            continue;
          }

          // Works without dart:io, so Chrome is supported too.
          final bytes = await file.readAsBytes();

          if (!mounted) return;

          if (bytes.isEmpty || bytes.lengthInBytes > _maxPhotoBytes) {
            skipped.add('${file.name}: empty or larger than 5 MB.');
            continue;
          }

          // Confirm that the selected file can actually be
          // decoded as an image, rather than trusting its extension.
          final codec = await ui.instantiateImageCodec(
            bytes,
            targetWidth: 512,
          );

          try {
            final frame = await codec.getNextFrame();
            frame.image.dispose();
          } finally {
            codec.dispose();
          }

          if (!mounted) return;

          setState(() {
            _photos.add(
              ReportAttachment(
                name: file.name,
                bytes: bytes,
                isVideo: false,
              ),
            );
          });
        } catch (_) {
          skipped.add('${file.name}: unable to read this photo.');
        }
      }

      if (skipped.isNotEmpty) {
        _showMessage(skipped.join('\n'));
      }
    } catch (_) {
      _showMessage('Unable to open the photo picker. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  void _saveStatus() {
    if (_busy || !_formKey.currentState!.validate()) return;

    final officerId = PwdDemoSession.officerId;
    final area = PwdDemoSession.officerArea;

    // Preserve the existing assigned-area check.
    if (officerId.isEmpty ||
        area == null ||
        !ReportAreaStore.matches(widget.report.id, area)) {
      _showMessage('This complaint is not in your assigned area.');
      return;
    }

    setState(() => _saving = true);

    try {
      ReportStoreScope.of(context).updateStatus(
        widget.report.id,
        _selectedStatus,
        note: _noteController.text.trim(),
        officerId: officerId,
        officerName: PwdDemoSession.current?.name ?? '',
        attachments: _photos,
      );

      _showMessage(
        'Update saved. The citizen can view the note and photos.',
      );

      Navigator.pop(context);
    } catch (_) {
      _showMessage('The update could not be saved. Please try again.');

      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _selectedStatus == ReportStatus.rejected;
    final officerName = PwdDemoSession.current?.name ?? '';

    return PwdPage(
      title: 'Update complaint',
      back: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Existing complaint summary.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.report.id,
                      style: const TextStyle(
                        color: PwdColors.navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.report.category),
                    const SizedBox(height: 6),
                    Text(
                      widget.report.location,
                      style: const TextStyle(
                        color: PwdColors.muted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Current status'),
                    const SizedBox(height: 8),
                    StatusPill(widget.report.status),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (officerName.isNotEmpty) ...[
              Text(
                'Officer: $officerName',
                style: const TextStyle(
                  color: PwdColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Identity cannot be edited here.
            TextFormField(
              controller: _officerIdController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Officer ID',
                prefixIcon: Icon(Icons.badge_outlined),
                suffixIcon: Icon(Icons.lock_outline),
                helperText: 'Filled from your signed-in officer account.',
                helperMaxLines: 2,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Sign in with an officer account.';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),
            const SectionHeading('New status'),
            const SizedBox(height: 10),

            DropdownButtonFormField<ReportStatus>(
              initialValue: _selectedStatus,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select report status',
                prefixIcon: Icon(Icons.assignment_outlined),
              ),
              items: ReportStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.label),
                );
              }).toList(),
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
            ),

            const SizedBox(height: 18),

            TextFormField(
              controller: _noteController,
              readOnly: _busy,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: isRejected
                    ? 'Reason for rejection'
                    : 'Work update',
                hintText: isRejected
                    ? 'Explain why this complaint cannot proceed.'
                    : 'Example: The damaged road has been cleared. '
                        'Repair work is now in progress.',
                helperText: 'This note will be shared with the citizen.',
                helperMaxLines: 2,
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if ((value?.trim() ?? '').length < 10) {
                  return isRejected
                      ? 'Enter a rejection reason of at least 10 characters.'
                      : 'Enter a work note of at least 10 characters.';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),
            const SectionHeading('Work progress photos'),
            const SizedBox(height: 8),

            const Text(
              'Show the citizen the inspection, ongoing repairs '
              'or completed work.',
              style: TextStyle(color: PwdColors.muted),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _busy || _photos.length >= _maxPhotos
                  ? null
                  : _pickPhotos,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _picking
                    ? 'Reading photos...'
                    : 'Add work photos (${_photos.length}/$_maxPhotos)',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'JPG, PNG or WebP. Maximum 5 MB per photo. '
              'Photos are shared only after you press Save update.',
              style: TextStyle(
                color: PwdColors.muted,
                fontSize: 12,
              ),
            ),

            if (_picking) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],

            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 16),

              // Existing shared widget: preview, zoom and remove.
              ReportAttachments(
                attachments: _photos,
                onRemove: _busy
                    ? null
                    : (photo) {
                        setState(() => _photos.remove(photo));
                      },
              ),
            ],

            const SizedBox(height: 18),

            const Text(
              'You can keep the current status and save a new '
              'work note with photos.',
              style: TextStyle(color: PwdColors.muted),
            ),

            const SizedBox(height: 20),

            PwdButton(
              _saving ? 'Saving...' : 'Save update',
              icon: Icons.save_outlined,
              onPressed: _busy ? null : _saveStatus,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}