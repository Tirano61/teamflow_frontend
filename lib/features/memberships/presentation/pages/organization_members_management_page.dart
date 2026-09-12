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
import '../widgets/member_status_chip.dart';

/// Administracion de miembros de la organizacion activa.
///
/// Usa siempre `GET .../members/manage`, que devuelve los miembros `ACTIVE` y
/// los `SUSPENDED`. Solo OWNER/ADMIN llegan aca: la entrada no se pinta para
/// DEVELOPER/MEMBER y el backend responde 403 igual si el rol no alcanza.
///
/// Es la unica pantalla con acciones administrativas (cambiar rol, suspender y
/// reactivar). El directorio general es informativo.
///
/// Las acciones se pintan segun el rol del usuario en la organizacion activa
/// (`AuthState.activeOrganization`) y el estado de cada fila. Es control
/// visual: la autoridad final sigue siendo el backend.
class OrganizationMembersManagementPage extends StatefulWidget {
  const OrganizationMembersManagementPage({super.key});

  @override
  State<OrganizationMembersManagementPage> createState() =>
      _OrganizationMembersManagementPageState();
}

class _OrganizationMembersManagementPageState
    extends State<OrganizationMembersManagementPage> {
  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    context.read<MembershipBloc>().add(const LoadMemberManagementRequested());
  }

  @override
  Widget build(BuildContext context) {
    // Rol del usuario en la organizacion activa: decide que acciones ofrece
    // cada fila y que roles se pueden asignar.
    final actorRole = context.select<AuthBloc, String>(
      (bloc) => bloc.state.activeOrganization?.role ?? '',
    );

    // Usuario autenticado: nadie puede suspenderse ni reactivarse a si mismo,
    // asi que su propia fila no ofrece esas acciones.
    final currentUserId = context.select<AuthBloc, String>(
      (bloc) => bloc.state.session?.user.id ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar miembros'),
        actions: [
          IconButton(
            onPressed: _loadMembers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          const OrganizationInvitationsAction(),
          const ActiveOrganizationAction(),
        ],
      ),
      floatingActionButton: const InviteMemberAction(),
      body: BlocConsumer<MembershipBloc, MembershipState>(
        // El resultado de cada accion se avisa con un snackbar; la fila la
        // repinta el builder con la membresia que devolvio el backend.
        listenWhen: (previous, current) =>
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          switch (state.actionStatus) {
            case MemberActionStatus.success:
              _showMessage(context, _successMessage(state));
            case MemberActionStatus.error:
              _showMessage(context, _errorMessage(state));
            case MemberActionStatus.idle:
            case MemberActionStatus.running:
              break;
          }
        },
        builder: (context, state) {
          switch (state.listStatus) {
            case MembershipListStatus.initial:
            case MembershipListStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case MembershipListStatus.error:
              return _ManagementErrorState(
                message: state.listErrorMessage,
                onRetry: _loadMembers,
              );
            case MembershipListStatus.success:
              if (state.members.isEmpty) {
                return const _ManagementEmptyState();
              }

              return _ManagementList(
                state: state,
                actorRole: actorRole,
                currentUserId: currentUserId,
              );
          }
        },
      ),
    );
  }

  /// Confirmacion de la accion ya aplicada, leida del miembro actualizado.
  String _successMessage(MembershipState state) {
    final member = state.memberById(state.actionMembershipId);
    final name = member?.displayName.trim() ?? '';

    switch (state.actionType) {
      case MemberActionType.changeRole:
        final roleLabel = member == null
            ? ''
            : MembershipRole.fromApiValue(member.role)?.label ??
                  member.role.trim();

        if (name.isEmpty || roleLabel.isEmpty) {
          return 'Rol actualizado.';
        }

        return 'Ahora $name tiene el rol $roleLabel.';
      case MemberActionType.suspend:
        if (name.isEmpty) {
          return 'Miembro suspendido.';
        }

        return '$name quedo suspendido y pierde el acceso a la organizacion.';
      case MemberActionType.reactivate:
        if (name.isEmpty) {
          return 'Miembro reactivado.';
        }

        return '$name vuelve a tener acceso a la organizacion.';
      case MemberActionType.none:
        return '';
    }
  }

  String _errorMessage(MembershipState state) {
    final detail = state.actionErrorMessage.trim();
    if (detail.isNotEmpty) {
      return detail;
    }

    return switch (state.actionType) {
      MemberActionType.changeRole => 'No se pudo cambiar el rol del miembro.',
      MemberActionType.suspend => 'No se pudo suspender al miembro.',
      MemberActionType.reactivate => 'No se pudo reactivar al miembro.',
      MemberActionType.none => '',
    };
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

class _ManagementList extends StatelessWidget {
  const _ManagementList({
    required this.state,
    required this.actorRole,
    required this.currentUserId,
  });

  final MembershipState state;

  /// Rol del usuario en la organizacion activa.
  final String actorRole;

  /// Id del usuario autenticado, para reconocer su propia membresia.
  final String currentUserId;

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

            return _ManageMemberCard(
              member: member,
              actorRole: actorRole,
              isSelf: _isSelf(member),
              isRunningAction: state.isRunningActionOn(member.id),
              // Mientras hay una accion en curso ninguna otra fila acepta
              // pulsaciones: el bloc igual ignora la segunda.
              areActionsEnabled: !state.isRunningAction,
            );
          },
        ),
      ),
    );
  }

  bool _isSelf(Membership member) {
    final userId = currentUserId.trim();

    return userId.isNotEmpty && member.userId.trim() == userId;
  }
}

