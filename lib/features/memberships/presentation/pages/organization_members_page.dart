import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../user_context/presentation/widgets/active_organization_action.dart';
import '../../../user_context/presentation/widgets/organization_role_chip.dart';
import '../../domain/entities/membership.dart';
import '../bloc/membership_bloc.dart';
import '../bloc/membership_event.dart';
import '../bloc/membership_state.dart';

/// Directorio de miembros de la organizacion activa.
///
/// Vista informativa, equivalente a la lista de miembros de un servidor:
/// muestra quien forma parte hoy de la organizacion (nombre, email y rol) y
/// esta disponible para cualquier rol con membresia activa.
///
/// Usa siempre `GET .../members`, que devuelve solamente miembros `ACTIVE`.
/// No ofrece ninguna accion administrativa: cambiar rol, suspender y reactivar
/// viven en `OrganizationMembersManagementPage`, que usa `.../members/manage`.
///
/// La organizacion no se recibe por parametro: el `MembershipBloc` que provee
/// la ruta la resuelve contra `OrganizationContext` en cada request.
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
    context.read<MembershipBloc>().add(const LoadMemberDirectoryRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio de miembros'),
        actions: const [ActiveOrganizationAction()],
      ),
      body: BlocBuilder<MembershipBloc, MembershipState>(
        builder: (context, state) {
          switch (state.listStatus) {
            case MembershipListStatus.initial:
            case MembershipListStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case MembershipListStatus.error:
              return _MembersErrorState(
                message: state.listErrorMessage,
                onRetry: _loadMembers,
              );
            case MembershipListStatus.success:
              if (state.members.isEmpty) {
                return const _MembersEmptyState();
              }

              return _MembersList(members: state.members);
          }
        },
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  const _MembersList({required this.members});

  final List<Membership> members;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: members.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, index) => _MemberCard(member: members[index]),
        ),
      ),
    );
  }
}

/// Fila del directorio: solo datos. El estado no se muestra porque el endpoint
/// devuelve unicamente miembros `ACTIVE`.
class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final Membership member;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final name = member.displayName;
    final email = member.email.trim();
    final joinedAt = member.joinedAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
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
                  if (member.role.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OrganizationRoleChip(role: member.role),
                  ],
                ],
              ),
            ),
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
