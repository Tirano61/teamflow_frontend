import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../domain/entities/discussion.dart';
import '../../../bloc/discussion_bloc.dart';
import '../discussion_attachment_option.dart';
import '../discussion_detail_helpers.dart';
import 'discussion_assignable_developers_list.dart';
import 'discussion_catalog_list.dart';

/// Bottom sheet para cambiar el estado de la discussion en layout compacto.
Future<DiscussionRecordStatus?> showDiscussionStatusSheet(
  BuildContext context,
  Discussion discussion,
) {
  return showModalBottomSheet<DiscussionRecordStatus>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text('Cambiar estado', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            for (final status in DiscussionRecordStatus.values.where(
              (status) => status != DiscussionRecordStatus.unknown,
            ))
              ListTile(
                title: Text(discussionStatusLabel(status)),
                trailing: status == discussion.status
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(sheetContext, status),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}

/// Opciones de adjunto en layout compacto.
Future<AttachmentOption?> showAttachmentOptionsSheet(BuildContext context) {
  return showModalBottomSheet<AttachmentOption>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text('Adjuntar', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            ...AttachmentOption.values.map(
              (option) => ListTile(
                leading: Icon(option.icon),
                title: Text(option.label),
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}

/// Opciones de adjunto en escritorio, ancladas al composer.
Future<AttachmentOption?> showAttachmentOptionsMenu(BuildContext context) async {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null) {
    return null;
  }

  final position = RelativeRect.fromLTRB(
    box.size.width - 220,
    box.size.height - 140,
    12,
    12,
  );

  return showMenu<AttachmentOption>(
    context: context,
    position: position,
    items: [
      for (final option in AttachmentOption.values)
        PopupMenuItem<AttachmentOption>(
          value: option,
          child: Row(
            children: [
              Icon(option.icon, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(option.label),
            ],
          ),
        ),
    ],
  );
}

Future<Set<String>?> showDiscussionCatalogSelectorDialog<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required Set<String> selectedIds,
  required String Function(T) idOf,
  required String Function(T) nameOf,
  required bool isLoading,
}) {
  return showDialog<Set<String>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 420,
              child: DiscussionCatalogList<T>(
                items: items,
                selectedIds: selectedIds,
                idOf: idOf,
                nameOf: nameOf,
                isLoading: isLoading,
                setDialogState: setDialogState,
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
      );
    },
  );
}

Future<Set<String>?> showDiscussionCatalogSelectorSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required Set<String> selectedIds,
  required String Function(T) idOf,
  required String Function(T) nameOf,
  required bool isLoading,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setDialogState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Flexible(
                    child: DiscussionCatalogList<T>(
                      items: items,
                      selectedIds: selectedIds,
                      idOf: idOf,
                      nameOf: nameOf,
                      isLoading: isLoading,
                      setDialogState: setDialogState,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(
                            sheetContext,
                            Set<String>.from(selectedIds),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<Set<String>?> showDiscussionAssignmentsDialog({
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
                child: DiscussionAssignableDevelopersList(
                  selectedIds: selectedIds,
                  setDialogState: setDialogState,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final state = bloc.state;
                    final currentUser =
                        context.read<AuthBloc>().state.session?.user;
                    if (currentUser == null || !currentUser.isDeveloper) {
                      return;
                    }
                    if (!state.assignableDevelopers
                        .any((developer) => developer.id == currentUser.id)) {
                      return;
                    }
                    setDialogState(() {
                      selectedIds.add(currentUser.id);
                    });
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Asignarme'),
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

Future<Set<String>?> showDiscussionAssignmentsSheet({
  required BuildContext context,
  required DiscussionBloc bloc,
  required Set<String> selectedIds,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return BlocProvider.value(
        value: bloc,
        child: StatefulBuilder(
          builder: (sheetContext, setDialogState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Asignar developers',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Flexible(
                      child: DiscussionAssignableDevelopersList(
                        selectedIds: selectedIds,
                        setDialogState: setDialogState,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(
                              sheetContext,
                              Set<String>.from(selectedIds),
                            ),
                            child: const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

Future<bool?> showDeleteDiscussionMessageDialog({
  required BuildContext context,
  required bool isAttachment,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(isAttachment ? '¿Eliminar archivo?' : '¿Eliminar mensaje?'),
        content: Text(
          isAttachment
              ? '¿Eliminar este archivo de la conversación?\nEl archivo también será eliminado.'
              : '¿Eliminar este mensaje?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
}

/// Dialogo de error con texto seleccionable y accion de copiado, usado para
/// los fallos de carga de adjuntos en web.
Future<void> showCopyableErrorDialog({
  required BuildContext context,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Error de carga de video'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            child: SelectableText(message),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Error copiado al portapapeles.'),
                  ),
                );
            },
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Copiar error'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      );
    },
  );
}
