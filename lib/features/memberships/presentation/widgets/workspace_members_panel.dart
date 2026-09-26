import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/membership.dart';
import '../bloc/membership_bloc.dart';
import '../bloc/membership_event.dart';
import '../bloc/membership_state.dart';
import 'member_initials_avatar.dart';
import 'members_list_states.dart';

/// Panel de miembros del Workspace, al estilo de la lista de miembros de un
/// servidor de Discord.
///
/// Responde solo "quien pertenece hoy a esta organizacion": usa el directorio
/// (`LoadMemberDirectoryRequested` -> `GET .../members`, solo `ACTIVE`) y no
/// ofrece ninguna accion administrativa, que sigue en Configuracion de
/// organizacion -> Miembros.
///
/// Lee el `MembershipBloc` que provee la ruta. La organizacion la resuelve el
/// datasource contra `OrganizationContext`; el panel no la conoce.
///
/// Carga solo la primera vez que se muestra: al ocultarlo y volver a abrirlo
/// reutiliza el listado del bloc. La recarga explicita es el boton del
/// encabezado.
class WorkspaceMembersPanel extends StatefulWidget {
  const WorkspaceMembersPanel({super.key, required this.onClose});

  /// Ancho del panel cuando se integra como columna derecha.
  static const double width = 280;

  final VoidCallback onClose;

  @override
  State<WorkspaceMembersPanel> createState() => _WorkspaceMembersPanelState();
}

class _WorkspaceMembersPanelState extends State<WorkspaceMembersPanel> {
  @override
  void initState() {
    super.initState();
    if (context.read<MembershipBloc>().state.listStatus ==
        MembershipListStatus.initial) {
      _loadMembers();
    }
  }

  void _loadMembers() {
    context.read<MembershipBloc>().add(const LoadMemberDirectoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<MembershipBloc, MembershipState>(
            buildWhen: (previous, current) =>
                previous.listStatus != current.listStatus,
            builder: (context, state) => _PanelHeader(
              isLoading: state.listStatus == MembershipListStatus.loading,
              onRefresh: _loadMembers,
              onClose: widget.onClose,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<MembershipBloc, MembershipState>(
              builder: (context, state) {
                switch (state.listStatus) {
                  case MembershipListStatus.initial:
                  case MembershipListStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case MembershipListStatus.error:
                    // El error queda contenido en el panel: el contenido
                    // principal del Workspace sigue usable.
                    return SingleChildScrollView(
                      child: MembersErrorState(
                        message: state.listErrorMessage,
                        onRetry: _loadMembers,
                      ),
                    );
                  case MembershipListStatus.success:
                    final groups = state.membersGroupedByRole;
                    if (groups.isEmpty) {
                      return const SingleChildScrollView(
                        child: MembersEmptyState(),
                      );
                    }

                    return _GroupedMembersList(groups: groups);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.isLoading,
    required this.onRefresh,
    required this.onClose,
  });

  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Miembros',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Recargar miembros',
            onPressed: isLoading ? null : onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar miembros',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _GroupedMembersList extends StatelessWidget {
  const _GroupedMembersList({required this.groups});

  final List<MemberRoleGroup> groups;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        for (final group in groups) ...[
          _RoleGroupHeader(group: group),
          for (final member in group.members)
            _MemberTile(member: member, showRole: group.isUnknownRole),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Encabezado del grupo: es el dato de rol de cada miembro que lista.
class _RoleGroupHeader extends StatelessWidget {
  const _RoleGroupHeader({required this.group});

  final MemberRoleGroup group;

  @override
  Widget build(BuildContext context) {
    final label = group.isUnknownRole ? 'OTROS' : group.role;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        '$label — ${group.members.length}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Fila del panel: avatar y nombre. El rol lo da el grupo; solo se repite en
/// la fila para roles que no tienen grupo propio.
class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.showRole});

  final Membership member;
  final bool showRole;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = member.displayName;
    final role = member.role.trim().toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          MemberInitialsAvatar(name: name, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.isEmpty ? 'Miembro sin nombre' : name,
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showRole && role.isNotEmpty)
                  Text(
                    role,
                    style: textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
