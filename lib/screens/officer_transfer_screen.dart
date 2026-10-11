import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/demo_account_store.dart';
import '../widgets/pwd_location_fields.dart';
import '../widgets/pwd_widgets.dart';

// A request does not change the officer's active assignment.
class OfficerTransferRequest {
  OfficerTransferRequest({
    required this.officerId,
    required this.requestedArea,
    required this.reason,
    required this.documentName,
    required this.documentBytes,
  });

  final String officerId;
  final PwdAreaSelection requestedArea;
  final String reason;
  final String documentName;
  final Uint8List documentBytes;

  final DateTime createdAt = DateTime.now();
  final String status = 'Pending administrator review';
}

// Existing temporary storage.
// This does not send the request to an administrator.
class OfficerTransferStore {
  static final Map<String, OfficerTransferRequest> pending = {};
}

class OfficerTransferScreen extends StatefulWidget {
  const OfficerTransferScreen({super.key});

  @override
  State<OfficerTransferScreen> createState() =>
      _OfficerTransferScreenState();
}

class _OfficerTransferScreenState extends State<OfficerTransferScreen> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  PwdAreaSelection? _area;
  String? _fileName;
  Uint8List? _bytes;

  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickDocument() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (file == null || !mounted) return;

      final extension = file.name.split('.').last.toLowerCase();

      if (!['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
        _message('Choose a PDF, JPG or PNG document.');
        return;
      }

      final length = file.lengthSync() ?? await file.length();
      if (!mounted) return;

      if (length == null || length <= 0 || length > 5 * 1024 * 1024) {
        _message('Choose a non-empty document up to 5 MB.');
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        _message('Choose a non-empty document up to 5 MB.');
        return;
      }

      setState(() {
        _fileName = file.name;
        _bytes = bytes;
      });
    } catch (_) {
      _message('Could not read the document. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (_busy || !_form.currentState!.validate()) return;

    if (!PwdDemoSession.isOfficer) {
      _message('Sign in with an officer account.');
      return;
    }

    final area = _area;
    final bytes = _bytes;
    final fileName = _fileName;

    if (area == null || bytes == null || fileName == null) {
      _message(
        'Choose the requested area and attach the transfer document.',
      );
      return;
    }

    final current = PwdDemoSession.officerArea;

    if (current?.districtCode == area.districtCode &&
        current?.locality.trim().toLowerCase() ==
            area.locality.trim().toLowerCase()) {
      _message('Choose a different area for the transfer request.');
      return;
    }

    final id = PwdDemoSession.officerId;

    if (OfficerTransferStore.pending.containsKey(id)) {
      _message('You already have a pending request.');
      return;
    }

    setState(() {
      OfficerTransferStore.pending[id] = OfficerTransferRequest(
        officerId: id,
        requestedArea: area,
        reason: _reason.text.trim(),
        documentName: fileName,
        documentBytes: bytes,
      );
    });

    _message(
      'Request recorded. Your current assignment remains unchanged.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = OfficerTransferStore.pending[PwdDemoSession.officerId];

    return PwdPage(
      title: 'Request area change',
      back: () => Navigator.pop(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PwdDemoSession.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Current assignment: '
                        '${PwdDemoSession.officerArea?.label ?? "Not assigned"}',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Submit a transfer order or supporting approval '
                        'document. The administrator must approve before '
                        'your assignment can change.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (pending != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pending.status,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Requested area: ${pending.requestedArea.label}'),
                        Text('Document: ${pending.documentName}'),
                        Text('Reason: ${pending.reason}'),
                      ],
                    ),
                  ),
                )
              else
                Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PwdLocationFields(
                        onChanged: (area) => _area = area,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reason,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Reason for transfer',
                        ),
                        validator: (text) =>
                            (text?.trim().length ?? 0) < 10
                                ? 'Enter at least 10 characters.'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _pickDocument,
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                          _fileName ??
                              'Attach supporting paper '
                                  '(PDF / image, max 5 MB)',
                        ),
                      ),
                      if (_busy) const LinearProgressIndicator(),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: const Text('Submit for approval'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}