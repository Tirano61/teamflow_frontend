import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../discussion_messages/domain/entities/discussion_message.dart';

enum AttachmentOption {
  image,
  audio,
  video,
  file;

  String get label {
    switch (this) {
      case AttachmentOption.image:
        return 'Imagen';
      case AttachmentOption.audio:
        return 'Audio';
      case AttachmentOption.video:
        return 'Video';
      case AttachmentOption.file:
        return 'Archivo';
    }
  }

  IconData get icon {
    switch (this) {
      case AttachmentOption.image:
        return Icons.image_outlined;
      case AttachmentOption.audio:
        return Icons.audiotrack_outlined;
      case AttachmentOption.video:
        return Icons.videocam_outlined;
      case AttachmentOption.file:
        return Icons.attach_file_rounded;
    }
  }

  DiscussionMessageType get type {
    switch (this) {
      case AttachmentOption.image:
        return DiscussionMessageType.image;
      case AttachmentOption.audio:
        return DiscussionMessageType.audio;
      case AttachmentOption.video:
        return DiscussionMessageType.video;
      case AttachmentOption.file:
        return DiscussionMessageType.file;
    }
  }

  FileType get filePickerType {
    switch (this) {
      case AttachmentOption.image:
      case AttachmentOption.audio:
      case AttachmentOption.video:
        return FileType.custom;
      case AttachmentOption.file:
        return FileType.any;
    }
  }

  List<String>? get allowedExtensions {
    switch (this) {
      case AttachmentOption.image:
        return const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'];
      case AttachmentOption.audio:
        return const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus', 'flac', 'amr'];
      case AttachmentOption.video:
        return const ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'];
      case AttachmentOption.file:
        return null;
    }
  }
}
