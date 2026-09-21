import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';
import 'create_organization_dialog.dart';

/// Accion `Crear organizacion` reutilizable.
///
/// Es el unico punto de entrada de la creacion en la UI: lo comparten el
/// onboarding (`NoOrganizationPage`, usuario sin organizaciones) y el selector
/// (`OrganizationSelectionPage`, en sus dos modos). No depende del rol del
/// usuario en la organizacion activa: crear una organizacion propia es una
/// accion global de la cuenta.
///
/// Requiere un `OrganizationBloc` y un `AuthBloc` en el arbol.
///
/// Cuando `POST /organizations` termina bien no navega ni toca
/// `OrganizationContext`: avisa a `AuthBloc` con [AuthOrganizationCreated],
/// que recarga `/me/context` y deja activa la organizacion nueva solo si el
/// backend la devuelve entre las memberships del usuario. Si la creacion falla
/// no se cambia de organizacion y se puede reintentar.
class CreateOrganizationAction extends StatelessWidget {
  const CreateOrganizationAction({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganizationBloc, OrganizationState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onOrganizationStateChanged,
      child: const _CreateOrganizationButton(),
    );
  }

  void _onOrganizationStateChanged(
    BuildContext context,
    OrganizationState state,
  ) {
    switch (state.status) {
      case OrganizationStatus.success:
        final organization = state.createdOrganization;
        final name = organization?.name.trim() ?? '';
        _showMessage(
          context,
          name.isEmpty
              ? 'Organizacion creada.'
              : 'Organizacion "$name" creada.',
        );
        // El destino final (workspace de la organizacion nueva, selector u
        // onboarding) lo decide el `/me/context` recargado, no esta pantalla.
        context.read<AuthBloc>().add(
          AuthOrganizationCreated(organization?.id ?? ''),
        );
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
    // creacion, para no perder el refresh siguiente ni crear duplicados.
    final isRefreshingContext = context
        .watch<AuthBloc>()
        .state
        .isUserContextLoading;

    return BlocBuilder<OrganizationBloc, OrganizationState>(
      builder: (context, state) {
        final isBusy = state.isCreating || isRefreshingContext;

        return ElevatedButton.icon(
          onPressed: isBusy
              ? null
              : () => _openCreateOrganizationDialog(context),
          icon: state.isCreating
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_business_outlined),
          label: Text(state.isCreating ? 'Creando...' : 'Crear organizacion'),
        );
      },
    );
  }

  Future<void> _openCreateOrganizationDialog(BuildContext context) async {
    final bloc = context.read<OrganizationBloc>();
    final name = await showCreateOrganizationDialog(context);

    // Cancelar no toca nada: ni `OrganizationContext`, ni la organizacion
    // activa, ni la persistida.
    if (name == null || name.isEmpty) {
      return;
    }

    bloc.add(CreateOrganizationRequested(name));
  }
}
