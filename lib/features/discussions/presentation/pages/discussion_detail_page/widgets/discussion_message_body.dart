import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../widgets/messages/discussion_audio_message.dart';
import '../../../widgets/messages/discussion_file_message.dart';
import '../../../widgets/messages/discussion_image_message.dart';
import '../../../widgets/messages/discussion_text_message.dart';
import '../../../widgets/messages/discussion_video_message.dart';

/// Abre el adjunto de un mensaje, opcionalmente forzando la descarga en web.
typedef DiscussionAttachmentOpener = Future<void> Function(
  String? url, {
  bool preferDownload,
});

class DiscussionMessageBody extends StatelessWidget {
  const DiscussionMessageBody({
    required this.message,
    required this.onOpenAttachment,
    super.key,
  });

  final DiscussionMessage message;
  final DiscussionAttachmentOpener onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case DiscussionMessageType.text:
        return DiscussionTextMessage(content: message.content);
      case DiscussionMessageType.image:
        return DiscussionImageMessage(
          fileUrl: message.attachmentUrl,
          caption: message.content,
        );
      case DiscussionMessageType.audio:
        return DiscussionAudioMessage(
          fileUrl: message.attachmentUrl,
          caption: message.content,
          onOpenExternally: () => onOpenAttachment(message.attachmentUrl),
        );
      case DiscussionMessageType.video:
        return DiscussionVideoMessage(
          fileUrl: message.attachmentUrl,
          caption: message.content,
          onOpenExternally: () => onOpenAttachment(message.attachmentUrl),
        );
      case DiscussionMessageType.file:
      case DiscussionMessageType.unknown:
        return DiscussionFileMessage(
          message: message,
          onOpen: () =>
              onOpenAttachment(message.attachmentUrl, preferDownload: kIsWeb),
        );
    }
  }
}
