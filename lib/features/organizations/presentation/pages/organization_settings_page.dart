import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../memberships/domain/entities/membership_role.dart';
import '../../../memberships/presentation/bloc/membership_bloc.dart';
import '../../../memberships/presentation/bloc/membership_event.dart';
import '../../../memberships/presentation/bloc/membership_state.dart';
import '../../../organization_invitations/presentation/widgets/invite_member_action.dart';
import '../../../user_context/domain/entities/user_organization.dart';
import '../../../user_context/presentation/widgets/active_organization_action.dart';
import '../../../user_context/presentation/widgets/organization_role_chip.dart';

/// Configuracion de la organizacion activa.
///
/// Es un concentrador de navegacion y de las opciones personales de la
/// membresia. La organizacion sobre la que opera es siempre la activa, leida de
/// `AuthState.activeOrganization` (que resuelve `activeOrganizationId` contra
/// el `/me/context` ya cargado). No guarda ningun `organizationId` propio, asi
/// que no puede quedar apuntando a una organizacion vieja: al cambiar de
/// organizacion la pila se reinicia sobre `home` y esta ruta se descarta.
///
/// Se abre para cualquier Membership ACTIVE y cada seccion se decide por el
/// `MembershipRole` de la organizacion activa (nunca por el rol global):
///
/// - OWNER/ADMIN: General, catalogos y miembros.
/// - ADMIN/DEVELOPER/MEMBER: `Abandonar organizacion` en la Zona de peligro.
/// - OWNER: `Eliminar organizacion` (pendiente) y el aviso de que no puede
///   abandonar sin transferir la propiedad.
///
/// Es control visual: la autoridad final es el backend, que responde 403 en
/// cada endpoint administrativo y 409 si el OWNER intenta abandonar.
///
/// Abandonar sigue el mismo camino que cualquier cambio de pertenencia: con el
/// exito de `POST .../leave` se pide `AuthUserContextRefreshRequested` y
/// `AuthBloc` resuelve la nueva organizacion activa. El reinicio de la pila lo
/// hace el listener central de `app.dart` cuando cambia (o se pierde) la
/// organizacion activa; esta pantalla no navega por su cuenta.
class OrganizationSettingsPage extends StatelessWidget {
  const OrganizationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final organization = authState.activeOrganization;
    final role = organization?.role ?? '';

    // Desde que se confirma el abandono hasta que `AuthBloc` termina de
    // recargar `/me/context` la pantalla no se puede cerrar: el reinicio de la
    // navegacion lo decide el resultado del contexto.
    final isLeaving = context.select<MembershipBloc, bool>(
      (bloc) =>
          bloc.state.leaveStatus != LeaveOrganizationStatus.idle &&
          bloc.state.leaveStatus != LeaveOrganizationStatus.error,
    );

    return BlocListener<MembershipBloc, MembershipState>(
      listenWhen: (previous, current) =>
          previous.leaveStatus != current.leaveStatus,
      listener: _onLeaveStatusChanged,
      child: PopScope(
        canPop: !isLeaving,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Configuracion de organizacion'),
            actions: const [ActiveOrganizationAction()],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _buildBody(
                context,
                organization: organization,
                role: role,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onLeaveStatusChanged(BuildContext context, MembershipState state) {
    switch (state.leaveStatus) {
      case LeaveOrganizationStatus.success:
        // El backend ya saco la organizacion de las memberships ACTIVE: la
        // lista y la organizacion activa las vuelve a resolver `AuthBloc`
        // contra `/me/context`, nunca esta pantalla.
        context.read<AuthBloc>().add(const AuthUserContextRefreshRequested());
      case LeaveOrganizationStatus.error:
        final message = state.leaveErrorMessage.trim();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                message.isEmpty
                    ? 'No se pudo abandonar la organizacion.'
                    : message,
              ),
            ),
          );
      case LeaveOrganizationStatus.idle:
      case LeaveOrganizationStatus.leaving:
        break;
    }
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

    // `Eliminar organizacion` todavia no existe en el backend. Se prepara para
    // el OWNER, que es quien la creo; cuando el flujo real exista habra que
    // confirmar el alcance contra el endpoint.
    final isOwner = role.trim().toUpperCase() == MembershipRole.ownerApiValue;
    final canManageMembers = MembershipRole.canManageMembers(role);
    final canManageCatalogs = MembershipRole.canManageCatalogs(role);
    final canLeave = MembershipRole.canLeaveOrganization(role);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _OrganizationHeaderCard(organization: organization),
        if (canManageMembers) ...[
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
        ],
        if (canManageCatalogs) ...[
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
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.workModules),
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
        ],
        if (canManageMembers) ...[
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
        ],
        // Visible para todos los roles: su contenido cambia segun el rol
        // (abandonar para ADMIN/DEVELOPER/MEMBER, eliminar para OWNER).
        const SizedBox(height: AppSpacing.xl),
        _DangerZoneSection(
          organizationName: organization.displayName,
          isOwner: isOwner,
          canLeave: canLeave,
        ),
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

/// `Zona de peligro` de la organizacion activa.
///
/// Reune dos acciones de alcance distinto, y el texto de cada una lo deja
/// explicito:
///
/// - `Abandonar organizacion` (ADMIN/DEVELOPER/MEMBER): afecta solo a la
///   membresia del usuario actual; la organizacion y sus datos siguen
///   existiendo.
/// - `Eliminar organizacion` (OWNER): se pinta deshabilitada a proposito. El
///   backend no expone todavia ningun endpoint de eliminacion.
///
/// El OWNER no ve `Abandonar`: el backend responde 409 mientras siga siendo
/// OWNER y la transferencia de propiedad todavia no existe.
class _DangerZoneSection extends StatelessWidget {
  const _DangerZoneSection({
    required this.organizationName,
    required this.isOwner,
    required this.canLeave,
  });