/// Fila administrativa: datos del miembro, su estado y las acciones que el rol
/// del usuario activo puede ejecutar sobre el.
class _ManageMemberCard extends StatelessWidget {
  const _ManageMemberCard({
    required this.member,
    required this.actorRole,
    required this.isSelf,
    required this.isRunningAction,
    required this.areActionsEnabled,
  });

  final Membership member;
  final String actorRole;

  /// La fila es la membresia del propio usuario autenticado.
  final bool isSelf;

  final bool isRunningAction;
  final bool areActionsEnabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final name = member.displayName;
    final email = member.email.trim();
    final joinedAt = member.joinedAt;

    // El OWNER no se edita desde estos endpoints y un ADMIN tampoco puede
    // editar a otro ADMIN: esas filas no ofrecen la accion. Tampoco hace falta
    // excluir la propia fila del cambio de rol: el rol de uno mismo nunca esta
    // entre los que su propio rol puede modificar.
    //
    // El cambio de rol exige ademas que el miembro este `ACTIVE`: el backend
    // responde 409 sobre un miembro suspendido, asi que la accion no se ofrece.
    final canChangeRole =
        member.isActive &&
        MembershipRole.canChangeRoleOf(
          actorRole: actorRole,
          targetRole: member.role,
        );

    // Suspender/reactivar tienen el mismo alcance por rol, mas la regla
    // explicita de auto-modificacion: nadie cambia su propio estado.
    final canChangeStatus =
        !isSelf &&
        MembershipRole.canChangeStatusOf(
          actorRole: actorRole,
          targetRole: member.role,
        );

    final canSuspend = canChangeStatus && member.isActive;
    final canReactivate = canChangeStatus && member.isSuspended;
    final hasActions = canChangeRole || canSuspend || canReactivate;

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
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (member.role.trim().isNotEmpty)
                            OrganizationRoleChip(role: member.role),
                          MemberStatusChip(status: member.statusValue),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isRunningAction) ...[
              const SizedBox(height: AppSpacing.sm),
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ] else if (hasActions) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (canChangeRole)
                      _ChangeMemberRoleButton(
                        member: member,
                        actorRole: actorRole,
                        isEnabled: areActionsEnabled,
                      ),
                    if (canSuspend)
                      _SuspendMemberButton(
                        member: member,
                        isEnabled: areActionsEnabled,
                      ),
                    if (canReactivate)
                      _ReactivateMemberButton(
                        member: member,
                        isEnabled: areActionsEnabled,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
    required this.isEnabled,
  });

  final Membership member;
  final String actorRole;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
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

/// `Suspender` de un miembro activo.
///
/// Pide confirmacion nombrando al afectado y explicando que pierde el acceso
/// hasta que se lo reactive.
class _SuspendMemberButton extends StatelessWidget {
  const _SuspendMemberButton({required this.member, required this.isEnabled});

  final Membership member;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isEnabled ? () => _confirmAndSuspend(context) : null,
      icon: const Icon(Icons.block_outlined, size: 18),
      label: const Text('Suspender'),
    );
  }

  Future<void> _confirmAndSuspend(BuildContext context) async {
    final bloc = context.read<MembershipBloc>();
    final name = member.displayName.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(name.isEmpty ? 'Suspender miembro' : 'Suspender a $name'),
        content: Text(
          name.isEmpty
              ? 'El miembro perdera el acceso a la organizacion hasta que lo '
                    'reactives. Sigue perteneciendo a la organizacion y '
                    'conserva su rol.'
              : '$name perdera el acceso a la organizacion hasta que lo '
                    'reactives. Sigue perteneciendo a la organizacion y '
                    'conserva su rol.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Suspender'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    bloc.add(SuspendMemberRequested(member.id));
  }
}

/// `Reactivar` de un miembro suspendido.
class _ReactivateMemberButton extends StatelessWidget {
  const _ReactivateMemberButton({
    required this.member,
    required this.isEnabled,
  });

  final Membership member;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: isEnabled ? () => _confirmAndReactivate(context) : null,
      icon: const Icon(Icons.lock_open_outlined, size: 18),
      label: const Text('Reactivar'),
    );
  }

  Future<void> _confirmAndReactivate(BuildContext context) async {
    final bloc = context.read<MembershipBloc>();
    final name = member.displayName.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(name.isEmpty ? 'Reactivar miembro' : 'Reactivar a $name'),
        content: Text(
          name.isEmpty
              ? 'El miembro volvera a tener acceso a la organizacion con el '
                    'rol que ya tenia.'
              : '$name volvera a tener acceso a la organizacion con el rol '
                    'que ya tenia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    bloc.add(ReactivateMemberRequested(member.id));
  }
}

class _ManagementEmptyState extends StatelessWidget {
  const _ManagementEmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.manage_accounts_outlined),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Esta organizacion no tiene miembros para administrar.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementErrorState extends StatelessWidget {
  const _ManagementErrorState({required this.message, required this.onRetry});

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
              'No se pudo cargar la administracion de miembros.',
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
