enum DiscussionMessageType { text, image, audio, video, file, unknown }

extension DiscussionMessageTypeX on DiscussionMessageType {
  String get apiValue {
    switch (this) {
      case DiscussionMessageType.text:
        return 'TEXT';
      case DiscussionMessageType.image:
        return 'IMAGE';
      case DiscussionMessageType.audio:
        return 'AUDIO';
      case DiscussionMessageType.video:
        return 'VIDEO';
      case DiscussionMessageType.file:
        return 'FILE';
      case DiscussionMessageType.unknown:
        return 'UNKNOWN';
    }
  }

  static DiscussionMessageType fromApiValue(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'TEXT':
        return DiscussionMessageType.text;
      case 'IMAGE':
        return DiscussionMessageType.image;
      case 'AUDIO':
        return DiscussionMessageType.audio;
      case 'VIDEO':
        return DiscussionMessageType.video;
      case 'FILE':
        return DiscussionMessageType.file;
      default:
        return DiscussionMessageType.unknown;
    }
  }
}

class DiscussionMessageAuthor {
  const DiscussionMessageAuthor({required this.id, this.email, this.fullName});

  final String id;
  final String? email;
  final String? fullName;

  String get displayName {
    final normalizedFullName = fullName?.trim();
    if (normalizedFullName != null && normalizedFullName.isNotEmpty) {
      return normalizedFullName;
    }

    final normalizedEmail = email?.trim();
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      return normalizedEmail;
    }

    return id;
  }

  DiscussionMessageAuthor copyWith({
    String? id,
    String? email,
    String? fullName,
  }) {
    return DiscussionMessageAuthor(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
    );
  }
}

class DiscussionMessage {
  const DiscussionMessage({
    required this.id,
    required this.discussionId,
    required this.author,
    required this.type,
    required this.content,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentMimeType,
    this.attachmentSizeBytes,
    this.attachmentPublicId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String discussionId;
  final DiscussionMessageAuthor author;
  final DiscussionMessageType type;
  final String content;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentMimeType;
  final int? attachmentSizeBytes;
  final String? attachmentPublicId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasAttachment =>
      attachmentUrl != null && attachmentUrl!.trim().isNotEmpty;

  DiscussionMessage copyWith({
    String? id,
    String? discussionId,
    DiscussionMessageAuthor? author,
    DiscussionMessageType? type,
    String? content,
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentMimeType,
    int? attachmentSizeBytes,
    String? attachmentPublicId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiscussionMessage(
      id: id ?? this.id,
      discussionId: discussionId ?? this.discussionId,
      author: author ?? this.author,
      type: type ?? this.type,
      content: content ?? this.content,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentMimeType: attachmentMimeType ?? this.attachmentMimeType,
      attachmentSizeBytes: attachmentSizeBytes ?? this.attachmentSizeBytes,
      attachmentPublicId: attachmentPublicId ?? this.attachmentPublicId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
