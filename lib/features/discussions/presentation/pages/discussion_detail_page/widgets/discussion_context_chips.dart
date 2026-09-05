import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_radius.dart';

/// Construye los chips de contexto (aplicaciones / indicadores) del encabezado.
///
/// Devuelve una lista para poder mezclar varios grupos dentro de un mismo
/// [Wrap] sin anidar layouts.
List<Widget> buildDiscussionContextChips({
  required String label,
  required List<String> values,
  String? emptyLabel,
  VoidCallback? onTap,
}) {
  final canTap = onTap != null;

  Widget wrapChip(Widget chip) {
    if (!canTap) {
      return chip;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: chip,
    );
  }

  if (values.isEmpty) {
    return [
      wrapChip(
        Chip(
          visualDensity: VisualDensity.compact,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emptyLabel ?? '$label: Sin asignar'),
              if (canTap) ...[
                const SizedBox(width: 4),
                const Icon(Icons.add_rounded, size: 14),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  const visibleCount = 3;
  final visible = values.take(visibleCount).toList(growable: false);
  final overflow = values.length - visible.length;

  final result = <Widget>[];
  for (final value in visible) {
    result.add(
      wrapChip(
        Chip(
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '$label: $value',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canTap) ...[
                const SizedBox(width: 4),
                const Icon(Icons.edit_outlined, size: 13),
              ],
            ],
          ),
        ),
      ),
    );
  }

  if (overflow > 0) {
    result.add(
      wrapChip(
        Chip(
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          label: Text('+$overflow'),
        ),
      ),
    );
  }

  return result;
}
