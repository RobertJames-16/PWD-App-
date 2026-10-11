import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/pwd_report.dart';
import '../services/attachment_video.dart';

// Displays attachments in both citizen and officer screens.
class ReportAttachments extends StatelessWidget {
  const ReportAttachments({
    required this.attachments,
    this.onRemove,
    super.key,
  });

  final List<ReportAttachment> attachments;
  final ValueChanged<ReportAttachment>? onRemove;

  void _openAttachment(
    BuildContext context,
    ReportAttachment attachment,
  ) {
    if (attachment.isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _VideoPreviewScreen(
            attachment: attachment,
          ),
        ),
      );
      return;
    }

    // Opens a larger photo with zoom.
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.memory(
                    attachment.bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Unable to display this photo.'),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  attachment.name,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No photos or videos attached.'),
      );
    }

    return Column(
      children: attachments.map((attachment) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => _openAttachment(context, attachment),
                child: attachment.isVideo
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text('Tap to play video'),
                          ],
                        ),
                      )
                    : Image.memory(
                        attachment.bytes,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Photo preview unavailable.'),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      attachment.isVideo
                          ? Icons.videocam_outlined
                          : Icons.image_outlined,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attachment.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onRemove != null)
                      IconButton(
                        tooltip: 'Remove attachment',
                        onPressed: () => onRemove!(attachment),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Plays a selected video inside the app.
class _VideoPreviewScreen extends StatefulWidget {
  const _VideoPreviewScreen({
    required this.attachment,
  });

  final ReportAttachment attachment;

  @override
  State<_VideoPreviewScreen> createState() =>
      _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<_VideoPreviewScreen> {
  AttachmentVideo? _video;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      final video = AttachmentVideo(widget.attachment);
      _video = video;

      await video.controller.initialize();

      if (!mounted) return;

      setState(() {
        _ready = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'Unable to play this video. Try an MP4 video '
            'encoded with H.264 video and AAC audio.';
      });
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _video?.controller;

    if (controller == null || !_ready) return;

    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        // Starts again if the video has finished.
        if (controller.value.position >= controller.value.duration) {
          await controller.seekTo(Duration.zero);
        }

        await controller.play();
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video playback could not start.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    final video = _video;

    if (video != null) {
      unawaited(video.dispose());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _video?.controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.attachment.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : !_ready || controller == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AspectRatio(
                            aspectRatio:
                                controller.value.aspectRatio > 0
                                    ? controller.value.aspectRatio
                                    : 16 / 9,
                            child: VideoPlayer(controller),
                          ),
                          const SizedBox(height: 16),
                          VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),

                          // Updates the button as playback changes.
                          ValueListenableBuilder<VideoPlayerValue>(
                            valueListenable: controller,
                            builder: (context, value, _) {
                              return FilledButton.icon(
                                onPressed: _togglePlayback,
                                icon: Icon(
                                  value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  value.isPlaying ? 'Pause' : 'Play',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}