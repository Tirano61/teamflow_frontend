import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Accion `Invitaciones` de la pantalla de Miembros.
///
/// Solo se pinta si el rol del usuario en la organizacion activa
/// (`AuthState.activeOrganization`) puede administrar invitaciones. Es control
/// visual: la autoridad final sigue siendo el backend, que responde 403 si el
/// rol no alcanza.
class OrganizationInvitationsAction extends StatelessWidget {
  const OrganizationInvitationsAction({super.key});

  /// Roles de membresia que pueden listar y cancelar invitaciones segun el
  /// backend.
  ///
  /// `MEMBER` y `DEVELOPER` no ven la accion.
  static const Set<String> _rolesAllowedToManage = <String>{'OWNER', 'ADMIN'};

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthBloc, String>(
      (bloc) => bloc.state.activeOrganization?.role ?? '',
    );

    if (!_rolesAllowedToManage.contains(role.trim().toUpperCase())) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () =>
          Navigator.of(context).pushNamed(AppRoutes.organizationInvitations),
      icon: const Icon(Icons.outgoing_mail),
      tooltip: 'Invitaciones',
    );
  }
}
