import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/memberships/domain/entities/membership_role.dart';
import '../../features/memberships/presentation/widgets/workspace_members_scaffold.dart';
import '../../features/user_context/presentation/widgets/active_organization_action.dart';
import '../router/app_router.dart';

class IntegrationMenuPage extends StatelessWidget {
  const IntegrationMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    // Rol del usuario en la organizacion activa. La configuracion se abre para
    // cualquier Membership ACTIVE (ahi esta `Abandonar organizacion`); el rol
    // solo cambia el texto de la entrada. Que secciones se ven lo decide la
    // propia pantalla, y el backend responde 403 igual si el rol no alcanza.
    final canManageOrganization = MembershipRole.canManageMembers(
      authState.activeOrganization?.role ?? '',
    );

    // `Miembros` (panel del directorio de la organizacion activa) lo agrega
    // el scaffold del Workspace, para cualquier Membership ACTIVE.
    return WorkspaceMembersScaffold(
      title: const Text('TeamFlow'),
      actions: [
        const ActiveOrganizationAction(),
        IconButton(
          tooltip: 'Cerrar sesion',
          onPressed: () {
            context.read<AuthBloc>().add(const AuthLogoutRequested());
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TeamFlow',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Gestion interna de desarrollo y soporte',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                _MenuAccessCard(
                  icon: Icons.forum_outlined,
                  title: 'Discussions',
                  subtitle: 'Errores, ideas, mejoras y consultas',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.discussions),
                ),
                const SizedBox(height: AppSpacing.md),
                // Unica entrada de configuracion del menu: administrar
                // miembros, invitaciones y catalogos (OWNER/ADMIN) y abandonar
                // la organizacion (resto de roles) se abren desde adentro.
                _MenuAccessCard(
                  icon: Icons.settings_outlined,
                  title: 'Configuracion de organizacion',
                  subtitle: canManageOrganization
                      ? 'General, modulos, componentes, tags y miembros'
                      : 'Tu membresia en la organizacion',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.organizationSettings,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuAccessCard extends StatelessWidget {
  const _MenuAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.arrow_forward_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
