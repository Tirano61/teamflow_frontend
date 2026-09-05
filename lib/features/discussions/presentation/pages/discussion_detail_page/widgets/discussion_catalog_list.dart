import 'package:flutter/material.dart';

/// Lista de seleccion multiple reutilizada por los selectores de aplicaciones
/// e indicadores (dialogo en escritorio, bottom sheet en compacto).
class DiscussionCatalogList<T> extends StatelessWidget {
  const DiscussionCatalogList({
    required this.items,
    required this.selectedIds,
    required this.idOf,
    required this.nameOf,
    required this.isLoading,
    required this.setDialogState,
    super.key,
  });

  final List<T> items;
  final Set<String> selectedIds;
  final String Function(T) idOf;
  final String Function(T) nameOf;
  final bool isLoading;
  final void Function(VoidCallback fn) setDialogState;

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return const Center(child: Text('No hay elementos disponibles.'));
    }

    return ListView(
      shrinkWrap: true,
      children: items
          .where((item) => idOf(item).isNotEmpty)
          .map(
            (item) => CheckboxListTile(
              dense: true,
              value: selectedIds.contains(idOf(item)),
              title: Text(nameOf(item)),
              onChanged: (checked) {
                setDialogState(() {
                  if (checked == true) {
                    selectedIds.add(idOf(item));
                  } else {
                    selectedIds.remove(idOf(item));
                  }
                });
              },
            ),
          )
          .toList(growable: false),
    );
  }
}
