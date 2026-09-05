import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../components/domain/entities/component.dart';
import '../../../../../tags/domain/entities/tag.dart';
import '../../../../../work_modules/domain/entities/work_module.dart';
import '../../../bloc/discussion_bloc.dart';
import '../../../bloc/discussion_state.dart';
import '../discussion_advanced_filter_selection.dart';
import 'discussion_advanced_filters_content.dart';

/// Filtros avanzados en escritorio.
Future<DiscussionAdvancedFilterSelection?> showDiscussionAdvancedFiltersDialog({
  required BuildContext context,
  required DiscussionAdvancedFilterSelection selection,
  required List<WorkModule> workModules,
  required List<Component> components,
  required List<Tag> tags,
}) {
  return showDialog<DiscussionAdvancedFilterSelection>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        clipBehavior: Clip.antiAlias,
        child: DiscussionAdvancedFiltersContent(
          initialSelection: selection,
          workModules: workModules,
          components: components,
          tags: tags,
          onClose: (result) => Navigator.pop(dialogContext, result),
        ),
      );
    },
  );
}

/// Filtros avanzados en layout compacto.
Future<DiscussionAdvancedFilterSelection?> showDiscussionAdvancedFiltersSheet({
  required BuildContext context,
  required DiscussionAdvancedFilterSelection selection,
  required List<WorkModule> workModules,
  required List<Component> components,
  required List<Tag> tags,
}) {
  return showModalBottomSheet<DiscussionAdvancedFilterSelection>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: DiscussionAdvancedFiltersContent(
            initialSelection: selection,
            workModules: workModules,
            components: components,
            tags: tags,
            onClose: (result) => Navigator.pop(sheetContext, result),
          ),
        ),
      );
    },
  );
}

/// Dialog para asignar developers desde una card del tablero.
Future<Set<String>?> showDiscussionBoardAssignmentsDialog({
  required BuildContext context,
  required DiscussionBloc bloc,
  required Set<String> selectedIds,
}) {
  return showDialog<Set<String>>(
    context: context,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: bloc,
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Asignar developers'),
              content: SizedBox(
                width: 420,
                child: BlocBuilder<DiscussionBloc, DiscussionState>(
                  builder: (context, state) {
                    if (state.isLoadingAssignableDevelopers &&
                        state.assignableDevelopers.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.assignableDevelopers.isEmpty) {
                      return const Text('No hay developers disponibles.');
                    }

                    return SingleChildScrollView(
                      child: Column(
                        children: state.assignableDevelopers
                            .map(
                              (developer) => CheckboxListTile(
                                dense: true,
                                value: selectedIds.contains(developer.id),
                                title: Text(developer.fullName),
                                subtitle: developer.email == null
                                    ? null
                                    : Text(developer.email!),
                                onChanged: (checked) {
                                  setDialogState(() {
                                    if (checked == true) {
                                      selectedIds.add(developer.id);
                                    } else {
                                      selectedIds.remove(developer.id);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, Set<String>.from(selectedIds)),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
