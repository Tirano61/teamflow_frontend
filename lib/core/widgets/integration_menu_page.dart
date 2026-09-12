import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/memberships/domain/entities/membership_role.dart';
import '../../features/user_context/presentation/widgets/active_organization_action.dart';
import '../router/app_router.dart';

class IntegrationMenuPage extends StatelessWidget {
  const IntegrationMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isDeveloper = authState.session?.user.isDeveloper ?? false;

    // Rol del usuario en la organizacion activa: solo OWNER/ADMIN ven la
    // entrada de administracion de miembros. Es control visual; el backend
    // responde 403 igual si el rol no alcanza.
    final canManageMembers = MembershipRole.canManageMembers(
      authState.activeOrganization?.role ?? '',
    );

    return Scaffold(
      appBar: AppBar(
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
      ),
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
                  onTap: () => Navigator.pushNamed(context, AppRoutes.discussions),
                ),
                const SizedBox(height: AppSpacing.md),
                // Vista informativa: quien puede verla lo decide el backend,
                // que exige membership ACTIVE en la organizacion.
                _MenuAccessCard(
                  icon: Icons.groups_outlined,
                  title: 'Directorio de miembros',
                  subtitle: 'Quien forma parte de la organizacion activa',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.organizationMembers,
                  ),
                ),
                if (canManageMembers) ...[
                  const SizedBox(height: AppSpacing.md),
                  // Entrada separada del directorio: roles, suspensiones y
                  // reactivaciones. No se pinta para DEVELOPER/MEMBER.
                  _MenuAccessCard(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Administrar miembros',
                    subtitle: 'Roles, suspensiones e invitaciones',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.organizationMembersManage,
                    ),
                  ),
                ],
                if (isDeveloper) ...[
                  const SizedBox(height: AppSpacing.md),
                  _MenuAccessCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Administracion',
                    subtitle: 'Aplicaciones, indicadores y tags',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.workModules),
                  ),
                ],
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
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.16),
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
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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




