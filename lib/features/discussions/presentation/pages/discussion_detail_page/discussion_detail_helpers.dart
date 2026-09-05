import 'package:flutter/material.dart';

import '../../../../../core/theme/app_breakpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../domain/entities/discussion.dart';
import '../../bloc/discussion_state.dart';

bool isCompactLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width < AppBreakpoints.compact;
}

Discussion? resolveDiscussion(DiscussionState state, String discussionId) {
  final selected = state.selectedDiscussion;
  if (selected != null && selected.id == discussionId) {
    return selected;
  }

  for (final discussion in state.discussions) {
    if (discussion.id == discussionId) {
      return discussion;
    }
  }

  return null;
}

String discussionStatusLabel(DiscussionRecordStatus status) {
  switch (status) {
    case DiscussionRecordStatus.newDiscussion:
      return 'Entrada';
    case DiscussionRecordStatus.review:
      return 'RevisiÃ³n';
    case DiscussionRecordStatus.inProgress:
      return 'Trabajando';
    case DiscussionRecordStatus.resolved:
      return 'Resuelto';
    case DiscussionRecordStatus.unknown:
      return 'Desconocido';
  }
}

Color discussionStatusAccent(
  BuildContext context,
  DiscussionRecordStatus status,
) {
  final semantic = context.semanticColors;
  switch (status) {
    case DiscussionRecordStatus.newDiscussion:
      return semantic.statusNew;
    case DiscussionRecordStatus.review:
      return semantic.statusReview;
    case DiscussionRecordStatus.inProgress:
      return semantic.statusInProgress;
    case DiscussionRecordStatus.resolved:
      return semantic.statusResolved;
    case DiscussionRecordStatus.unknown:
      return Theme.of(context).colorScheme.outline;
  }
}

String formatShortDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');

  return '$day/$month $hh:$mm';
}

String normalizedDiscussionTitle(String title) {
  final value = title.trim();
  return value.isEmpty ? '(Sin titulo)' : value;
}

String creatorDisplayName(DiscussionCreator? creator) {
  if (creator == null) {
    return 'Sin creador';
  }

  final fullName = creator.fullName?.trim();
  if (fullName != null && fullName.isNotEmpty) {
    return fullName;
  }

  final email = creator.email?.trim();
  if (email != null && email.isNotEmpty) {
    return email;
  }

  return creator.id;
}

String nameInitials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1).toUpperCase()}${parts.last.substring(0, 1).toUpperCase()}';
}

bool isConsecutiveMessage(
  DiscussionMessage? previous,
  DiscussionMessage current,
) {
  if (previous == null) {
    return false;
  }

  if (previous.author.id != current.author.id) {
    return false;
  }

  final previousCreatedAt = previous.createdAt;
  final currentCreatedAt = current.createdAt;
  if (previousCreatedAt == null || currentCreatedAt == null) {
    return true;
  }

  final diffMinutes = currentCreatedAt.difference(previousCreatedAt).inMinutes;
  return diffMinutes >= 0 && diffMinutes <= 7;
}
