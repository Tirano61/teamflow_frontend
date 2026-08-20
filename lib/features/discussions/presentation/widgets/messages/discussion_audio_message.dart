import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

class DiscussionAudioMessage extends StatefulWidget {
  const DiscussionAudioMessage({
    required this.fileUrl,
    required this.caption,
    this.onOpenExternally,
    super.key,
  });

  final String? fileUrl;
  final String caption;
  final VoidCallback? onOpenExternally;

  @override
  State<DiscussionAudioMessage> createState() => _DiscussionAudioMessageState();
}

class _DiscussionAudioMessageState extends State<DiscussionAudioMessage> {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Duration?>? _durationSubscription;

  Duration _duration = Duration.zero;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _durationSubscription = _player.durationStream.listen((duration) {
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = duration ?? Duration.zero;
      });
    });
    _prepare();
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
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

    try {
      await _player.setUrl(url);
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = _player.duration ?? Duration.zero;
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _togglePlayback(PlayerState state) async {
    if (state.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }

    if (_player.playing) {
      await _player.pause();
      return;
    }

    await _player.play();
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
          child: _buildPlayerContent(context),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(caption),
        ],
      ],
    );
  }

  Widget _buildPlayerContent(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No se pudo reproducir el audio'),
          if (widget.onOpenExternally != null)
            TextButton.icon(
              onPressed: widget.onOpenExternally,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir externamente'),
            ),
        ],
      );
    }

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data ?? _player.playerState;
        final playing = playerState.playing;

        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final durationMs = _duration.inMilliseconds;
            final sliderMax = durationMs > 0 ? durationMs.toDouble() : 1.0;
            final sliderValue = position.inMilliseconds
                .clamp(0, durationMs > 0 ? durationMs : 1)
                .toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: playing ? 'Pausar' : 'Reproducir',
                      onPressed: () => _togglePlayback(playerState),
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    ),
                    Expanded(
                      child: Slider(
                        value: sliderValue,
                        max: sliderMax,
                        onChanged: durationMs <= 0
                            ? null
                            : (value) {
                                _player.seek(
                                  Duration(milliseconds: value.round()),
                                );
                              },
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position)),
                      Text(_formatDuration(_duration)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
