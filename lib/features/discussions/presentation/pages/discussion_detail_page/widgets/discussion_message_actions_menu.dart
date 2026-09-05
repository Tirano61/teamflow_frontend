import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';

enum _MessageAction { edit, delete }

class DiscussionMessageActionsMenu extends StatelessWidget {
  const DiscussionMessageActionsMenu({
    required this.canEdit,
    required this.canDelete,
    required this.isHovered,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final bool canEdit;
  final bool canDelete;
  final bool isHovered;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // En web solo se muestra el icono al pasar el mouse; en movil siempre.
    final visible = kIsWeb ? isHovered : true;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: visible ? 1.0 : 0.0,
      child: PopupMenuButton<_MessageAction>(
        iconSize: 16,
        padding: EdgeInsets.zero,
        tooltip: 'Acciones del mensaje',
        enabled: !isDeleting,
        icon: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        itemBuilder: (context) => [
          if (canEdit)
            const PopupMenuItem<_MessageAction>(
              value: _MessageAction.edit,
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 16),
                  SizedBox(width: AppSpacing.sm),
                  Text('Editar'),
                ],
              ),
            ),
          if (canDelete)
            PopupMenuItem<_MessageAction>(
              value: _MessageAction.delete,
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onSelected: (action) {
          switch (action) {
            case _MessageAction.edit:
              onEdit();
            case _MessageAction.delete:
              onDelete();
          }
        },
      ),
    );
  }
}
