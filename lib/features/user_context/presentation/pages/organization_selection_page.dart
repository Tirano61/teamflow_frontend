import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../organization_invitations/presentation/bloc/organization_invitation_bloc.dart';
import '../../../organization_invitations/presentation/widgets/pending_invitations_section.dart';
import '../../../organizations/presentation/bloc/organization_bloc.dart';
import '../../../organizations/presentation/widgets/create_organization_action.dart';
import '../../domain/entities/pending_invitation.dart';
import '../../domain/entities/user_organization.dart';
import '../widgets/organization_role_chip.dart';

/// Contexto desde el que se abre [OrganizationSelectionPage].
///
/// La lista de organizaciones y el evento de seleccion son los mismos en ambos
/// modos; solo cambian los textos, la accion de la AppBar, el marcado de la
/// organizacion activa y si se muestran las invitaciones pendientes.
enum OrganizationSelectionMode {
  /// Paso posterior al login: todavia no hay organizacion activa.
  postLogin,

  /// Cambio de organizacion desde el Workspace: ya hay una organizacion activa.
  switchOrganization,
}

/// Seleccion de organizacion activa y punto de acceso a `Crear organizacion`.
///
/// En [OrganizationSelectionMode.postLogin] la decision de mostrar esta
/// pantalla la toma `PostAuthDestinationResolver`; en
/// [OrganizationSelectionMode.switchOrganization] se abre como ruta desde el
/// flujo principal, tambien cuando el usuario tiene una sola organizacion:
/// crear otra no depende de cuantas tenga ni del rol que tenga en la activa.
/// En los dos casos aca solo se lista el contexto y se emite el evento de
/// seleccion. Aceptar una invitacion o crear una organizacion no eligen
/// organizacion por el usuario: solo recargan el contexto y esta pantalla
/// vuelve a resolverse con la lista nueva.
class OrganizationSelectionPage extends StatelessWidget {
  const OrganizationSelectionPage({
    super.key,
    this.mode = OrganizationSelectionMode.postLogin,
  });

  final OrganizationSelectionMode mode;

  @override
  Widget build(BuildContext context) {
    // Crear organizacion esta disponible en los dos modos, asi que el
    // `OrganizationBloc` acompana siempre a la pantalla. Es factory: se cierra
    // con la ruta y no deja estado de una creacion anterior.
    //
    // Las invitaciones pendientes, en cambio, pertenecen al onboarding: el
    // cambio desde el Workspace no las muestra y no necesita su bloc.
    if (mode == OrganizationSelectionMode.switchOrganization) {
      return BlocProvider<OrganizationBloc>(
        create: (_) => sl<OrganizationBloc>(),
        child: const _OrganizationSelectionView(
          mode: OrganizationSelectionMode.switchOrganization,
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<OrganizationBloc>(create: (_) => sl<OrganizationBloc>()),
        BlocProvider<OrganizationInvitationBloc>(
          create: (_) => sl<OrganizationInvitationBloc>(),
        ),
      ],
      child: const _OrganizationSelectionView(
        mode: OrganizationSelectionMode.postLogin,
      ),
    );
  }
}

class _OrganizationSelectionView extends StatelessWidget {
  const _OrganizationSelectionView({required this.mode});

  final OrganizationSelectionMode mode;

  bool get _isSwitching => mode == OrganizationSelectionMode.switchOrganization;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authState = context.watch<AuthBloc>().state;
    final userContext = authState.userContext;
    final organizations =
        userContext?.organizations ?? const <UserOrganization>[];
    final pendingInvitations =
        userContext?.pendingInvitations ?? const <PendingInvitation>[];
    final canSwitch = authState.canSwitchOrganization;

    // Mientras se recarga `/me/context` (por ejemplo tras crear una
    // organizacion) la lista todavia es la vieja: elegir ahora competiria con
    // la organizacion que esta por quedar activa.
    final isRefreshingContext = authState.isUserContextLoading;

    // Solo se marca una organizacion activa en el cambio desde el Workspace:
    // despues del login todavia no hay ninguna elegida.
    final activeOrganizationId = _isSwitching
        ? authState.activeOrganizationId
        : '';

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(
          _isSwitching && canSwitch ? 'Cambiar organizacion' : 'Organizaciones',
        ),
        actions: [
          if (!_isSwitching)
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
                _headline(canSwitch: canSwitch),
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _description(canSwitch: canSwitch),
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final organization in organizations) ...[
                _OrganizationCard(
                  organization: organization,
                  isActive: organization.id == activeOrganizationId,
                  onTap: isRefreshingContext
                      ? null
                      : () => _onOrganizationTap(
                          context,
                          organization: organization,
                          activeOrganizationId: activeOrganizationId,
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.lg),
              // Crear una organizacion no depende de cuantas tenga el usuario
              // ni del rol que tenga en la activa: el creador queda como OWNER
              // de la nueva, y eso lo decide el backend.
              Text('Crear una organizacion', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tu organizacion actual no cambia hasta que la nueva este '
                'creada y confirmada.',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              const CreateOrganizationAction(),
              if (!_isSwitching && pendingInvitations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
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

    if (!_isSwitching) {
      return scaffold;
    }

    // Modo cambio: esta pantalla es una ruta apilada sobre el Workspace. Si
    // `/me/context` falla (por ejemplo al recargarlo despues de crear una
    // organizacion) ya no queda lista que mostrar, asi que se cierra el
    // selector y decide `AuthGatePage`, que muestra el error recuperable con
    // su reintento de contexto. La organizacion ya creada no se vuelve a crear.
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.userContext != null && current.userContext == null,
      listener: (context, state) => Navigator.of(context).maybePop(),
      child: scaffold,
    );
  }

  String _headline({required bool canSwitch}) {
    if (!_isSwitching) {
      return 'Selecciona una organizacion';
    }

    return canSwitch ? 'Cambia de organizacion' : 'Tus organizaciones';
  }

  String _description({required bool canSwitch}) {
    if (!_isSwitching) {
      return 'Tu cuenta pertenece a varias organizaciones. '
          'Elige con cual quieres trabajar.';
    }

    if (canSwitch) {
      return 'Se abrira el Workspace de la organizacion que elijas. '
          'La organizacion actual esta marcada.';
    }

    return 'Por ahora trabajas en una sola organizacion, la marcada como '
        'activa.';
  }

  void _onOrganizationTap(
    BuildContext context, {
    required UserOrganization organization,
    required String activeOrganizationId,
  }) {
    // Volver a elegir la organizacion activa solo cierra el selector: no se
    // reinicia el Workspace por una seleccion que no cambia nada.
    if (organization.id == activeOrganizationId) {
      Navigator.of(context).pop();
      return;
    }

    // La navegacion posterior no se decide aca: al cambiar la organizacion
    // activa, el listener central de `MyApp` reinicia la pila sobre el
    // Workspace y cierra este selector.
    context.read<AuthBloc>().add(AuthOrganizationSelected(organization.id));
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({
    required this.organization,
    required this.onTap,
    this.isActive = false,
  });

  final UserOrganization organization;

  /// `null` deshabilita la tarjeta: se usa mientras se recarga el contexto.
  final VoidCallback? onTap;

  /// La organizacion es la que esta activa en el Workspace.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final name = organization.displayName;
    final slug = organization.slug.trim();

    return Card(
      shape: isActive
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: colorScheme.primary),
            )
          : null,
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
                    if (isActive) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Organizacion activa',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
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
              Icon(
                isActive
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
