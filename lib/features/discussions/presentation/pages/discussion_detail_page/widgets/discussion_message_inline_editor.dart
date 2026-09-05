import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';

class DiscussionMessageInlineEditor extends StatelessWidget {
  const DiscussionMessageInlineEditor({
    required this.controller,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 8,
          enabled: !isSubmitting,
          decoration: const InputDecoration(
            hintText: 'Editar mensaje...',
            isDense: true,
          ),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: isSubmitting ? null : onCancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: AppSpacing.xs),
            FilledButton(
              onPressed: isSubmitting ? null : onSave,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ],
    );
  }
}
