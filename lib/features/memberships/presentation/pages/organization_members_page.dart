import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../organization_invitations/presentation/widgets/invite_member_action.dart';
import '../../../organization_invitations/presentation/widgets/organization_invitations_action.dart';
import '../../../user_context/presentation/widgets/active_organization_action.dart';
import '../../../user_context/presentation/widgets/organization_role_chip.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/membership_role.dart';
import '../bloc/membership_bloc.dart';
import '../bloc/membership_event.dart';
import '../bloc/membership_state.dart';
import '../widgets/change_member_role_dialog.dart';

/// Miembros de la organizacion activa.
///
/// La organizacion no se recibe por parametro: el `MembershipBloc` que provee
/// la ruta la resuelve contra `OrganizationContext` en cada request.
///
/// `Cambiar rol` solo se pinta en las filas que el rol del usuario en la
/// organizacion activa (`AuthState.activeOrganization`) puede administrar. Es
/// control visual: la autoridad final sigue siendo el backend, que responde
/// 403 si el rol no alcanza.
class OrganizationMembersPage extends StatefulWidget {
  const OrganizationMembersPage({super.key});

  @override
  State<OrganizationMembersPage> createState() =>
      _OrganizationMembersPageState();
}

class _OrganizationMembersPageState extends State<OrganizationMembersPage> {
  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    context.read<MembershipBloc>().add(const LoadOrganizationMembersEvent());
  }

  @override
  Widget build(BuildContext context) {
    // Rol del usuario en la organizacion activa: decide que filas ofrecen
    // `Cambiar rol` y que roles se pueden asignar.
    final actorRole = context.select<AuthBloc, String>(
      (bloc) => bloc.state.activeOrganization?.role ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miembros'),
        // `Invitaciones` solo se pinta para OWNER/ADMIN de la organizacion
        // activa; el resto de los roles ve solo el selector de organizacion.
        actions: const [
          OrganizationInvitationsAction(),
          ActiveOrganizationAction(),
        ],
      ),
      // Solo se pinta para OWNER/ADMIN de la organizacion activa; el resto de
      // los roles no ve la accion.
      floatingActionButton: const InviteMemberAction(),
      body: BlocConsumer<MembershipBloc, MembershipState>(
        // El resultado del cambio de rol se avisa con un snackbar; el listado
        // lo repinta el builder con la fila ya actualizada.
        listenWhen: (previous, current) =>
            previous.changeRoleStatus != current.changeRoleStatus,
        listener: (context, state) {
          switch (state.changeRoleStatus) {
            case ChangeMemberRoleStatus.success:
              _showMessage(context, _roleChangedMessage(state));
            case ChangeMemberRoleStatus.error:
              _showMessage(
                context,
                state.changeRoleErrorMessage.trim().isEmpty
                    ? 'No se pudo cambiar el rol del miembro.'
                    : state.changeRoleErrorMessage,
              );
            case ChangeMemberRoleStatus.idle:
            case ChangeMemberRoleStatus.saving:
              break;
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case MembershipStatus.initial:
            case MembershipStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case MembershipStatus.error:
              return _MembersErrorState(
                message: state.errorMessage,
                onRetry: _loadMembers,
              );
            case MembershipStatus.success:
              if (state.members.isEmpty) {
                return const _MembersEmptyState();
              }

              return _MembersList(state: state, actorRole: actorRole);
          }
        },
      ),
    );
  }

  /// Confirmacion del cambio ya aplicado, leida del miembro actualizado.
  String _roleChangedMessage(MembershipState state) {
    final member = state.memberById(state.changingMembershipId);
    if (member == null) {
      return 'Rol actualizado.';
    }

    final name = member.displayName.trim();
    final roleLabel =
        MembershipRole.fromApiValue(member.role)?.label ?? member.role.trim();

    if (name.isEmpty || roleLabel.isEmpty) {
      return 'Rol actualizado.';
    }

    return 'Ahora $name tiene el rol $roleLabel.';
  }

  void _showMessage(BuildContext context, String message) {
    final text = message.trim();
    if (text.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _MembersList extends StatelessWidget {
  const _MembersList({required this.state, required this.actorRole});

  final MembershipState state;

  /// Rol del usuario en la organizacion activa.
  final String actorRole;

  @override
  Widget build(BuildContext context) {
    final members = state.members;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: members.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, index) {
            final member = members[index];

            return _MemberCard(
              member: member,
              actorRole: actorRole,
              isChangingRole: state.isChangingRoleOf(member.id),
              // Mientras hay un cambio en curso ninguna otra fila acepta
              // pulsaciones: el bloc igual ignora la segunda.
              isActionEnabled: !state.isChangingRole,
            );
          },
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.actorRole,
    required this.isChangingRole,
    required this.isActionEnabled,
  });

  final Membership member;
  final String actorRole;
  final bool isChangingRole;
  final bool isActionEnabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final name = member.displayName;
    final email = member.email.trim();
    final joinedAt = member.joinedAt;

    // El OWNER no se edita desde este endpoint y un ADMIN tampoco puede
    // editar a otro ADMIN: esas filas no ofrecen la accion.
    final canChangeRole = MembershipRole.canChangeRoleOf(
      actorRole: actorRole,
      targetRole: member.role,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Text(
                    _initials(name),
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Miembro sin nombre' : name,
                        style: textTheme.titleMedium,
                      ),
                      // El nombre ya cae al email cuando el usuario no tiene
                      // fullName: no se repite abajo en ese caso.
                      if (email.isNotEmpty && email != name) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(email, style: textTheme.bodySmall),
                      ],
                      if (joinedAt != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Miembro desde ${_formatDate(joinedAt)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (member.role.trim().isNotEmpty ||
                          _shouldShowStatus(member.status)) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (member.role.trim().isNotEmpty)
                              OrganizationRoleChip(role: member.role),
                            if (_shouldShowStatus(member.status))
                              _MemberStatusChip(status: member.status),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (canChangeRole) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: _ChangeMemberRoleButton(
                  member: member,
                  actorRole: actorRole,
                  isChangingRole: isChangingRole,
                  isEnabled: isActionEnabled,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// El endpoint solo devuelve miembros `ACTIVE`: mostrar ese chip en todas las
  /// filas no aportaria nada. Solo se muestra un status distinto.
  bool _shouldShowStatus(String status) {
    final normalized = status.trim();
    return normalized.isNotEmpty && normalized.toUpperCase() != 'ACTIVE';
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

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }
}

/// `Cambiar rol` de un miembro administrable.
///
/// Abre el dialogo de seleccion y recien despues emite el evento: el cambio no
/// se aplica con la sola pulsacion.
class _ChangeMemberRoleButton extends StatelessWidget {
  const _ChangeMemberRoleButton({
    required this.member,
    required this.actorRole,
    required this.isChangingRole,
    required this.isEnabled,
  });

  final Membership member;
  final String actorRole;
  final bool isChangingRole;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    if (isChangingRole) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return TextButton.icon(
      onPressed: isEnabled ? () => _pickRoleAndSubmit(context) : null,
      icon: const Icon(Icons.manage_accounts_outlined, size: 18),
      label: const Text('Cambiar rol'),
    );
  }

  Future<void> _pickRoleAndSubmit(BuildContext context) async {
    final bloc = context.read<MembershipBloc>();

    final role = await ChangeMemberRoleDialog.show(
      context,
      member: member,
      // Un ADMIN no puede asignar ADMIN: el dialogo no ofrece esa opcion.
      assignableRoles: MembershipRole.assignableBy(actorRole),
    );

    // Vuelve `null` si se cancelo o si se confirmo el rol que ya tenia.
    if (role == null) {
      return;
    }

    bloc.add(ChangeMemberRoleRequested(membershipId: member.id, role: role));
  }
}

class _MemberStatusChip extends StatelessWidget {
  const _MemberStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.trim().toUpperCase()),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _MembersEmptyState extends StatelessWidget {
  const _MembersEmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Esta organizacion no tiene miembros para mostrar.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersErrorState extends StatelessWidget {
  const _MembersErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detail = message.trim();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No se pudieron cargar los miembros.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
