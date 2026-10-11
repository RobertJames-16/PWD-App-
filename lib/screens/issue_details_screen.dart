import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pwd_report.dart';
import '../services/citizen_location_store.dart';
import '../services/report_store.dart';
import 'citizen_place_picker_screen.dart';
import 'submission_success_screen.dart';

class IssueDetailsScreen extends StatefulWidget {
  const IssueDetailsScreen({
    required this.category,
    super.key,
  });

  final String category;

  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();

  // Opens the phone camera for photos and videos.
  final _cameraPicker = ImagePicker();

  // Selected files and camera captures use the same attachment list.
  final List<ReportAttachment> _attachments = [];

  // Change these values to adjust the page colours.
  static const _orange = Color(0xFFED783E);
  static const _navy = Color(0xFF163844);
  static const _muted = Color(0xFF687880);

  static const _maximumFiles = 5;
  static const _maximumBytes = 25 * 1024 * 1024;

  static const _categories = [
    'Pothole / Road',
    'Drainage',
    'Street light',
    'Pavement',
    'Other issue',
  ];

  late String _category;
  String _urgency = 'Medium';
  CitizenPlace? _place;

  bool _readingFiles = false;
  bool _submitting = false;

  bool get _busy => _readingFiles || _submitting;

  @override
  void initState() {
    super.initState();

    _category = _categories.contains(widget.category)
        ? widget.category
        : 'Other issue';

    // Recommend the citizen's saved address.
    _place = CitizenLocationStore.savedPlace.value;
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  // Check the attachment limit before opening camera or files.
  bool _canAddAttachment() {
    if (_busy) return false;

    if (_attachments.length >= _maximumFiles) {
      _message('You can attach up to $_maximumFiles files.');
      return false;
    }

    return true;
  }

  // Open the existing location selection page.
  Future<void> _changeLocation() async {
    final place = await Navigator.push<CitizenPlace>(
      context,
      MaterialPageRoute(
        builder: (_) => CitizenPlacePickerScreen(
          initialPlace: _place,
        ),
      ),
    );

    if (!mounted || place == null) return;

    // Changes this complaint's address only.
    setState(() => _place = place);
  }

  // NEW: take a photo or record a video using the phone camera.
  Future<void> _captureMedia(bool video) async {
    if (!_canAddAttachment()) return;

    // Browser camera behaviour differs from the Android camera.
    // Existing file selection remains available in Chrome.
    if (kIsWeb) {
      _message(
        'Test Take photo and Record video on your Android phone. '
        'In Chrome, use Add photos or Add videos.',
      );
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      _message('Use an Android phone or iPhone for camera capture.');
      return;
    }

    setState(() => _readingFiles = true);

    try {
      final XFile? capture;

      if (video) {
        // Open video recording. The requested limit is 30 seconds.
        capture = await _cameraPicker.pickVideo(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          maxDuration: const Duration(seconds: 30),
        );
      } else {
        // Open photo capture. Reduce resolution to limit file size.
        capture = await _cameraPicker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
          requestFullMetadata: false,
        );
      }

      // Cancelling the camera is not an error.
      if (!mounted || capture == null) return;

      final size = await capture.length();
      if (!mounted) return;

      if (size <= 0 || size > _maximumBytes) {
        _message(
          video
              ? 'Video is empty or larger than 25 MB. Record a shorter video.'
              : 'Photo is empty or larger than 25 MB. Please try again.',
        );
        return;
      }

      final bytes = await capture.readAsBytes();
      if (!mounted) return;

      if (bytes.isEmpty || bytes.lengthInBytes > _maximumBytes) {
        _message('The captured file is empty or larger than 25 MB.');
        return;
      }

      // Store the capture using your existing report attachment model.
      setState(() {
        _attachments.add(
          ReportAttachment(
  name: capture!.name,
  bytes: bytes,
  isVideo: video,
  path: capture.path,
),
        );
      });

      _message(video ? 'Video added.' : 'Photo added.');
    } on PlatformException catch (error) {
      debugPrint('Camera error: ${error.code}: ${error.message}');

      if (error.code.toLowerCase().contains('access')) {
        _message(
          'Allow camera and microphone access in your phone settings, '
          'then try again.',
        );
      } else {
        _message('Could not open the camera. Please try again.');
      }
    } catch (error) {
      debugPrint('Camera capture failed: $error');
      _message('Could not add the capture. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _readingFiles = false);
      }
    }
  }

