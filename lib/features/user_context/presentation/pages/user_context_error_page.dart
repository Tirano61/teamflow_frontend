import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Estado de error cuando `GET /me/context` no pudo cargarse.
///
/// Sin contexto no se puede decidir el destino del usuario ni entrar al
/// Workspace, por eso se ofrece reintentar la carga.
class UserContextErrorPage extends StatelessWidget {
  const UserContextErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state.isUserContextLoading;
          final detail = state.userContextErrorMessage.trim();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 40,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No pudimos cargar tu contexto',
                      style: textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tu sesion esta activa, pero falta la informacion de tus '
                      'organizaciones para abrir el espacio de trabajo.',
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        detail,
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => context.read<AuthBloc>().add(
                              const AuthUserContextRetryRequested(),
                            ),
                      child: Text(isLoading ? 'Reintentando...' : 'Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
