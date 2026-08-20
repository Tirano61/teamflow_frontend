import '../../../discussion_messages/domain/entities/discussion_message.dart';

class SharedContent {
  const SharedContent({
    required this.signature,
    required this.path,
    required this.type,
    required this.displayName,
    this.mimeType,
    this.sizeBytes,
    this.durationMs,
    this.thumbnailPath,
    this.receivedAt,
  });

  final String signature;
  final String path;
  final DiscussionMessageType type;
  final String displayName;
  final String? mimeType;
  final int? sizeBytes;
  final int? durationMs;
  final String? thumbnailPath;
  final DateTime? receivedAt;

  String? get extension {
    final name = displayName.trim();
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == name.length - 1) {
      return null;
    }

    final ext = name.substring(dotIndex + 1).trim().toLowerCase();
    return ext.isEmpty ? null : ext;
  }

  String get uploadFileName {
    final name = displayName.trim();
    if (name.isNotEmpty) {
      return name;
    }

    final ext = extension;
    if (ext != null) {
      return 'shared_file.$ext';
    }

    return 'shared_file';
  }

  String get previewUri {
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
