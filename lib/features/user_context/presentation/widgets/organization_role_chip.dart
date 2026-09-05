import 'package:flutter/material.dart';

/// Chip con el rol del usuario dentro de una organizacion.
class OrganizationRoleChip extends StatelessWidget {
  const OrganizationRoleChip({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final label = role.trim();
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Chip(
      label: Text(label.toUpperCase()),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
