import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../applications/domain/entities/application.dart';
import '../../../applications/presentation/bloc/application_bloc.dart';
import '../../../applications/presentation/bloc/application_event.dart';
import '../../../applications/presentation/bloc/application_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../discussion_messages/domain/entities/discussion_message.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_bloc.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_event.dart';
import '../../../discussion_messages/presentation/bloc/discussion_message_state.dart';
import '../../../indicators/domain/entities/indicator.dart';
import '../../../indicators/presentation/bloc/indicator_bloc.dart';
import '../../../indicators/presentation/bloc/indicator_event.dart';
import '../../../indicators/presentation/bloc/indicator_state.dart';
import '../../../tags/presentation/bloc/tag_bloc.dart';
import '../../../tags/presentation/bloc/tag_event.dart';
import '../../domain/entities/discussion.dart';
import '../bloc/discussion_bloc.dart';
import '../bloc/discussion_event.dart';
import '../bloc/discussion_state.dart';

enum _SubmitFlowStage { idle, creatingDiscussion, updatingDiscussion }

class DiscussionEditorPage extends StatefulWidget {
  const DiscussionEditorPage({this.initialDiscussion, this.discussionId, super.key});

  final Discussion? initialDiscussion;
  final String? discussionId;

  @override
  State<DiscussionEditorPage> createState() => _DiscussionEditorPageState();
}

