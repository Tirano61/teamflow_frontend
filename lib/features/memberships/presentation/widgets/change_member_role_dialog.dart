import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/membership_role.dart';

/// Dialogo para elegir el rol nuevo de un miembro.
///
/// Solo muestra y devuelve roles asignables: `OWNER` nunca es una opcion. No
/// conoce el bloc ni dispara la request; devuelve el rol elegido y quien lo
/// abre decide que hacer con el.
///
/// `Guardar` queda deshabilitado mientras la seleccion sea el rol actual: el
/// backend es idempotente en ese caso, pero no tiene sentido pedirle un cambio
/// que no cambia nada.
class ChangeMemberRoleDialog extends StatefulWidget {
  const ChangeMemberRoleDialog({
    super.key,
    required this.member,
    required this.assignableRoles,
  });

  final Membership member;

  /// Roles que el usuario activo puede asignar, ya filtrados por su propio rol
  /// (`MembershipRole.assignableBy`).
  final List<MembershipRole> assignableRoles;

  /// Abre el dialogo y devuelve el rol elegido, o `null` si se cancelo.
  static Future<MembershipRole?> show(
    BuildContext context, {
    required Membership member,
    required List<MembershipRole> assignableRoles,
  }) {
    return showDialog<MembershipRole>(
      context: context,
      builder: (_) => ChangeMemberRoleDialog(
        member: member,
        assignableRoles: assignableRoles,
      ),
    );
  }

  @override
  State<ChangeMemberRoleDialog> createState() => _ChangeMemberRoleDialogState();
}

class _ChangeMemberRoleDialogState extends State<ChangeMemberRoleDialog> {
  /// Rol actual del miembro, o `null` si no es uno de los asignables.
  late final MembershipRole? _currentRole = MembershipRole.fromApiValue(
    widget.member.role,
  );

  late MembershipRole? _selectedRole = _currentRole;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final name = widget.member.displayName;
    final email = widget.member.email.trim();
    final currentRoleLabel = _currentRole?.label ?? widget.member.role.trim();
    final selectedRole = _selectedRole;

    return AlertDialog(
      // Los nombres largos y las pantallas chicas no deben cortar el
      // contenido.
      scrollable: true,
      title: const Text('Cambiar rol'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'Miembro sin nombre' : name,
            style: textTheme.titleMedium,
          ),
          // El nombre ya cae al email cuando el usuario no tiene fullName: no
          // se repite abajo en ese caso.
          if (email.isNotEmpty && email != name) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(email, style: textTheme.bodySmall),
          ],
          if (currentRoleLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Rol actual: $currentRoleLabel',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Rol nuevo', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final role in widget.assignableRoles)
                ChoiceChip(
                  label: Text(role.label),
                  selected: selectedRole == role,
                  onSelected: (selected) {
                    if (!selected) {
                      return;
                    }

                    setState(() => _selectedRole = role);
                  },
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: selectedRole == null || selectedRole == _currentRole
              ? null
              : () => Navigator.of(context).pop(selectedRole),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
