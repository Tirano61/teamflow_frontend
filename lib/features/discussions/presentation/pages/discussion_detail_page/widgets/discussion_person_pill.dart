import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../discussion_detail_helpers.dart';

class DiscussionPersonPill extends StatelessWidget {
  const DiscussionPersonPill({
    required this.name,
    required this.borderColor,
    this.avatarBackground,
    this.avatarTextColor,
    this.textColor,
    super.key,
  });

  final String name;
  final Color borderColor;
  final Color? avatarBackground;
  final Color? avatarTextColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: avatarBackground,
            child: Text(
              nameInitials(name),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: avatarTextColor,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }
}
