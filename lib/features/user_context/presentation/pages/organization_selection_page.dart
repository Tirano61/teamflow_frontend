import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../organization_invitations/presentation/bloc/organization_invitation_bloc.dart';
import '../../../organization_invitations/presentation/widgets/pending_invitations_section.dart';
import '../../domain/entities/pending_invitation.dart';
import '../../domain/entities/user_organization.dart';
import '../widgets/organization_role_chip.dart';

/// Seleccion de organizacion activa cuando el usuario pertenece a varias.
///
/// La decision de mostrar esta pantalla la toma `PostAuthDestinationResolver`;
/// aca solo se lista el contexto y se emite el evento de seleccion. Aceptar
/// una invitacion no elige organizacion por el usuario: solo recarga el
/// contexto y esta pantalla vuelve a resolverse con la lista nueva.
class OrganizationSelectionPage extends StatelessWidget {
  const OrganizationSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrganizationInvitationBloc>(
      create: (_) => sl<OrganizationInvitationBloc>(),
      child: const _OrganizationSelectionView(),
    );
  }
}

class _OrganizationSelectionView extends StatelessWidget {
  const _OrganizationSelectionView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final userContext = context.watch<AuthBloc>().state.userContext;
    final organizations =
        userContext?.organizations ?? const <UserOrganization>[];
    final pendingInvitations =
        userContext?.pendingInvitations ?? const <PendingInvitation>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizaciones'),
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
              Text(
                'Selecciona una organizacion',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tu cuenta pertenece a varias organizaciones. '
                'Elige con cual quieres trabajar.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final organization in organizations) ...[
                _OrganizationCard(
                  organization: organization,
                  onTap: () => context.read<AuthBloc>().add(
                    AuthOrganizationSelected(organization.id),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (pendingInvitations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                PendingInvitationsSection(
                  invitations: pendingInvitations,
                  description:
                      'Al aceptar una invitacion se suma esa organizacion a '
                      'tu lista.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({required this.organization, required this.onTap});

  final UserOrganization organization;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final name = organization.name.trim().isEmpty
        ? organization.slug
        : organization.name;
    final slug = organization.slug.trim();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(
                  Icons.apartment_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
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
                    if (organization.role.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OrganizationRoleChip(role: organization.role),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
