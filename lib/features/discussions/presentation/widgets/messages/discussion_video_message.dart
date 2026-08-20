import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'discussion_web_video_surface_stub.dart'
  if (dart.library.html) 'discussion_web_video_surface_web.dart';

class DiscussionVideoMessage extends StatefulWidget {
  const DiscussionVideoMessage({
    required this.fileUrl,
    required this.caption,
    this.onOpenExternally,
    super.key,
  });

  final String? fileUrl;
  final String caption;
  final VoidCallback? onOpenExternally;

  @override
  State<DiscussionVideoMessage> createState() => _DiscussionVideoMessageState();
}

class _DiscussionVideoMessageState extends State<DiscussionVideoMessage> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  late final String _webViewType;
  Uri? _resolvedWebPlaybackUri;

  @override
  void initState() {
    super.initState();
    _webViewType = 'dw-discussion-video-${identityHashCode(this)}';
    _initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final url = widget.fileUrl?.trim();
    if (url == null || url.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    final playbackUri = kIsWeb ? _resolveWebPlaybackUri(uri) : uri;
    final controller = VideoPlayerController.networkUrl(playbackUri);

    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isLoading = false;
        _hasError = false;
        _resolvedWebPlaybackUri = playbackUri;
      });
    } catch (_) {
      controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _togglePlayback(VideoPlayerController controller) async {
    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }

    await controller.play();
  }

  Uri _resolveWebPlaybackUri(Uri originalUri) {
    final host = originalUri.host.toLowerCase();
    final segments = originalUri.pathSegments;

    if (!host.contains('cloudinary.com') || segments.isEmpty) {
      return originalUri;
    }

    final uploadIndex = segments.indexOf('upload');
    if (uploadIndex == -1) {
      return originalUri;
    }

    if (uploadIndex + 1 < segments.length) {
      final nextSegment = segments[uploadIndex + 1];
      if (nextSegment.contains('f_mp4') || nextSegment.contains('vc_h264')) {
        return originalUri;
      }
    }

    final transformedSegments = <String>[
      ...segments.sublist(0, uploadIndex + 1),
      'f_mp4,vc_h264,ac_aac,fl_progressive,q_auto',
      ...segments.sublist(uploadIndex + 1),
    ];

    return originalUri.replace(pathSegments: transformedSegments);
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.caption.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: _buildVideoContent(context),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(caption),
        ],
      ],
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 210,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_hasError || _controller == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No se pudo reproducir el video'),
          if (widget.onOpenExternally != null)
            TextButton.icon(
              onPressed: widget.onOpenExternally,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir externamente'),
            ),
        ],
      );
    }

    final controller = _controller!;

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final aspectRatio = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
        final videoUri = _resolvedWebPlaybackUri;
        final viewPort = kIsWeb
            ? AspectRatio(
                aspectRatio: aspectRatio,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: videoUri == null
                      ? const SizedBox.shrink()
                      : buildDiscussionWebVideoSurface(
                          viewType: _webViewType,
                          uri: videoUri,
                        ),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: GestureDetector(
                    onTap: () => _togglePlayback(controller),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VideoPlayer(controller),
                        if (!value.isPlaying)
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              size: 56,
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            viewPort,
            if (kIsWeb && widget.onOpenExternally != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onOpenExternally,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir externamente'),
                ),
              ),
            if (!kIsWeb)
              Row(
                children: [
                  IconButton(
                    tooltip: value.isPlaying ? 'Pausar' : 'Reproducir',
                    onPressed: () => _togglePlayback(controller),
                    icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
