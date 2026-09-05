import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../organization_invitations/presentation/bloc/organization_invitation_bloc.dart';
import '../../../organization_invitations/presentation/widgets/pending_invitations_section.dart';
import '../../../organizations/presentation/bloc/organization_bloc.dart';
import '../../../organizations/presentation/bloc/organization_event.dart';
import '../../../organizations/presentation/bloc/organization_state.dart';
import '../../../organizations/presentation/widgets/create_organization_dialog.dart';
import '../../domain/entities/pending_invitation.dart';

/// Onboarding para usuarios que todavia no pertenecen a ninguna organizacion.
///
/// Ofrece las dos unicas salidas posibles: crear una organizacion propia o
/// aceptar una invitacion pendiente. Ninguna de las dos navega a mano: ambas
/// terminan recargando `/me/context` y dejan que `AuthGatePage` resuelva el
/// destino.
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

    return BlocListener<OrganizationBloc, OrganizationState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onOrganizationStateChanged,
      child: Scaffold(
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
                const _CreateOrganizationButton(),
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
      ),
    );
  }

  void _onOrganizationStateChanged(
    BuildContext context,
    OrganizationState state,
  ) {
    switch (state.status) {
      case OrganizationStatus.success:
        final name = state.createdOrganization?.name.trim() ?? '';
        _showMessage(
          context,
          name.isEmpty
              ? 'Organizacion creada.'
              : 'Organizacion "$name" creada.',
        );
        // Con el contexto recargado la organizacion recien creada queda como
        // unica: `AuthBloc` la autoselecciona y `AuthGatePage` abre el
        // Workspace sin navegacion manual.
        context.read<AuthBloc>().add(const AuthUserContextRefreshRequested());
      case OrganizationStatus.error:
        _showMessage(context, state.errorMessage);
      case OrganizationStatus.initial:
      case OrganizationStatus.creating:
        break;
    }
  }

  void _showMessage(BuildContext context, String message) {
    final text = message.trim();
    if (text.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _CreateOrganizationButton extends StatelessWidget {
  const _CreateOrganizationButton();

  @override
  Widget build(BuildContext context) {
    // Tras crear se recarga `/me/context`: hasta que termine no se admite otra
    // creacion, para no perder el refresh siguiente.
    final isRefreshingContext = context
        .watch<AuthBloc>()
        .state
        .isUserContextLoading;

    return BlocBuilder<OrganizationBloc, OrganizationState>(
      builder: (context, state) {
        return ElevatedButton.icon(
          onPressed: state.isCreating || isRefreshingContext
              ? null
              : () => _openCreateOrganizationDialog(context),
          icon: state.isCreating
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_business_outlined),
          label: Text(
            state.isCreating ? 'Creando...' : 'Crear organizacion',
          ),
        );
      },
    );
  }

  Future<void> _openCreateOrganizationDialog(BuildContext context) async {
    final bloc = context.read<OrganizationBloc>();
    final name = await showCreateOrganizationDialog(context);

    if (name == null || name.isEmpty) {
      return;
    }

    bloc.add(CreateOrganizationRequested(name));
  }
}
