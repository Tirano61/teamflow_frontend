import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../discussions/domain/entities/discussion.dart';
import '../../domain/entities/shared_content.dart';
import '../bloc/share_intent_bloc.dart';
import '../bloc/share_intent_event.dart';
import '../bloc/share_intent_state.dart';
import 'share_intent_route_args.dart';

class ShareIntentComposePage extends StatefulWidget {
  const ShareIntentComposePage({
    this.routeArgs = const ShareIntentComposeRouteArgs(),
    super.key,
  });

  final ShareIntentComposeRouteArgs routeArgs;

  @override
  State<ShareIntentComposePage> createState() => _ShareIntentComposePageState();
}

class _ShareIntentComposePageState extends State<ShareIntentComposePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<ShareIntentBloc>().add(
        ShareIntentLoadDiscussionsEvent(
          preferredDiscussionId: widget.routeArgs.preferredDiscussionId,
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir en Develop Workflow')),
      body: BlocConsumer<ShareIntentBloc, ShareIntentState>(
        listenWhen: (previous, current) =>
            previous.sendSuccessVersion != current.sendSuccessVersion,
        listener: (context, state) {
          final discussionId = state.lastSentDiscussionId;
          if (discussionId == null || discussionId.trim().isEmpty) {
            Navigator.pop(context);
            return;
          }

          Navigator.pop(context, discussionId);
        },
        builder: (context, state) {
          final pending = state.pendingContent;
          if (pending == null) {
            return _buildEmptyState(context);
          }

          final filteredDiscussions = state.filteredDiscussions;
          final selectedDiscussionId = state.selectedDiscussionId;

          if (_searchController.text != state.searchQuery) {
            _searchController.text = state.searchQuery;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
          }

          final selectedDiscussion = _findDiscussionById(
            state.discussions,
            selectedDiscussionId,
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPreviewCard(context, pending),
                const SizedBox(height: 16),
                Text(
                  'Discusion',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Buscar por titulo',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    context.read<ShareIntentBloc>().add(
                      ShareIntentSearchChangedEvent(value),
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (state.isLoadingDiscussions)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(
                      '${state.searchQuery}|${selectedDiscussionId ?? ''}|${filteredDiscussions.length}',
                    ),
                    isExpanded: true,
                    initialValue:
                        selectedDiscussionId != null &&
                            filteredDiscussions.any(
                              (discussion) =>
                                  discussion.id == selectedDiscussionId,
                            )
                        ? selectedDiscussionId
                        : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Seleccionar discusion',
                    ),
                    items: filteredDiscussions
                        .where(
                          (discussion) =>
                              discussion.id != null &&
                              discussion.id!.trim().isNotEmpty,
                        )
                        .map(
                          (discussion) => DropdownMenuItem<String>(
                            value: discussion.id,
                            child: Text(
                              _discussionLabel(discussion),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    selectedItemBuilder: (context) {
                      return filteredDiscussions
                          .where(
                            (discussion) =>
                                discussion.id != null &&
                                discussion.id!.trim().isNotEmpty,
                          )
                          .map(
                            (discussion) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _discussionLabel(discussion),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false);
                    },
                    onChanged: state.sendStatus == ShareIntentSendStatus.sending
                        ? null
                        : (value) {
                            context.read<ShareIntentBloc>().add(
                              ShareIntentDiscussionSelectedEvent(value),
                            );
                          },
                  ),
                if (state.discussionsErrorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.discussionsErrorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (selectedDiscussion != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Destino: ${selectedDiscussion.title}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (state.sendErrorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.sendErrorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            state.sendStatus == ShareIntentSendStatus.sending
                            ? null
                            : () {
                                context.read<ShareIntentBloc>().add(
                                  const ShareIntentCancelEvent(),
                                );
                                Navigator.pop(context);
                              },
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canSend(state)
                            ? () {
                                context.read<ShareIntentBloc>().add(
                                  const ShareIntentSendRequestedEvent(),
                                );
                              }
                            : null,
                        child: state.sendStatus == ShareIntentSendStatus.sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Enviar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 36),
            const SizedBox(height: 8),
            const Text('No hay contenido compartido pendiente.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, SharedContent content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archivo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _buildPreviewMedia(content),
            const SizedBox(height: 12),
            Text(
              content.displayName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _contentMeta(content),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewMedia(SharedContent content) {
    if (content.type == DiscussionMessageType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          content.previewUri,
          height: 170,
          width: double.infinity,
          fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) =>
              _fallbackIcon(context, content.type),
        ),
      );
    }

    if (content.type == DiscussionMessageType.video) {
      final thumbnailPath = content.thumbnailPath?.trim();
      if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _toPreviewUri(thumbnailPath),
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) =>
              _fallbackIcon(context, content.type),
          ),
        );
      }
    }

    return _fallbackIcon(context, content.type);
  }

  Widget _fallbackIcon(BuildContext context, DiscussionMessageType type) {
    final icon = switch (type) {
      DiscussionMessageType.image => Icons.image_outlined,
      DiscussionMessageType.audio => Icons.audiotrack_outlined,
      DiscussionMessageType.video => Icons.videocam_outlined,
      DiscussionMessageType.file => Icons.insert_drive_file_outlined,
      DiscussionMessageType.text => Icons.notes_outlined,
      DiscussionMessageType.unknown => Icons.help_outline,
    };

    return Container(
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 36),
    );
  }

  Discussion? _findDiscussionById(List<Discussion> list, String? discussionId) {
    if (discussionId == null || discussionId.trim().isEmpty) {
      return null;
    }

    for (final discussion in list) {
      if (discussion.id == discussionId) {
        return discussion;
      }
    }

    return null;
  }

  String _discussionLabel(Discussion discussion) {
    final title = discussion.title.trim();
    if (title.isNotEmpty) {
      return title;
    }

    return 'Sin titulo';
  }

  bool _canSend(ShareIntentState state) {
    return state.pendingContent != null &&
        state.selectedDiscussionId != null &&
        state.selectedDiscussionId!.trim().isNotEmpty &&
        state.sendStatus != ShareIntentSendStatus.sending;
  }

  String _contentMeta(SharedContent content) {
    final parts = <String>[];

    parts.add(_typeLabel(content.type));

    if (content.sizeBytes != null) {
      parts.add(_formatBytes(content.sizeBytes!));
    }

    final ext = content.extension;
    if (ext != null) {
      parts.add(ext.toUpperCase());
    }

    final mime = content.mimeType?.trim();
    if (mime != null && mime.isNotEmpty) {
      parts.add(mime);
    }

    final duration = content.durationMs;
    if (duration != null && duration > 0) {
      parts.add(_formatDuration(duration));
    }

    return parts.join(' · ');
  }

  String _typeLabel(DiscussionMessageType type) {
    return switch (type) {
      DiscussionMessageType.image => 'Imagen',
      DiscussionMessageType.audio => 'Audio',
      DiscussionMessageType.video => 'Video',
      DiscussionMessageType.file => 'Archivo',
      DiscussionMessageType.text => 'Texto',
      DiscussionMessageType.unknown => 'Desconocido',
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    final kib = bytes / 1024;
    if (kib < 1024) {
      return '${kib.toStringAsFixed(1)} KB';
    }

    final mib = kib / 1024;
    if (mib < 1024) {
      return '${mib.toStringAsFixed(1)} MB';
    }

    final gib = mib / 1024;
    return '${gib.toStringAsFixed(1)} GB';
  }

  String _formatDuration(int durationMs) {
    final totalSeconds = (durationMs / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _toPreviewUri(String path) {
    final normalized = path.trim();
    if (normalized.startsWith('content://') ||
        normalized.startsWith('file://') ||
        normalized.startsWith('http://') ||
        normalized.startsWith('https://')) {
      return normalized;
    }

    return Uri.file(normalized).toString();
  }
}
