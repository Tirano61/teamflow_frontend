import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../components/domain/entities/component.dart';
import '../../../../../tags/domain/entities/tag.dart';
import '../../../../../work_modules/domain/entities/work_module.dart';
import '../../../../domain/entities/discussion.dart';
import '../discussion_advanced_filter_selection.dart';

/// Contenido reutilizable de los filtros avanzados (dialog y bottom sheet).
class DiscussionAdvancedFiltersContent extends StatefulWidget {
  const DiscussionAdvancedFiltersContent({
    required this.initialSelection,
    required this.workModules,
    required this.components,
    required this.tags,
    required this.onClose,
    super.key,
  });

  final DiscussionAdvancedFilterSelection initialSelection;
  final List<WorkModule> workModules;
  final List<Component> components;
  final List<Tag> tags;
  final ValueChanged<DiscussionAdvancedFilterSelection?> onClose;

  @override
  State<DiscussionAdvancedFiltersContent> createState() =>
      _DiscussionAdvancedFiltersContentState();
}

class _DiscussionAdvancedFiltersContentState
    extends State<DiscussionAdvancedFiltersContent> {
  late DiscussionType? _type;
  late Set<String> _workModuleIds;
  late Set<String> _componentIds;
  late Set<String> _tagIds;

  @override
  void initState() {
    super.initState();
    _type = widget.initialSelection.type;
    _workModuleIds = Set<String>.from(widget.initialSelection.moduleIds);
    _componentIds = Set<String>.from(widget.initialSelection.componentIds);
    _tagIds = Set<String>.from(widget.initialSelection.tagIds);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros avanzados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipo', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: _type == null,
                          onSelected: (_) => setState(() => _type = null),
                        ),
                        for (final type in DiscussionType.values.where(
                          (value) => value != DiscussionType.unknown,
                        ))
                          ChoiceChip(
                            label: Text(_typeLabel(type)),
                            selected: _type == type,
                            onSelected: (_) => setState(() => _type = type),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSelectorSection(
                      title: 'Aplicaciones',
                      items: widget.workModules
                          .where((item) => item.id != null)
                          .toList(growable: false),
                      selectedIds: _workModuleIds,
                      idBuilder: (item) => item.id,
                      labelBuilder: (item) => item.name,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSelectorSection(
                      title: 'Indicadores',
                      items: widget.components
                          .where((item) => item.id != null)
                          .toList(growable: false),
                      selectedIds: _componentIds,
                      idBuilder: (item) => item.id,
                      labelBuilder: (item) => item.name,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSelectorSection(
                      title: 'Tags',
                      items: widget.tags
                          .where((item) => item.id != null)
                          .toList(growable: false),
                      selectedIds: _tagIds,
                      idBuilder: (item) => item.id,
                      labelBuilder: (item) => item.name,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _type = null;
                      _workModuleIds.clear();
                      _componentIds.clear();
                      _tagIds.clear();
                    });
                  },
                  child: const Text('Limpiar'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => widget.onClose(null),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () {
                    widget.onClose(
                      DiscussionAdvancedFilterSelection(
                        type: _type,
                        moduleIds: Set<String>.from(_workModuleIds),
                        componentIds: Set<String>.from(_componentIds),
                        tagIds: Set<String>.from(_tagIds),
                      ),
                    );
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorSection<T>({
    required String title,
    required List<T> items,
    required Set<String> selectedIds,
    required String? Function(T item) idBuilder,
    required String Function(T item) labelBuilder,
  }) {
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sin datos disponibles.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in items)
              FilterChip(
                label: Text(labelBuilder(item)),
                selected: selectedIds.contains(idBuilder(item)),
                onSelected: (selected) {
                  final id = idBuilder(item);
                  if (id == null || id.isEmpty) {
                    return;
                  }

                  setState(() {
                    if (selected) {
                      selectedIds.add(id);
                    } else {
                      selectedIds.remove(id);
                    }
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  String _typeLabel(DiscussionType type) {
    switch (type) {
      case DiscussionType.error:
        return 'Error';
      case DiscussionType.idea:
        return 'Idea';
      case DiscussionType.improvement:
        return 'Mejora';
      case DiscussionType.question:
        return 'Consulta';
      case DiscussionType.unknown:
        return 'Otro';
    }
  }
}