class _DiscussionEditorPageState extends State<DiscussionEditorPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _initialMessageController = TextEditingController();

  final Set<String> _selectedApplicationIds = <String>{};
  final Set<String> _selectedIndicatorIds = <String>{};
  final Set<String> _selectedTagIds = <String>{};
  final List<_PendingAttachment> _pendingAttachments = <_PendingAttachment>[];

  DiscussionType _selectedType = DiscussionType.error;
  DiscussionRecordStatus _status = DiscussionRecordStatus.newDiscussion;
  bool _submitInProgress = false;
  _SubmitFlowStage _submitFlowStage = _SubmitFlowStage.idle;
  String? _createdDiscussionId;
  int _attachmentUploadIndex = 0;
  bool _waitingForAttachmentUpload = false;

  @override
  void initState() {
    super.initState();

    _titleController.addListener(_refreshFormState);
    _initialMessageController.addListener(_refreshFormState);

    context.read<ApplicationBloc>().add(const LoadApplicationsEvent());
    context.read<IndicatorBloc>().add(const LoadIndicatorsEvent());
    context.read<TagBloc>().add(const LoadTagsEvent());

    final initial = widget.initialDiscussion;
    if (initial != null) {
      _applyDiscussion(initial);
      return;
    }

    final id = widget.discussionId?.trim();
    if (id != null && id.isNotEmpty) {
      context.read<DiscussionBloc>().add(LoadDiscussionEvent(id));
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController
      ..removeListener(_refreshFormState)
      ..dispose();
    _initialMessageController
      ..removeListener(_refreshFormState)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar Discussion' : 'Nueva Discussion')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<DiscussionBloc, DiscussionState>(listener: _onDiscussionStateChanged),
          BlocListener<DiscussionMessageBloc, DiscussionMessageState>(listener: _onDiscussionMessageStateChanged),
        ],
        child: BlocBuilder<DiscussionBloc, DiscussionState>(
          builder: (context, state) {
            final applicationState = context.watch<ApplicationBloc>().state;
            final indicatorState = context.watch<IndicatorBloc>().state;
            final isDeveloper = context.watch<AuthBloc>().state.session?.user.isDeveloper ?? false;
            final messageState = context.watch<DiscussionMessageBloc>().state;

            final isLoading = state.status == DiscussionStatus.loading;
            final isUploadingAttachment = _waitingForAttachmentUpload || messageState.isSending;
            final isBusy = isLoading || _submitInProgress || isUploadingAttachment;

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < AppBreakpoints.compact;

                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.lg : AppSpacing.xl, vertical: AppSpacing.lg),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(_isEditing ? 'Actualizar Discussion' : 'Iniciar una conversacion de trabajo', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: AppSpacing.xs),
                                Text(_isEditing ? 'Ajusta los datos principales sin cambiar la conversacion.' : 'Contanos el problema, idea o consulta con el contexto minimo necesario.', style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: AppSpacing.xl),
                                _DiscussionTypeSelector(
                                  selectedType: _selectedType,
                                  enabled: !isBusy,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedType = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                TextField(
                                  controller: _titleController,
                                  enabled: !isBusy,
                                  maxLength: 150,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(labelText: 'Titulo', hintText: 'Resumen breve de lo que esta pasando'),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _OptionalEntitySelector<Application>(title: 'Aplicacion', helperText: 'No aparece la correcta? Deja este campo vacio y mencionala en la descripcion.', catalogActionLabel: 'Administrar aplicaciones', showCatalogAction: isDeveloper, enabled: !isBusy, items: applicationState.applications, selectedIds: _selectedApplicationIds, isLoading: applicationState.status == ApplicationStatus.loading, errorMessage: applicationState.status == ApplicationStatus.error ? applicationState.errorMessage : null, idOf: (item) => item.id, labelOf: (item) => item.name, onRetry: () => context.read<ApplicationBloc>().add(const LoadApplicationsEvent()), onToggle: _toggleApplication, onOpenCatalog: () => _openCatalog(AppRoutes.applications, () => context.read<ApplicationBloc>().add(const LoadApplicationsEvent()))),
                                const SizedBox(height: AppSpacing.md),
                                _OptionalEntitySelector<Indicator>(title: 'Indicador', helperText: 'No aparece el correcto? Deja este campo vacio y aclaralo en el mensaje.', catalogActionLabel: 'Administrar indicadores', showCatalogAction: isDeveloper, enabled: !isBusy, items: indicatorState.indicators, selectedIds: _selectedIndicatorIds, isLoading: indicatorState.status == IndicatorStatus.loading, errorMessage: indicatorState.status == IndicatorStatus.error ? indicatorState.errorMessage : null, idOf: (item) => item.id, labelOf: (item) => item.name, onRetry: () => context.read<IndicatorBloc>().add(const LoadIndicatorsEvent()), onToggle: _toggleIndicator, onOpenCatalog: () => _openCatalog(AppRoutes.indicators, () => context.read<IndicatorBloc>().add(const LoadIndicatorsEvent()))),
                                if (!_isEditing) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  TextField(
                                    controller: _initialMessageController,
                                    enabled: !isBusy,
                                    minLines: compact ? 4 : 5,
                                    maxLines: 8,
                                    textInputAction: TextInputAction.newline,
                                    decoration: const InputDecoration(labelText: 'Descripcion', hintText: 'Cuenta que esta pasando, que esperabas y cualquier dato util para entenderlo.'),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _AttachmentPicker(attachments: _pendingAttachments, enabled: !isBusy, onPick: _openAttachmentOptions, onRemove: _removeAttachment),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                if (isBusy) ...[LinearProgressIndicator(value: _attachmentUploadProgress), const SizedBox(height: AppSpacing.sm), Text(_busyMessage, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: AppSpacing.md)],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(onPressed: isBusy ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                    const SizedBox(width: AppSpacing.sm),
                                    ElevatedButton(onPressed: isBusy || !_canSubmit ? null : _saveDiscussion, child: Text(_primaryActionLabel)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _toggleApplication(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedApplicationIds.add(id);
      } else {
        _selectedApplicationIds.remove(id);
      }
    });
  }

  void _toggleIndicator(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIndicatorIds.add(id);
      } else {
        _selectedIndicatorIds.remove(id);
      }
    });
  }

  bool get _canSubmit {
    final title = _titleController.text.trim();
    final message = _initialMessageController.text.trim();
    return title.isNotEmpty && title.length <= 150 && (_isEditing || message.isNotEmpty);
  }

  bool get _hasCreatedDiscussionPendingAttachments {
    final discussionId = _createdDiscussionId?.trim();
    return discussionId != null && discussionId.isNotEmpty && _pendingAttachments.isNotEmpty && _attachmentUploadIndex < _pendingAttachments.length;
  }

  String get _primaryActionLabel {
    if (_hasCreatedDiscussionPendingAttachments) {
      return 'Reintentar adjuntos';
    }

    return _isEditing ? 'Actualizar' : 'Crear discusion';
  }

  double? get _attachmentUploadProgress {
    if (_pendingAttachments.isEmpty || !_waitingForAttachmentUpload) {
      return null;
    }

    return (_attachmentUploadIndex + 1) / _pendingAttachments.length;
  }

  String get _busyMessage {
    if (_waitingForAttachmentUpload && _pendingAttachments.isNotEmpty) {
      return 'Subiendo adjunto ${_attachmentUploadIndex + 1} de ${_pendingAttachments.length}.';
    }

    if (_submitFlowStage == _SubmitFlowStage.creatingDiscussion) {
      return 'Creando Discussion...';
    }

    if (_submitFlowStage == _SubmitFlowStage.updatingDiscussion) {
      return 'Actualizando Discussion...';
    }

    return 'Procesando...';
  }

  void _refreshFormState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openCatalog(String routeName, VoidCallback onReturn) async {
    await Navigator.pushNamed(context, routeName);
    if (!mounted) {
      return;
    }

    onReturn();
  }

  Future<void> _openAttachmentOptions() async {
    final selectedOption = await showModalBottomSheet<_AttachmentOption>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text('Adjuntar', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              ..._AttachmentOption.values.map((option) => ListTile(leading: Icon(option.icon), title: Text(option.label), onTap: () => Navigator.pop(sheetContext, option))),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedOption == null) {
      return;
    }

    await _pickAttachment(selectedOption);
  }

  Future<void> _pickAttachment(_AttachmentOption option) async {
    try {
      final selection = await FilePicker.platform.pickFiles(type: option.filePickerType, allowMultiple: false, withData: true, allowedExtensions: option.allowedExtensions);

      if (!mounted || selection == null || selection.files.isEmpty) {
        return;
      }

      final picked = selection.files.first;
      final bytes = picked.bytes;
      final rawName = picked.name.trim();
      final fileName = rawName.isNotEmpty ? rawName : 'attachment';

      if (bytes == null || bytes.isEmpty) {
        _showMessage('No se pudo leer el archivo seleccionado.');
        return;
      }

      setState(() {
        _pendingAttachments.add(_PendingAttachment(option: option, fileName: fileName, fileBytes: bytes));
      });
    } on PlatformException {
      if (mounted) {
        _showMessage('No se pudo abrir el selector de archivos.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Ocurrio un error al adjuntar el archivo.');
      }
    }
  }

  void _removeAttachment(_PendingAttachment attachment) {
    setState(() {
      _pendingAttachments.remove(attachment);
    });
  }

  void _onDiscussionStateChanged(BuildContext context, DiscussionState state) {
    final selected = state.selectedDiscussion;
    if (selected != null) {
      final selectedId = selected.id;
      final expectedId = widget.initialDiscussion?.id ?? widget.discussionId;
      final isExpectedSelection = expectedId == null || expectedId.trim().isEmpty || selectedId == expectedId || _submitInProgress;

      if (isExpectedSelection) {
        _applyDiscussion(selected);
      }
    }

    if (state.status == DiscussionStatus.error && state.errorMessage.isNotEmpty) {
      setState(() {
        _submitInProgress = false;
        _submitFlowStage = _SubmitFlowStage.idle;
        _waitingForAttachmentUpload = false;
      });
      _showMessage(state.errorMessage);
      return;
    }

    if (state.status != DiscussionStatus.success || !_submitInProgress) {
      return;
    }

    if (_submitFlowStage != _SubmitFlowStage.creatingDiscussion && _submitFlowStage != _SubmitFlowStage.updatingDiscussion) {
      return;
    }

    if (_submitFlowStage == _SubmitFlowStage.creatingDiscussion && _pendingAttachments.isNotEmpty) {
      final discussionId = selected?.id?.trim();
      if (discussionId == null || discussionId.isEmpty) {
        setState(() {
          _submitInProgress = false;
          _submitFlowStage = _SubmitFlowStage.idle;
        });
        _showMessage('La Discussion se creo, pero no se obtuvo el ID para subir adjuntos.');
        return;
      }

      _createdDiscussionId = discussionId;
      _attachmentUploadIndex = 0;
      _uploadNextAttachment();
      return;
    }

    _finishSubmitWithSuccess();
  }

  void _onDiscussionMessageStateChanged(BuildContext context, DiscussionMessageState state) {
    if (!_waitingForAttachmentUpload) {
      return;
    }

    if (state.status == DiscussionMessageStatus.error && state.errorMessage.isNotEmpty && !state.isSending) {
      setState(() {
        _submitInProgress = false;
        _submitFlowStage = _SubmitFlowStage.idle;
        _waitingForAttachmentUpload = false;
      });
      _showMessage(state.errorMessage);
      return;
    }

    if (state.status != DiscussionMessageStatus.success || state.isSending) {
      return;
    }

    _attachmentUploadIndex += 1;
    if (_attachmentUploadIndex < _pendingAttachments.length) {
      _uploadNextAttachment();
      return;
    }

    _finishSubmitWithSuccess();
  }

  bool get _isEditing => _idController.text.trim().isNotEmpty;

  void _finishSubmitWithSuccess() {
    setState(() {
      _submitInProgress = false;
      _submitFlowStage = _SubmitFlowStage.idle;
      _waitingForAttachmentUpload = false;
      _createdDiscussionId = null;
    });

    _showMessage('Discussion guardada correctamente.');
    Navigator.pop(context, true);
  }

  void _uploadNextAttachment() {
    final discussionId = _createdDiscussionId?.trim();
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    final attachment = _pendingAttachments[_attachmentUploadIndex];
    setState(() {
      _waitingForAttachmentUpload = true;
    });

    context.read<DiscussionMessageBloc>().add(CreateDiscussionAttachmentMessageEvent(discussionId: discussionId, type: attachment.option.type, fileName: attachment.fileName, fileBytes: attachment.fileBytes));
  }

  void _applyDiscussion(Discussion discussion) {
    _idController.text = discussion.id ?? '';
    _titleController.text = discussion.title;

    setState(() {
      _selectedType = discussion.type == DiscussionType.unknown ? DiscussionType.error : discussion.type;
      _status = discussion.status == DiscussionRecordStatus.unknown ? DiscussionRecordStatus.newDiscussion : discussion.status;

      _selectedApplicationIds
        ..clear()
        ..addAll(discussion.resolvedApplicationIds);
      _selectedIndicatorIds
        ..clear()
        ..addAll(discussion.resolvedIndicatorIds);
      _selectedTagIds
        ..clear()
        ..addAll(discussion.resolvedTagIds);
    });
  }

  void _saveDiscussion() {
    if (_hasCreatedDiscussionPendingAttachments) {
      setState(() {
        _submitInProgress = true;
        _submitFlowStage = _SubmitFlowStage.creatingDiscussion;
      });
      _uploadNextAttachment();
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('El titulo es obligatorio.');
      return;
    }

    if (title.length > 150) {
      _showMessage('El titulo no puede superar los 150 caracteres.');
      return;
    }

    final isEditing = _isEditing;
    final initialMessage = _initialMessageController.text.trim();
    if (!isEditing && initialMessage.isEmpty) {
      _showMessage('La descripcion inicial es obligatoria.');
      return;
    }

    final discussion = Discussion(id: _nullableText(_idController.text), type: _selectedType, title: title, initialMessageContent: isEditing ? null : initialMessage, status: _status, applicationIds: _sortedIds(_selectedApplicationIds), indicatorIds: _sortedIds(_selectedIndicatorIds), tagIds: _sortedIds(_selectedTagIds));

    setState(() {
      _submitInProgress = true;
      _submitFlowStage = isEditing ? _SubmitFlowStage.updatingDiscussion : _SubmitFlowStage.creatingDiscussion;
      _createdDiscussionId = null;
      _attachmentUploadIndex = 0;
      _waitingForAttachmentUpload = false;
    });

    final bloc = context.read<DiscussionBloc>();
    if (!isEditing) {
      bloc.add(CreateDiscussionEvent(discussion));
      return;
    }

    bloc.add(UpdateDiscussionEvent(discussion));
  }

  List<String> _sortedIds(Set<String> values) {
    final list = values.map((value) => value.trim()).where((value) => value.isNotEmpty).toList(growable: false);

    final sorted = List<String>.from(list)..sort();
    return sorted;
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DiscussionTypeSelector extends StatelessWidget {
  const _DiscussionTypeSelector({required this.selectedType, required this.enabled, required this.onChanged});

  final DiscussionType selectedType;
  final bool enabled;
  final ValueChanged<DiscussionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final types = DiscussionType.values.where((type) => type != DiscussionType.unknown).toList(growable: false);
    final compact = MediaQuery.of(context).size.width < AppBreakpoints.compact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tipo', style: Theme.of(context).textTheme.labelLarge),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        if (compact)
          Row(
            children: [
              for (final type in types)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _DiscussionTypeButton(type: type, selected: selectedType == type, enabled: enabled, compact: true, onTap: () => onChanged(type)),
                  ),
                ),
            ],
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final type in types) _DiscussionTypeButton(type: type, selected: selectedType == type, enabled: enabled, compact: false, onTap: () => onChanged(type))],
          ),
      ],
    );
  }
}

