import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../memberships/domain/entities/membership_role.dart';
import '../../../organization_invitations/presentation/widgets/invite_member_action.dart';
import '../../../user_context/domain/entities/user_organization.dart';
import '../../../user_context/presentation/widgets/active_organization_action.dart';
import '../../../user_context/presentation/widgets/organization_role_chip.dart';

/// Configuracion de la organizacion activa.
///
/// Es un concentrador de navegacion: no tiene datos propios ni bloc propio.
/// La organizacion sobre la que opera es siempre la activa, leida de
/// `AuthState.activeOrganization` (que resuelve `activeOrganizationId` contra
/// el `/me/context` ya cargado). No guarda ningun `organizationId` propio, asi
/// que no puede quedar apuntando a una organizacion vieja: al cambiar de
/// organizacion la pila se reinicia sobre `home` y esta ruta se descarta.
///
/// La entrada solo se pinta para OWNER/ADMIN, pero la ruta puede alcanzarse por
/// otros caminos, asi que el rol se vuelve a evaluar aca. Es control visual: la
/// autoridad final es el backend, que responde 403 en cada endpoint
/// administrativo si el rol no alcanza.
class OrganizationSettingsPage extends StatelessWidget {
  const OrganizationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final organization = state.activeOrganization;
    final role = organization?.role ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuracion de organizacion'),
        actions: const [ActiveOrganizationAction()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _buildBody(context, organization: organization, role: role),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required UserOrganization? organization,
    required String role,
  }) {
    // Sin organizacion activa no hay nada que configurar. Puede pasar si la
    // ruta se abre justo mientras se recarga `/me/context`.
    if (organization == null) {
      return const _SettingsMessage(
        icon: Icons.apartment_outlined,
        message:
            'No hay una organizacion activa. Elegi una organizacion para '
            'configurarla.',
      );
    }

    if (!MembershipRole.canManageMembers(role)) {
      return const _SettingsMessage(
        icon: Icons.lock_outline_rounded,
        message:
            'Tu rol en esta organizacion no permite administrarla. Solo el '
            'OWNER y los ADMIN acceden a la configuracion.',
      );
    }

    // `Eliminar organizacion` todavia no existe en el backend. Se prepara para
    // el OWNER, que es quien la creo; cuando el flujo real exista habra que
    // confirmar el alcance contra el endpoint.
    final isOwner = role.trim().toUpperCase() == MembershipRole.ownerApiValue;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _OrganizationHeaderCard(organization: organization),
        const SizedBox(height: AppSpacing.xl),
        _SettingsSection(
          title: 'General',
          description:
              'Datos de la organizacion. La edicion del nombre y del slug '
              'todavia no esta disponible.',
          children: [
            _ReadOnlyRow(
              icon: Icons.badge_outlined,
              label: 'Nombre',
              value: organization.name,
            ),
            _ReadOnlyRow(
              icon: Icons.link_rounded,
              label: 'Slug',
              value: organization.slug,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SettingsSection(
          title: 'Modulos, componentes y tags',
          description:
              'Catalogos de la organizacion activa. Un modulo de trabajo puede '
              'tener varios componentes y un componente puede pertenecer a '
              'varios modulos. La relacion se administra desde cualquiera de '
              'los dos lados. Desactivar no elimina: se puede reactivar.',
          children: [
            _SettingsTile(
              icon: Icons.widgets_outlined,
              title: 'Modulos de trabajo',
              subtitle: 'Catalogo de modulos y sus componentes asociados',
              onTap: () => Navigator.pushNamed(context, AppRoutes.workModules),
            ),
            _SettingsTile(
              icon: Icons.donut_small_outlined,
              title: 'Componentes',
              subtitle: 'Catalogo de componentes y los modulos que los usan',
              onTap: () => Navigator.pushNamed(context, AppRoutes.components),
            ),
            _SettingsTile(
              icon: Icons.sell_outlined,
              title: 'Tags',
              subtitle: 'Etiquetas de la organizacion para clasificar',
              onTap: () => Navigator.pushNamed(context, AppRoutes.tags),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SettingsSection(
          title: 'Miembros',
          description:
              'Administracion de las membresias de la organizacion activa. El '
              'directorio general sigue estando fuera de la configuracion: es '
              'informativo para todos los miembros.',
          children: [
            _SettingsTile(
              icon: Icons.manage_accounts_outlined,
              title: 'Administrar miembros',
              subtitle: 'Roles, suspensiones y reactivaciones',
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.organizationMembersManage,
              ),
            ),
            _SettingsTile(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Invitar miembro',
              subtitle:
                  'Buscar un usuario registrado y enviarle una invitacion',
              onTap: () => InviteMemberAction.openInviteFlow(context),
            ),
            _SettingsTile(
              icon: Icons.outgoing_mail,
              title: 'Invitaciones enviadas',
              subtitle:
                  'Estado de las invitaciones y cancelacion de pendientes',
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.organizationInvitations,
              ),
            ),
          ],
        ),
        if (isOwner) ...[
          const SizedBox(height: AppSpacing.xl),
          const _DangerZoneSection(),
        ],
      ],
    );
  }
}

/// Identifica la organizacion que se esta configurando.
///
/// Nombre, slug y rol salen del contexto ya cargado: no dispara ninguna
/// llamada extra.
class _OrganizationHeaderCard extends StatelessWidget {
  const _OrganizationHeaderCard({required this.organization});

  final UserOrganization organization;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final name = organization.displayName;
    final slug = organization.slug.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.apartment_outlined, color: colorScheme.primary),
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
                    Text(
                      slug,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (organization.role.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    OrganizationRoleChip(role: organization.role),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque de configuracion: titulo, aclaracion y las entradas de la seccion.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.description,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final detail = description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleSmall),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Entrada de configuracion que abre una pantalla ya existente.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
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
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

/// Dato de la organizacion que todavia no se puede editar desde TeamFlow.
class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = value.trim();

    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label),
      subtitle: Text(text.isEmpty ? 'Sin definir' : text),
    );
  }
}

/// `Zona de peligro`: queda preparada para `Eliminar organizacion`.
///
/// La accion se pinta deshabilitada a proposito. El backend no expone todavia
/// ningun endpoint de eliminacion de organizacion, asi que no hay ninguna
/// llamada detras de este bloque.
class _DangerZoneSection extends StatelessWidget {
  const _DangerZoneSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zona de peligro',
          style: textTheme.titleSmall?.copyWith(color: colorScheme.error),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Acciones irreversibles sobre la organizacion activa.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            enabled: false,
            leading: Icon(
              Icons.delete_forever_outlined,
              color: colorScheme.error,
            ),
            title: const Text('Eliminar organizacion'),
            subtitle: const Text(
              'Todavia no esta implementado: se habilita cuando exista el '
              'flujo de eliminacion.',
            ),
            trailing: const Chip(
              label: Text('Pendiente'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}

/// Estado vacio de la pantalla: sin organizacion activa o sin rol suficiente.
class _SettingsMessage extends StatelessWidget {
  const _SettingsMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
