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

/// Miembros de la organizacion activa, solo lectura.
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
    context.read<MembershipBloc>().add(const LoadOrganizationMembersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Miembros'),
        actions: const [ActiveOrganizationAction()],
      ),
      body: BlocBuilder<MembershipBloc, MembershipState>(
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
