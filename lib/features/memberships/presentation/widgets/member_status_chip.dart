import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/membership_status.dart';

/// Estado de la membresia en la pantalla administrativa.
///
/// Solo aparece ahi: el directorio devuelve unicamente miembros `ACTIVE` y
/// pintar el estado en todas sus filas no aportaria nada.
class MemberStatusChip extends StatelessWidget {
  const MemberStatusChip({super.key, required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (status) {
      MembershipStatus.active => AppColors.success,
      MembershipStatus.suspended => AppColors.warning,
      MembershipStatus.unknown => theme.colorScheme.outline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: accent),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
