import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../organization_invitations/presentation/bloc/organization_invitation_bloc.dart';
import '../../../organization_invitations/presentation/widgets/pending_invitations_section.dart';
import '../../../organizations/presentation/bloc/organization_bloc.dart';
import '../../../organizations/presentation/widgets/create_organization_action.dart';
import '../../domain/entities/pending_invitation.dart';

/// Onboarding para usuarios que todavia no pertenecen a ninguna organizacion.
///
/// Ofrece las dos unicas salidas posibles: crear una organizacion propia o
/// aceptar una invitacion pendiente. Ninguna de las dos navega a mano: ambas
/// terminan recargando `/me/context` y dejan que `AuthGatePage` resuelva el
/// destino.
///
/// La creacion no es exclusiva de esta pantalla: usa la misma
/// [CreateOrganizationAction] que el selector de organizaciones, que es desde
/// donde se crea una organizacion adicional.
class NoOrganizationPage extends StatelessWidget {
  const NoOrganizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrganizationBloc>(create: (_) => sl<OrganizationBloc>()),
        BlocProvider<OrganizationInvitationBloc>(
          create: (_) => sl<OrganizationInvitationBloc>(),
        ),
      ],
      child: const _NoOrganizationView(),
    );
  }
}

class _NoOrganizationView extends StatelessWidget {
  const _NoOrganizationView();

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
              const SizedBox(height: AppSpacing.lg),
              const CreateOrganizationAction(),
              if (pendingInvitations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                PendingInvitationsSection(
                  invitations: pendingInvitations,
                  description:
                      'Acepta una invitacion para entrar a una organizacion '
                      'existente.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