class _DiscussionTypeButton extends StatelessWidget {
  const _DiscussionTypeButton({required this.type, required this.selected, required this.enabled, required this.compact, required this.onTap});

  final DiscussionType type;
  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _discussionTypeColor(context, type);
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onSurface : scheme.onSurfaceVariant;

    return Material(
      color: selected ? accent.withValues(alpha: 0.16) : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        side: BorderSide(color: selected ? accent : scheme.outline, width: selected ? 1.4 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.sm : AppSpacing.md, vertical: compact ? 6 : AppSpacing.sm),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                width: compact ? 6 : 8,
                height: compact ? 6 : 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
              Flexible(
                child: Text(
                  _discussionTypeLabel(type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: foreground, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: compact ? 11 : null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionalEntitySelector<T> extends StatelessWidget {
  const _OptionalEntitySelector({required this.title, required this.helperText, required this.catalogActionLabel, required this.showCatalogAction, required this.enabled, required this.items, required this.selectedIds, required this.isLoading, required this.errorMessage, required this.idOf, required this.labelOf, required this.onRetry, required this.onToggle, required this.onOpenCatalog});

  final String title;
  final String helperText;
  final String catalogActionLabel;
  final bool showCatalogAction;
  final bool enabled;
  final List<T> items;
  final Set<String> selectedIds;
  final bool isLoading;
  final String? errorMessage;
  final String? Function(T item) idOf;
  final String Function(T item) labelOf;
  final VoidCallback onRetry;
  final void Function(String id, bool selected) onToggle;
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final options = _resolvedOptions;
    final labelsById = {for (final option in options) option.id: option.label};
    final selectedLabels = selectedIds
        .map((id) => labelsById[id] ?? 'Elemento sin nombre')
        .where((label) => label.trim().isNotEmpty)
        .toList(growable: false);
    final scheme = Theme.of(context).colorScheme;
    final error = errorMessage?.trim();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('$title (opcional)', style: Theme.of(context).textTheme.labelLarge)),
              if (showCatalogAction) TextButton(onPressed: onOpenCatalog, child: Text(catalogActionLabel)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(onPressed: enabled ? () => _openSelectionDialog(context, options) : null, icon: const Icon(Icons.checklist_rounded), label: Text(selectedIds.isEmpty ? 'Seleccionar $title' : 'Seleccionar $title (${selectedIds.length})')),
          const SizedBox(height: AppSpacing.xs),
          Text(helperText, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          if (isLoading && items.isEmpty) ...[const SizedBox(height: AppSpacing.md), const LinearProgressIndicator()],
          if (error != null && error.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), Text(error, style: TextStyle(color: scheme.error)), const SizedBox(height: AppSpacing.sm), OutlinedButton(onPressed: onRetry, child: const Text('Reintentar carga'))],
          const SizedBox(height: AppSpacing.md),
          if (selectedLabels.isEmpty)
            Text('Sin $title seleccionado.', style: Theme.of(context).textTheme.bodySmall)
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 6,
              children: [
                for (final id in selectedIds)
                  _SelectedItemChip(
                    label: labelsById[id] ?? 'Elemento sin nombre',
                    onDeleted: enabled ? () => onToggle(id, false) : null,
                  ),
              ],
            ),
          if (selectedIds.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text('${selectedIds.length} seleccionado${selectedIds.length == 1 ? '' : 's'}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted))],
        ],
      ),
    );
  }

  Future<void> _openSelectionDialog(BuildContext context, List<_EntityOption> options) async {
    final queryController = TextEditingController();
    final tempSelected = Set<String>.from(selectedIds);
    var shouldApply = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = queryController.text.trim().toLowerCase();
            final visibleOptions = options
                .where((option) {
                  if (query.isEmpty) {
                    return true;
                  }

                  return option.label.toLowerCase().contains(query);
                })
                .toList(growable: false);

            return AlertDialog(
              title: Text('Seleccionar $title'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width > 600 ? 520 : double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: queryController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar $title',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: queryController.text.trim().isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpiar busqueda',
                                onPressed: () {
                                  queryController.clear();
                                  setDialogState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 320,
                      child: visibleOptions.isEmpty
                          ? Center(child: Text('No hay opciones que coincidan.', style: Theme.of(context).textTheme.bodySmall))
                          : Scrollbar(
                              child: ListView.builder(
                                itemCount: visibleOptions.length,
                                itemBuilder: (context, index) {
                                  final option = visibleOptions[index];
                                  final checked = tempSelected.contains(option.id);

                                  return CheckboxListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    value: checked,
                                    title: Text(option.label),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        if (value ?? false) {
                                          tempSelected.add(option.id);
                                        } else {
                                          tempSelected.remove(option.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
                    shouldApply = true;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    queryController.dispose();

    if (!shouldApply) {
      return;
    }

    final toUnselect = selectedIds.where((id) => !tempSelected.contains(id)).toList(growable: false);
    final toSelect = tempSelected.where((id) => !selectedIds.contains(id)).toList(growable: false);

    for (final id in toUnselect) {
      onToggle(id, false);
    }
    for (final id in toSelect) {
      onToggle(id, true);
    }
  }

  List<_EntityOption> get _resolvedOptions {
    final options = <_EntityOption>[];
    final seenIds = <String>{};

    for (final item in items) {
      final id = _resolvedId(item);
      if (id.isEmpty || seenIds.contains(id)) {
        continue;
      }

      seenIds.add(id);
      options.add(_EntityOption(id: id, label: _resolvedLabel(item)));
    }

    options.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return options;
  }

  String _resolvedId(T item) {
    return idOf(item)?.trim() ?? '';
  }

  String _resolvedLabel(T item) {
    final label = labelOf(item).trim();
    return label.isEmpty ? 'Elemento sin nombre' : label;
  }
}

class _SelectedItemChip extends StatelessWidget {
  const _SelectedItemChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onDeleted: onDeleted,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }
}

class _EntityOption {
  const _EntityOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _AttachmentPicker extends StatelessWidget {
  const _AttachmentPicker({required this.attachments, required this.enabled, required this.onPick, required this.onRemove});

  final List<_PendingAttachment> attachments;
  final bool enabled;
  final VoidCallback onPick;
  final ValueChanged<_PendingAttachment> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(onPressed: enabled ? onPick : null, icon: const Icon(Icons.add_rounded), label: const Text('Adjuntar')),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final attachment in attachments) InputChip(avatar: Icon(attachment.option.icon, size: 18), label: Text(attachment.fileName), onDeleted: enabled ? () => onRemove(attachment) : null)],
          ),
        ],
      ],
    );
  }
}

class _PendingAttachment {
  const _PendingAttachment({required this.option, required this.fileName, required this.fileBytes});

  final _AttachmentOption option;
  final String fileName;
  final List<int> fileBytes;
}

enum _AttachmentOption {
  image,
  audio,
  video,
  file;

  String get label {
    switch (this) {
      case _AttachmentOption.image:
        return 'Imagen';
      case _AttachmentOption.audio:
        return 'Audio';
      case _AttachmentOption.video:
        return 'Video';
      case _AttachmentOption.file:
        return 'Archivo';
    }
  }

  IconData get icon {
    switch (this) {
      case _AttachmentOption.image:
        return Icons.image_outlined;
      case _AttachmentOption.audio:
        return Icons.audiotrack_outlined;
      case _AttachmentOption.video:
        return Icons.videocam_outlined;
      case _AttachmentOption.file:
        return Icons.attach_file_rounded;
    }
  }

  DiscussionMessageType get type {
    switch (this) {
      case _AttachmentOption.image:
        return DiscussionMessageType.image;
      case _AttachmentOption.audio:
        return DiscussionMessageType.audio;
      case _AttachmentOption.video:
        return DiscussionMessageType.video;
      case _AttachmentOption.file:
        return DiscussionMessageType.file;
    }
  }

  FileType get filePickerType {
    switch (this) {
      case _AttachmentOption.image:
      case _AttachmentOption.audio:
      case _AttachmentOption.video:
        return FileType.custom;
      case _AttachmentOption.file:
        return FileType.any;
    }
  }

  List<String>? get allowedExtensions {
    switch (this) {
      case _AttachmentOption.image:
        return const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'];
      case _AttachmentOption.audio:
        return const ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus', 'flac', 'amr'];
      case _AttachmentOption.video:
        return const ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'];
      case _AttachmentOption.file:
        return null;
    }
  }
}

Color _discussionTypeColor(BuildContext context, DiscussionType type) {
  final semantic = context.semanticColors;
  switch (type) {
    case DiscussionType.error:
      return semantic.discussionError;
    case DiscussionType.idea:
      return semantic.discussionIdea;
    case DiscussionType.improvement:
      return semantic.discussionImprovement;
    case DiscussionType.question:
      return semantic.discussionQuestion;
    case DiscussionType.unknown:
      return Theme.of(context).colorScheme.outline;
  }
}

String _discussionTypeLabel(DiscussionType type) {
  switch (type) {
    case DiscussionType.error:
      return 'ERROR';
    case DiscussionType.idea:
      return 'IDEA';
    case DiscussionType.improvement:
      return 'MEJORA';
    case DiscussionType.question:
      return 'CONSULTA';
    case DiscussionType.unknown:
      return 'UNKNOWN';
  }
}
