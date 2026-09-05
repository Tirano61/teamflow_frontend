import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../discussion_view_filter.dart';

/// Barra superior del tablero con los filtros rapidos y la accion de crear.
class DiscussionBoardTopBar extends StatelessWidget {
  const DiscussionBoardTopBar({
    required this.isDeveloper,
    required this.isKanban,
    required this.viewFilter,
    required this.unreadOnly,
    required this.hasAdvancedFilters,
    required this.onViewFilterSelected,
    required this.onUnreadOnlyChanged,
    required this.onOpenAdvancedFilters,
    required this.onClearAdvancedFilters,
    required this.onRefresh,
    required this.onCreateDiscussion,
    super.key,
  });

  final bool isDeveloper;
  final bool isKanban;
  final DiscussionViewFilter viewFilter;
  final bool unreadOnly;
  final bool hasAdvancedFilters;
  final ValueChanged<DiscussionViewFilter> onViewFilterSelected;
  final ValueChanged<bool> onUnreadOnlyChanged;
  final VoidCallback onOpenAdvancedFilters;
  final VoidCallback onClearAdvancedFilters;
  final VoidCallback onRefresh;
  final VoidCallback onCreateDiscussion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilterChip(
                      label: const Text('Todas'),
                      selected: viewFilter == DiscussionViewFilter.all,
                      onSelected: (_) =>
                          onViewFilterSelected(DiscussionViewFilter.all),
                    ),
                    FilterChip(
                      label: const Text('Mis discussions'),
                      selected: viewFilter == DiscussionViewFilter.mine,
                      onSelected: (_) =>
                          onViewFilterSelected(DiscussionViewFilter.mine),
                    ),
                    if (isDeveloper)
                      FilterChip(
                        label: const Text('Asignadas a mi'),
                        selected:
                            viewFilter == DiscussionViewFilter.assignedToMe,
                        onSelected: (_) => onViewFilterSelected(
                          DiscussionViewFilter.assignedToMe,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilterChip(
                      label: const Text('No leídas'),
                      selected: unreadOnly,
                      onSelected: onUnreadOnlyChanged,
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpenAdvancedFilters,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Filtros'),
                    ),
                    if (hasAdvancedFilters)
                      OutlinedButton(
                        onPressed: onClearAdvancedFilters,
                        child: const Text('Limpiar filtros'),
                      ),
                    OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isKanban) ...[
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: onCreateDiscussion,
              icon: const Icon(Icons.add),
              label: const Text('Nueva discussion'),
            ),
          ],
        ],
      ),
    );
  }
}
