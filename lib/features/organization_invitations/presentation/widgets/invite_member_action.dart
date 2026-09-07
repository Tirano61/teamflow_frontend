import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Accion `Invitar miembro` de la pantalla de Miembros.
///
/// Solo se pinta si el rol del usuario en la organizacion activa
/// (`AuthState.activeOrganization`) puede invitar. Es control visual: la
/// autoridad final sigue siendo el backend, que responde 403 si el rol no
/// alcanza.
///
/// Abre el flujo de invitacion como ruta propia y muestra la confirmacion al
/// volver: la pantalla que envio la invitacion ya no existe en ese momento.
class InviteMemberAction extends StatelessWidget {
  const InviteMemberAction({super.key});

  /// Roles de membresia que pueden invitar segun el backend.
  ///
  /// `MEMBER` y `DEVELOPER` no ven la accion.
  static const Set<String> _rolesAllowedToInvite = <String>{'OWNER', 'ADMIN'};

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthBloc, String>(
      (bloc) => bloc.state.activeOrganization?.role ?? '',
    );

    if (!_rolesAllowedToInvite.contains(role.trim().toUpperCase())) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () => _openInviteFlow(context),
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Invitar miembro'),
    );
  }

  Future<void> _openInviteFlow(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(
      context,
    ).pushNamed<Object?>(AppRoutes.organizationInvite);

    // Vuelve vacio si el usuario cancelo: no hay nada que confirmar.
    final recipient = result is String ? result.trim() : '';
    if (recipient.isEmpty) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Invitacion enviada a $recipient')),
      );
  }
}
