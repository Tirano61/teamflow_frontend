import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/pending_invitation.dart';
import '../widgets/organization_role_chip.dart';

/// Onboarding minimo para usuarios que todavia no pertenecen a ninguna
/// organizacion.
///
/// Solo informa: crear organizacion y aceptar invitaciones se implementan en
/// una fase posterior, por eso no se muestran acciones que no hagan nada.
class NoOrganizationPage extends StatelessWidget {
  const NoOrganizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final pendingInvitations =
        context.watch<AuthBloc>().state.userContext?.pendingInvitations ??
        const <PendingInvitation>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TeamFlow'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Icon(
                Icons.apartment_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Todavia no perteneces a ninguna organizacion',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'TeamFlow organiza las discusiones por organizacion. '
                'Necesitas pertenecer a una para acceder al espacio de trabajo.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Puedes pedirle a un administrador que te invite. '
                'Crear una organizacion y aceptar invitaciones estara '
                'disponible en una proxima version.',
                style: textTheme.bodySmall,
              ),
              if (pendingInvitations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Invitaciones pendientes (${pendingInvitations.length})',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ya tienes invitaciones esperando. Todavia no es posible '
                  'aceptarlas desde la aplicacion.',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final invitation in pendingInvitations) ...[
                  _PendingInvitationCard(invitation: invitation),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingInvitationCard extends StatelessWidget {
  const _PendingInvitationCard({required this.invitation});

  final PendingInvitation invitation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = invitation.organizationName.trim().isEmpty
        ? invitation.organizationSlug
        : invitation.organizationName;
    final slug = invitation.organizationSlug.trim();
    final expiresAt = invitation.expiresAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? 'Organizacion sin nombre' : name,
              style: textTheme.titleMedium,
            ),
            if (slug.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('@$slug', style: textTheme.bodySmall),
            ],
            if (invitation.role.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              OrganizationRoleChip(role: invitation.role),
            ],
            if (expiresAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Vence el ${_formatDate(expiresAt)}', style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }
}
