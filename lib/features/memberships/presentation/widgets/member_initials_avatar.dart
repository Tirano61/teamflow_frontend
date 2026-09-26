import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

/// Avatar de un miembro con sus iniciales.
///
/// El backend no expone avatar de usuario: se pintan las iniciales de
/// `Membership.displayName`, o `?` si no hay nombre ni email.
class MemberInitialsAvatar extends StatelessWidget {
  const MemberInitialsAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final baseStyle = size >= 40 ? textTheme.titleMedium : textTheme.labelLarge;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Text(
        _initials(name),
        style: baseStyle?.copyWith(color: colorScheme.primary),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}
