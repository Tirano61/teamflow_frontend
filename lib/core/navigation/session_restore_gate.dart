import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'post_auth_destination.dart';

/// Retiene una ruta del Workspace hasta que la sesion y la organizacion activa
/// esten resueltas.
///
/// En Flutter Web el `Navigator` reconstruye la pila desde la URL al recargar
/// (`#/discussions`, `#/discussions/detail?id=...`), antes de que `AuthBloc`
/// valide la sesion con `GET /me/context` y restaure la organizacion activa.
/// Sin esta espera la pantalla tenant se crearia sin `OrganizationContext` y
/// sus blocs pedirian datos sin organizacion.
///
/// No decide el destino: solo libera la ruta cuando
/// [PostAuthDestinationResolver] resuelve `workspace`. Cualquier otro destino
/// (login, seleccion, sin organizacion, error de contexto) lo aplica el
/// listener de autenticacion de `MyApp`, que reinicia la pila; mientras tanto
/// aca se muestra la espera y nunca contenido protegido.
///
/// Una vez liberada, la ruta queda liberada: los cambios posteriores de sesion
/// u organizacion los sigue manejando el flujo existente (reinicio de pila),
/// no este widget.
class SessionRestoreGate extends StatefulWidget {
  const SessionRestoreGate({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<SessionRestoreGate> createState() => _SessionRestoreGateState();
}

class _SessionRestoreGateState extends State<SessionRestoreGate> {
  bool _released = false;

  @override
  Widget build(BuildContext context) {
    // El `BlocBuilder` se mantiene aun liberada la ruta para que el arbol no
    // cambie de forma: si cambiara, Flutter recrearia la pagina y sus blocs.
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (_, _) => !_released,
      builder: (context, state) {
        if (!_released &&
            PostAuthDestinationResolver.resolve(state) !=
                PostAuthDestination.workspace) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _released = true;
        return widget.builder(context);
      },
    );
  }
}