  final String organizationName;
  final bool isOwner;
  final bool canLeave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final tiles = <Widget>[
      if (canLeave) _LeaveOrganizationTile(organizationName: organizationName),
      if (isOwner) ...[
        ListTile(
          leading: Icon(
            Icons.info_outline_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          title: const Text('Abandonar organizacion'),
          subtitle: const Text(
            'Para abandonar la organizacion primero debes transferir la '
            'propiedad.',
          ),
        ),
        ListTile(
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
      ],
    ];

    // Un rol que este frontend no conoce no tiene ninguna accion para ofrecer.
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zona de peligro',
          style: textTheme.titleSmall?.copyWith(color: colorScheme.error),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Acciones irreversibles. Abandonar afecta solo a tu membresia; '
          'eliminar afectaria a toda la organizacion.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: tiles),
        ),
      ],
    );
  }
}

/// `Abandonar organizacion` del usuario actual.
///
/// Pide confirmacion antes de emitir `LeaveOrganizationRequested` y, mientras
/// el abandono y la recarga posterior de `/me/context` estan en curso, queda
/// deshabilitada con un indicador de progreso: no hay doble submit. Si el
/// backend falla se vuelve a habilitar para reintentar.
class _LeaveOrganizationTile extends StatelessWidget {
  const _LeaveOrganizationTile({required this.organizationName});

  final String organizationName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final leaveStatus = context.select<MembershipBloc, LeaveOrganizationStatus>(
      (bloc) => bloc.state.leaveStatus,
    );
    final isBusy =
        leaveStatus == LeaveOrganizationStatus.leaving ||
        leaveStatus == LeaveOrganizationStatus.success;

    return ListTile(
      enabled: !isBusy,
      leading: Icon(Icons.logout_rounded, color: colorScheme.error),
      title: Text(
        'Abandonar organizacion',
        style: TextStyle(color: isBusy ? null : colorScheme.error),
      ),
      subtitle: Text(
        leaveStatus == LeaveOrganizationStatus.success
            ? 'Actualizando tus organizaciones...'
            : 'Pierdes el acceso a esta organizacion. La organizacion y sus '
                  'datos no se eliminan.',
      ),
      trailing: isBusy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: isBusy ? null : () => _confirmAndLeave(context),
    );
  }

  Future<void> _confirmAndLeave(BuildContext context) async {
    final bloc = context.read<MembershipBloc>();
    final name = organizationName.trim();
    final target = name.isEmpty ? 'esta organizacion' : name;
    final errorColor = Theme.of(context).colorScheme.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(
          name.isEmpty ? 'Abandonar organizacion' : 'Abandonar $name',
        ),
        content: Text(
          'Vas a abandonar $target.\n\n'
          'Perderas el acceso a ella y dejara de aparecer entre tus '
          'organizaciones. La organizacion y sus datos no se eliminan.\n\n'
          'Solo podras volver si alguien de la organizacion te envia una '
          'nueva invitacion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: errorColor),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abandonar organizacion'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    bloc.add(const LeaveOrganizationRequested());
  }
}

/// Estado vacio de la pantalla: sin organizacion activa.
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
