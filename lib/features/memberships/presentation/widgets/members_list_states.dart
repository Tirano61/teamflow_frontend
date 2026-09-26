import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Estado vacio del directorio de miembros.
class MembersEmptyState extends StatelessWidget {
  const MembersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Esta organizacion no tiene miembros para mostrar.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error cargando el directorio de miembros, con reintento.
///
/// [message] es el mensaje del `Failure` mapeado, nunca la excepcion cruda.
class MembersErrorState extends StatelessWidget {
  const MembersErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detail = message.trim();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No se pudieron cargar los miembros.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
