import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/discussion.dart';
import 'discussion_info_chip.dart';

class DiscussionTypeChip extends StatelessWidget {
  const DiscussionTypeChip({required this.type, super.key});

  final DiscussionType type;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final (label, accent) = switch (type) {
      DiscussionType.error => ('ERROR', semantic.discussionError),
      DiscussionType.idea => ('IDEA', semantic.discussionIdea),
      DiscussionType.improvement => ('MEJORA', semantic.discussionImprovement),
      DiscussionType.question => ('CONSULTA', semantic.discussionQuestion),
      DiscussionType.unknown => ('OTRO', Theme.of(context).colorScheme.outline),
    };

    return DiscussionInfoChip(
      icon: Icons.sell_outlined,
      text: label,
      accent: accent,
    );
  }
}
