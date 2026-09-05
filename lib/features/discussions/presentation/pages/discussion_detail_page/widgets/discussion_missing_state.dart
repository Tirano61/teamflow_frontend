import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';

class DiscussionMissingState extends StatelessWidget {
  const DiscussionMissingState({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No se encontraron datos para la discussion.'),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
