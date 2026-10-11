import 'dart:io';

import 'package:video_player/video_player.dart';

import '../models/pwd_report.dart';

// Android video source.
class AttachmentVideo {
  AttachmentVideo(ReportAttachment attachment) {
    final path = attachment.path;

    if (path == null || path.isEmpty) {
      throw StateError('The video file path is unavailable.');
    }

    controller = VideoPlayerController.file(File(path));
  }

  late final VideoPlayerController controller;

  Future<void> dispose() async {
    await controller.dispose();
  }
}