  // EXISTING: select photos or videos already stored on the device.
  Future<void> _pickFiles(bool video) async {
    if (!_canAddAttachment()) return;

    setState(() => _readingFiles = true);

    final allowed = video
        ? ['mp4']
        : ['jpg', 'jpeg', 'png', 'webp'];

    try {
      // file_picker 13 returns a list directly.
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowed,
      );

      for (final file in files) {
        if (!mounted) return;

        if (_attachments.length >= _maximumFiles) {
          _message('Maximum $_maximumFiles attachments.');
          break;
        }

        final extension = file.name.split('.').last.toLowerCase();

        if (!allowed.contains(extension)) {
          _message('Unsupported file: ${file.name}');
          continue;
        }

        final size = file.lengthSync() ?? await file.length();
        if (!mounted) return;

        if (size == null || size <= 0 || size > _maximumBytes) {
          _message('${file.name}: choose a non-empty file under 25 MB.');
          continue;
        }

        final bytes = await file.readAsBytes();
        if (!mounted) return;

        if (bytes.isEmpty || bytes.lengthInBytes > _maximumBytes) {
          _message('${file.name} is empty or too large.');
          continue;
        }

        final path = kIsWeb ? null : file.path;

        if (video && !kIsWeb && path == null) {
          _message('Could not access this video.');
          continue;
        }

        setState(() {
          _attachments.add(
            ReportAttachment(
              name: file.name,
              bytes: bytes,
              isVideo: video,
              path: path,
            ),
          );
        });
      }
    } catch (error) {
      debugPrint('File selection failed: $error');
      _message('Could not read the selected file. Try again.');
    } finally {
      if (mounted) {
        setState(() => _readingFiles = false);
      }
    }
  }

  // Keep your existing report submission flow.
  void _submit() {
    if (_busy || !_formKey.currentState!.validate()) return;

    final place = _place;

    if (place == null) {
      _message('Select the complaint location.');
      return;
    }

    setState(() => _submitting = true);

    final report = ReportStoreScope.of(context).addReport(
      category: _category,
      description: _description.text.trim(),
      location: '${place.location}\n'
          'District: ${place.area.districtName}\n'
          'Area / locality: ${place.area.locality}',
      urgency: _urgency,
      mediaCount: _attachments.length,
      place: place,
    );

    // Both selected media and camera captures go into the report.
    report.attachments.addAll(_attachments);

    // Save the area used by officer filtering.
    ReportAreaStore.save(report.id, place);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionSuccessScreen(report: report),
      ),
    );
  }

  // Reusable white section card.
  Widget _section(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: _orange, size: 23),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  // Display an attachment with a remove button.
  Widget _attachmentRow(int index, ReportAttachment attachment) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          if (attachment.isVideo)
            const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.videocam_outlined,
                color: _orange,
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                attachment.bytes,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.broken_image),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              attachment.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: _busy
                ? null
                : () {
                    setState(() => _attachments.removeAt(index));
                  },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = CitizenLocationStore.savedPlace.value;
    final usingSaved = _place != null && identical(_place, saved);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('New report'),
        backgroundColor: const Color(0xFFF8FAFB),
        foregroundColor: _navy,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth > 720
                ? (constraints.maxWidth - 680) / 2
                : 16.0;

            return Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  16,
                  padding,
                  24,
                ),
                children: [
                  const Text(
                    'Help us understand the issue',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Describe the problem and confirm where it is.',
                    style: TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 24),

                  _section(
                    'Issue details',
                    Icons.edit_note,
                    [
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: _categories.map((value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _description,
                        enabled: !_busy,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'What happened? Add a nearby landmark.',
                          alignLabelWithHint: true,
                          helperText: 'At least 10 characters.',
                        ),
                        validator: (value) {
                          if ((value?.trim().length ?? 0) < 10) {
                            return 'Add at least 10 characters of detail.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  _section(
                    'Urgency',
                    Icons.priority_high,
                    [
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: ['Low', 'Medium', 'High'].map((value) {
                          return ChoiceChip(
                            label: Text(value),
                            selected: _urgency == value,
                            selectedColor: const Color(0xFFFFEEE4),
                            onSelected: _busy
                                ? null
                                : (_) {
                                    setState(() => _urgency = value);
                                  },
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  _section(
                    'Complaint location',
                    Icons.location_on_outlined,
                    [
                      Text(
                        usingSaved
                            ? 'Recommended: your saved address'
                            : 'Selected problem location',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _place?.area.label ?? 'No locality selected',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _place?.address ?? 'Select the exact map location.',
                        style: const TextStyle(color: _muted),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'The complaint location can be different '
                        'from your home address.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: _busy ? null : _changeLocation,
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Change location'),
                          ),
                          if (saved != null && !usingSaved)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      setState(() => _place = saved);
                                    },
                              child: const Text('Use saved address'),
                            ),
                        ],
                      ),
                    ],
                  ),

                  _section(
                    'Photos and videos',
                    Icons.photo_library_outlined,
                    [
                      const Text(
                        'Up to 5 files · Maximum 25 MB each\n'
                        'Take a new photo/video or select existing files.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // New camera buttons.
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _captureMedia(false),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Take photo'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _captureMedia(true),
                            icon: const Icon(Icons.videocam_outlined),
                            label: const Text('Record video'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Existing file-selection buttons.
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _pickFiles(false),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Add photos'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _pickFiles(true),
                            icon: const Icon(Icons.video_library_outlined),
                            label: const Text('Add videos'),
                          ),
                        ],
                      ),

                      if (_readingFiles) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text('Waiting for capture or reading files...'),
                      ],

                      ..._attachments.asMap().entries.map(
                            (entry) => _attachmentRow(
                              entry.key,
                              entry.value,
                            ),
                          ),
                    ],
                  ),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _busy ? null : _submit,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(
                      _submitting ? 'Submitting...' : 'Submit report',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}