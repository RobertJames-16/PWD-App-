import 'dart:js_interop';

import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

import '../models/pwd_report.dart';

// Chrome video source.
class AttachmentVideo {
  AttachmentVideo(ReportAttachment attachment) {
    // Creates a browser file from the selected video bytes.
    final blob = web.Blob(
      <JSAny>[attachment.bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'video/mp4'),
    );

    // A temporary browser URL, not an uploaded internet link.
    _url = web.URL.createObjectURL(blob);

    controller = VideoPlayerController.networkUrl(
      Uri.parse(_url),
    );
  }

  late final String _url;
  late final VideoPlayerController controller;

  Future<void> dispose() async {
    try {
      await controller.dispose();
    } finally {
      // Releases the temporary browser URL.
      web.URL.revokeObjectURL(_url);
    }
  }
}