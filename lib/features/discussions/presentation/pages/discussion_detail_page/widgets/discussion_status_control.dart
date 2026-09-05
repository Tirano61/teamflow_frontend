import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/discussion.dart';
import '../discussion_detail_helpers.dart';
import 'discussion_info_chip.dart';

class DiscussionStatusControl extends StatelessWidget {
  const DiscussionStatusControl({
    required this.discussion,
    required this.isDeveloper,
    required this.disabled,
    required this.onStatusSelected,
    required this.onOpenStatusSheet,
    super.key,
  });

  final Discussion discussion;
  final bool isDeveloper;
  final bool disabled;
  final ValueChanged<DiscussionRecordStatus> onStatusSelected;
  final VoidCallback onOpenStatusSheet;

  @override
  Widget build(BuildContext context) {
    final accent = discussionStatusAccent(context, discussion.status);
    final label = discussionStatusLabel(discussion.status);

    if (!isDeveloper) {
      return DiscussionInfoChip(
        icon: Icons.flag_rounded,
        text: label,
        accent: accent,
      );
    }

    if (isCompactLayout(context)) {
      return InkWell(
        onTap: disabled ? null : onOpenStatusSheet,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: DiscussionInfoChip(
          icon: Icons.alt_route_rounded,
          text: label,
          accent: accent,
        ),
      );
    }

    return PopupMenuButton<DiscussionRecordStatus>(
      enabled: !disabled,
      tooltip: 'Cambiar estado',
      itemBuilder: (context) {
        return DiscussionRecordStatus.values
            .where((status) => status != DiscussionRecordStatus.unknown)
            .map(
              (status) => PopupMenuItem<DiscussionRecordStatus>(
                value: status,
                child: Row(
                  children: [
                    Icon(
                      status == discussion.status
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(discussionStatusLabel(status)),
                  ],
                ),
              ),
            )
            .toList(growable: false);
      },
      onSelected: (status) {
        if (status == discussion.status) {
          return;
        }
        onStatusSelected(status);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DiscussionInfoChip(
            icon: Icons.alt_route_rounded,
            text: label,
            accent: accent,
          ),
        ],
      ),
    );
  }
}
