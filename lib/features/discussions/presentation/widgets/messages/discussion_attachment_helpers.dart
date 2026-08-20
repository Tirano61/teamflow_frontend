import 'package:flutter/material.dart';

import '../../../../discussion_messages/domain/entities/discussion_message.dart';

String resolveAttachmentDisplayName(DiscussionMessage message) {
  final trimmedName = message.attachmentName?.trim();
  if (trimmedName != null && trimmedName.isNotEmpty) {
    return trimmedName;
  }

  return switch (message.type) {
    DiscussionMessageType.image => 'Imagen adjunta',
    DiscussionMessageType.audio => 'Audio adjunto',
    DiscussionMessageType.video => 'Video adjunto',
    DiscussionMessageType.file => 'Archivo adjunto',
    DiscussionMessageType.text => 'Adjunto',
    DiscussionMessageType.unknown => 'Adjunto',
  };
}

String? resolveAttachmentExtension(DiscussionMessage message) {
  final name = message.attachmentName?.trim();
  if (name != null && name.contains('.')) {
    final extension = name.split('.').last.trim().toLowerCase();
    if (extension.isNotEmpty) {
      return extension;
    }
  }

  final rawUrl = message.attachmentUrl?.trim();
  if (rawUrl == null || rawUrl.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(rawUrl);
  final segment = uri?.pathSegments.isNotEmpty == true
      ? uri!.pathSegments.last
      : rawUrl.split('/').last;
  if (!segment.contains('.')) {
    return null;
  }

  final extension = segment.split('.').last.trim().toLowerCase();
  return extension.isEmpty ? null : extension;
}

IconData resolveAttachmentIcon(DiscussionMessage message) {
  switch (message.type) {
    case DiscussionMessageType.image:
      return Icons.image_outlined;
    case DiscussionMessageType.audio:
      return Icons.audiotrack_outlined;
    case DiscussionMessageType.video:
      return Icons.videocam_outlined;
    case DiscussionMessageType.text:
      return Icons.notes_outlined;
    case DiscussionMessageType.file:
    case DiscussionMessageType.unknown:
      final extension = resolveAttachmentExtension(message);
      switch (extension) {
        case 'pdf':
          return Icons.picture_as_pdf_outlined;
        case 'xls':
        case 'xlsx':
        case 'csv':
          return Icons.table_chart_outlined;
        case 'doc':
        case 'docx':
        case 'odt':
          return Icons.description_outlined;
        case 'zip':
        case 'rar':
        case '7z':
        case 'tar':
        case 'gz':
          return Icons.folder_zip_outlined;
        default:
          return Icons.insert_drive_file_outlined;
      }
  }
}

String formatFileSize(int? bytes) {
  if (bytes == null || bytes < 0) {
    return '-';
  }

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
