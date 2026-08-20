import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../applications/presentation/bloc/application_bloc.dart';
import '../../../applications/presentation/bloc/application_event.dart';
import '../../../applications/presentation/bloc/application_state.dart';
import '../../../applications/domain/entities/application.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../indicators/domain/entities/indicator.dart';
import '../../../indicators/presentation/bloc/indicator_bloc.dart';
import '../../../indicators/presentation/bloc/indicator_event.dart';
import '../../../indicators/presentation/bloc/indicator_state.dart';
import '../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../notifications/presentation/bloc/notification_state.dart';
import '../../../tags/presentation/bloc/tag_bloc.dart';
import '../../../tags/presentation/bloc/tag_event.dart';
import '../../../tags/presentation/bloc/tag_state.dart';
import '../../../tags/domain/entities/tag.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_filters.dart';
import '../bloc/discussion_bloc.dart';
import '../bloc/discussion_event.dart';
import '../bloc/discussion_state.dart';
import '../widgets/discussion_board_card.dart';
import 'discussion_detail_page.dart';
import 'discussion_route_args.dart';

enum _DiscussionViewFilter { all, mine, assignedToMe }

class DiscussionsPage extends StatefulWidget {
  const DiscussionsPage({super.key});

  @override
  State<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {
  _DiscussionViewFilter _viewFilter = _DiscussionViewFilter.all;
  bool _unreadOnly = false;
  DiscussionRecordStatus _mobileStatus = DiscussionRecordStatus.newDiscussion;
  String? _activeDiscussionId;

  DiscussionType? _advancedType;
  Set<String> _applicationFilterIds = <String>{};
  Set<String> _indicatorFilterIds = <String>{};
  Set<String> _tagFilterIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadFilterCatalogs();
      _requestDiscussions(silent: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDeveloper = _isDeveloper(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Develop Workflow')),
      floatingActionButton: _isCompactLayout(context)
          ? FloatingActionButton.extended(
              onPressed: _openDiscussionCreate,
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
      body: MultiBlocListener(
        listeners: [
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen: (previous, current) =>
                previous.notificationEventVersion !=
                current.notificationEventVersion,
            listener: (context, notificationState) {
              if (!_shouldRefreshKanbanForNotification(notificationState)) {
                return;
              }

              _requestDiscussions(silent: true);
            },
          ),
        ],
        child: BlocConsumer<DiscussionBloc, DiscussionState>(
          listener: (context, state) {
            if (state.errorMessage.isNotEmpty) {
              _showMessage(state.errorMessage);
              context.read<DiscussionBloc>().add(
                const ClearDiscussionOperationMessageEvent(),
              );
            }

            if (state.operationMessage.isNotEmpty) {
              _showMessage(state.operationMessage);
              context.read<DiscussionBloc>().add(
                const ClearDiscussionOperationMessageEvent(),
              );
            }
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isKanban = constraints.maxWidth >= AppBreakpoints.kanban;

                if (state.status == DiscussionStatus.loading &&
                    state.discussions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == DiscussionStatus.error &&
                    state.discussions.isEmpty) {
                  return _buildInitialError();
                }

                final grouped = _groupByStatus(state.discussions);
                final mobileItems = _itemsForStatus(grouped, _mobileStatus);
                final useDetailPanel = _shouldUseDetailPanel(
                  maxWidth: constraints.maxWidth,
                );

                return Column(
                  children: [
                    _buildTopSection(
                      context,
                      isDeveloper: isDeveloper,
                      isKanban: isKanban,
                    ),
                    if (state.status == DiscussionStatus.loading &&
                        state.discussions.isNotEmpty)
                      const LinearProgressIndicator(minHeight: 2),
                    if (!isKanban)
                      _buildMobileStatusSelector(
                        grouped: grouped,
                        currentStatus: _mobileStatus,
                        onStatusSelected: (status) {
                          setState(() {
                            _mobileStatus = status;
                          });
                        },
                      ),
                    Expanded(
                      child: isKanban
                          ? _buildKanbanWithOptionalDetailPanel(
                              grouped: grouped,
                              state: state,
                              isDeveloper: isDeveloper,
                              useDetailPanel: useDetailPanel,
                              maxWidth: constraints.maxWidth,
                            )
                          : _buildMobileList(
                              items: mobileItems,
                              state: state,
                              isDeveloper: isDeveloper,
                              currentStatus: _mobileStatus,
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

  Widget _buildKanbanWithOptionalDetailPanel({
    required Map<DiscussionRecordStatus, List<Discussion>> grouped,
    required DiscussionState state,
    required bool isDeveloper,
    required bool useDetailPanel,
    required double maxWidth,
  }) {
    if (!useDetailPanel || _activeDiscussionId == null) {
      return _buildKanbanBoard(
        grouped: grouped,
        state: state,
        isDeveloper: isDeveloper,
      );
    }

    final panelWidth = _detailPanelWidth(maxWidth);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildKanbanBoard(
              grouped: grouped,
              state: state,
              isDeveloper: isDeveloper,
              useOuterPadding: false,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: panelWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: DiscussionDetailPage(
                  key: ValueKey<String>(_activeDiscussionId!),
                  discussionId: _activeDiscussionId!,
                  embedded: true,
                  onClose: () {
                    setState(() {
                      _activeDiscussionId = null;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(
    BuildContext context, {
    required bool isDeveloper,
    required bool isKanban,
  }) {
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
                      selected: _viewFilter == _DiscussionViewFilter.all,
                      onSelected: (_) =>
                          _setViewFilter(_DiscussionViewFilter.all),
                    ),
                    FilterChip(
                      label: const Text('Mis discussions'),
                      selected: _viewFilter == _DiscussionViewFilter.mine,
                      onSelected: (_) =>
                          _setViewFilter(_DiscussionViewFilter.mine),
                    ),
                    if (isDeveloper)
                      FilterChip(
                        label: const Text('Asignadas a mi'),
                        selected: _viewFilter ==
                            _DiscussionViewFilter.assignedToMe,
                        onSelected: (_) =>
                            _setViewFilter(_DiscussionViewFilter.assignedToMe),
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
                      selected: _unreadOnly,
                      onSelected: (selected) {
                        setState(() {
                          _unreadOnly = selected;
                        });
                        _requestDiscussions();
                      },
                    ),
                    OutlinedButton.icon(
                      onPressed: _openAdvancedFilters,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Filtros'),
                    ),
                    if (_hasAdvancedFilters)
                      OutlinedButton(
                        onPressed: _clearAdvancedFilters,
                        child: const Text('Limpiar filtros'),
                      ),
                    OutlinedButton.icon(
                      onPressed: _requestDiscussions,
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
              onPressed: _openDiscussionCreate,
              icon: const Icon(Icons.add),
              label: const Text('Nueva discussion'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKanbanBoard({
    required Map<DiscussionRecordStatus, List<Discussion>> grouped,
    required DiscussionState state,
    required bool isDeveloper,
    bool useOuterPadding = true,
  }) {
    final board = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          _DwKanbanColumn(
            title: 'Entrada',
            accent: context.semanticColors.statusNew,
            items: _itemsForStatus(
              grouped,
              DiscussionRecordStatus.newDiscussion,
            ),
            state: state,
            isDeveloper: isDeveloper,
            onOpen: _openDiscussionFromBoard,
            onAssignToMe: _assignToMe,
            onManageAssignments: _openAssignmentsDialog,
            onChangeStatus: _changeDiscussionStatus,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DwKanbanColumn(
            title: 'Revisión',
            accent: context.semanticColors.statusReview,
            items: _itemsForStatus(grouped, DiscussionRecordStatus.review),
            state: state,
            isDeveloper: isDeveloper,
            onOpen: _openDiscussionFromBoard,
            onAssignToMe: _assignToMe,
            onManageAssignments: _openAssignmentsDialog,
            onChangeStatus: _changeDiscussionStatus,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DwKanbanColumn(
            title: 'Trabajando',
            accent: context.semanticColors.statusInProgress,
            items: _itemsForStatus(grouped, DiscussionRecordStatus.inProgress),
            state: state,
            isDeveloper: isDeveloper,
            onOpen: _openDiscussionFromBoard,
            onAssignToMe: _assignToMe,
            onManageAssignments: _openAssignmentsDialog,
            onChangeStatus: _changeDiscussionStatus,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DwKanbanColumn(
            title: 'Resuelto',
            accent: context.semanticColors.statusResolved,
            items: _itemsForStatus(grouped, DiscussionRecordStatus.resolved),
            state: state,
            isDeveloper: isDeveloper,
            onOpen: _openDiscussionFromBoard,
            onAssignToMe: _assignToMe,
            onManageAssignments: _openAssignmentsDialog,
            onChangeStatus: _changeDiscussionStatus,
          ),
        ],
    );

    if (!useOuterPadding) {
      return board;
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: board,
    );
  }

  Widget _buildMobileStatusSelector({
    required Map<DiscussionRecordStatus, List<Discussion>> grouped,
    required DiscussionRecordStatus currentStatus,
    required ValueChanged<DiscussionRecordStatus> onStatusSelected,
  }) {
    final entries = <(DiscussionRecordStatus, String)>[
      (DiscussionRecordStatus.newDiscussion, 'Entrada'),
      (DiscussionRecordStatus.review, 'Revisión'),
      (DiscussionRecordStatus.inProgress, 'Trabajando'),
      (DiscussionRecordStatus.resolved, 'Resuelto'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in entries) ...[
              ChoiceChip(
                label: Text(
                  '${entry.$2} ${_itemsForStatus(grouped, entry.$1).length}',
                ),
                selected: currentStatus == entry.$1,
                onSelected: (_) => onStatusSelected(entry.$1),
              ),
              if (entry != entries.last) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList({
    required List<Discussion> items,
    required DiscussionState state,
    required bool isDeveloper,
    required DiscussionRecordStatus currentStatus,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Sin discussions en ${_statusLabel(currentStatus).toLowerCase()}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final discussion = items[index];
        return DiscussionBoardCard(
          discussion: discussion,
          isDeveloper: isDeveloper,
          isBusy: _isDiscussionBusy(state, discussion.id),
          onOpen: () => _openDiscussionFromBoard(discussionId: discussion.id),
          onManageAssignments: () => _openAssignmentsDialog(discussion),
          onAssignToMe: () => _assignToMe(discussion),
          onChangeStatus: (nextStatus) =>
              _changeDiscussionStatus(discussion, nextStatus),
        );
      },
    );
  }

  Widget _buildInitialError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded),
            const SizedBox(height: AppSpacing.sm),
            const Text('No se pudieron cargar las discussions.'),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _requestDiscussions,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDiscussionCreate() async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.discussionCreate,
    );

    if (!mounted) {
      return;
    }

    if (changed == true) {
      _requestDiscussions();
    }
  }

  void _setViewFilter(_DiscussionViewFilter selected) {
    final nextFilter = _viewFilter == selected
        ? _DiscussionViewFilter.all
        : selected;

    setState(() {
      _viewFilter = nextFilter;
    });

    _requestDiscussions();
  }

  void _requestDiscussions({bool silent = false}) {
    context.read<DiscussionBloc>().add(
      LoadDiscussionsEvent(filters: _buildFilters(), silent: silent),
    );
  }

  void _loadFilterCatalogs() {
    final appBloc = context.read<ApplicationBloc>();
    if (appBloc.state.applications.isEmpty &&
        appBloc.state.status != ApplicationStatus.loading) {
      appBloc.add(const LoadApplicationsEvent());
    }

    final indicatorBloc = context.read<IndicatorBloc>();
    if (indicatorBloc.state.indicators.isEmpty &&
        indicatorBloc.state.status != IndicatorStatus.loading) {
      indicatorBloc.add(const LoadIndicatorsEvent());
    }

    final tagBloc = context.read<TagBloc>();
    if (tagBloc.state.tags.isEmpty &&
        tagBloc.state.status != TagStatus.loading) {
      tagBloc.add(const LoadTagsEvent());
    }
  }

  bool _shouldRefreshKanbanForNotification(NotificationState state) {
    const supportedTypes = <String>{
      'DISCUSSION_CREATED',
      'DISCUSSION_MESSAGE',
      'DISCUSSION_MESSAGE_UPDATED',
      'DISCUSSION_MESSAGE_DELETED',
      'DISCUSSION_CONTEXT_CHANGED',
      'DISCUSSION_STATUS_CHANGED',
      'DISCUSSION_ASSIGNMENT_CHANGED',
    };

    final type = state.lastNotificationType.trim();
    if (type.isEmpty || !supportedTypes.contains(type)) {
      return false;
    }

    return true;
  }

  DiscussionFilters _buildFilters() {
    return DiscussionFilters(
      page: 1,
      limit: 100,
      type: _advancedType,
      applicationIds: _sortedIds(_applicationFilterIds),
      indicatorIds: _sortedIds(_indicatorFilterIds),
      tagIds: _sortedIds(_tagFilterIds),
      mine: _viewFilter == _DiscussionViewFilter.mine,
      assignedToMe: _viewFilter == _DiscussionViewFilter.assignedToMe,
      unread: _unreadOnly ? true : null,
    );
  }

  bool get _hasAdvancedFilters {
    return _advancedType != null ||
        _applicationFilterIds.isNotEmpty ||
        _indicatorFilterIds.isNotEmpty ||
        _tagFilterIds.isNotEmpty;
  }

  void _clearAdvancedFilters() {
    setState(() {
      _advancedType = null;
      _applicationFilterIds = <String>{};
      _indicatorFilterIds = <String>{};
      _tagFilterIds = <String>{};
    });
    _requestDiscussions();
  }

  Future<void> _openAdvancedFilters() async {
    _loadFilterCatalogs();

    final applications = context.read<ApplicationBloc>().state.applications;
    final indicators = context.read<IndicatorBloc>().state.indicators;
    final tags = context.read<TagBloc>().state.tags;

    final tempResult = await (_isCompactLayout(context)
        ? _showAdvancedFiltersBottomSheet(
            applications: applications,
            indicators: indicators,
            tags: tags,
          )
        : _showAdvancedFiltersDialog(
            applications: applications,
            indicators: indicators,
            tags: tags,
          ));

    if (!mounted || tempResult == null) {
      return;
    }

    setState(() {
      _advancedType = tempResult.type;
      _applicationFilterIds = tempResult.applicationIds;
      _indicatorFilterIds = tempResult.indicatorIds;
      _tagFilterIds = tempResult.tagIds;
    });

    _requestDiscussions();
  }

  Future<_AdvancedFilterSelection?> _showAdvancedFiltersDialog({
    required List<Application> applications,
    required List<Indicator> indicators,
    required List<Tag> tags,
  }) {
    return showDialog<_AdvancedFilterSelection>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          clipBehavior: Clip.antiAlias,
          child: _AdvancedFiltersContent(
            initialType: _advancedType,
            initialApplicationIds: _applicationFilterIds,
            initialIndicatorIds: _indicatorFilterIds,
            initialTagIds: _tagFilterIds,
            applications: applications,
            indicators: indicators,
            tags: tags,
            onClose: (selection) => Navigator.pop(dialogContext, selection),
          ),
        );
      },
    );
  }

  Future<_AdvancedFilterSelection?> _showAdvancedFiltersBottomSheet({
    required List<Application> applications,
    required List<Indicator> indicators,
    required List<Tag> tags,
  }) {
    return showModalBottomSheet<_AdvancedFilterSelection>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: _AdvancedFiltersContent(
              initialType: _advancedType,
              initialApplicationIds: _applicationFilterIds,
              initialIndicatorIds: _indicatorFilterIds,
              initialTagIds: _tagFilterIds,
              applications: applications,
              indicators: indicators,
              tags: tags,
              onClose: (selection) => Navigator.pop(sheetContext, selection),
            ),
          ),
        );
      },
    );
  }

  Map<DiscussionRecordStatus, List<Discussion>> _groupByStatus(
    List<Discussion> discussions,
  ) {
    final grouped = <DiscussionRecordStatus, List<Discussion>>{
      DiscussionRecordStatus.newDiscussion: <Discussion>[],
      DiscussionRecordStatus.review: <Discussion>[],
      DiscussionRecordStatus.inProgress: <Discussion>[],
      DiscussionRecordStatus.resolved: <Discussion>[],
    };

    for (final discussion in discussions) {
      final status = discussion.status;
      if (!grouped.containsKey(status)) {
        continue;
      }
      grouped[status]!.add(discussion);
    }

    return grouped;
  }

  List<Discussion> _itemsForStatus(
    Map<DiscussionRecordStatus, List<Discussion>> grouped,
    DiscussionRecordStatus status,
  ) {
    return grouped[status] ?? const <Discussion>[];
  }

  bool _isDeveloper(BuildContext context) {
    final user = context.read<AuthBloc>().state.session?.user;
    return user?.isDeveloper ?? false;
  }

  bool _isCompactLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AppBreakpoints.compact;
  }

  bool _shouldUseDetailPanel({required double maxWidth}) {
    return maxWidth >= AppBreakpoints.discussionPanel;
  }

  double _detailPanelWidth(double maxWidth) {
    final width = maxWidth * 0.36;
    if (width < 560) {
      return 560;
    }
    if (width > 760) {
      return 760;
    }
    return width;
  }

  bool _isDiscussionBusy(DiscussionState state, String? discussionId) {
    if (discussionId == null || discussionId.isEmpty) {
      return false;
    }

    return state.operationDiscussionId == discussionId &&
        (state.isUpdatingAssignments || state.isUpdatingStatus);
  }

  Future<void> _openDiscussionFromBoard({required String? discussionId}) async {
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    context.read<DiscussionBloc>().add(MarkDiscussionAsReadEvent(discussionId));

    if (_shouldUseDetailPanel(maxWidth: MediaQuery.sizeOf(context).width)) {
      setState(() {
        _activeDiscussionId = discussionId;
      });
      return;
    }

    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.discussionDetail,
      arguments: DiscussionDetailRouteArgs(discussionId: discussionId),
    );

    if (!mounted) {
      return;
    }

    if (changed == true) {
      _requestDiscussions();
    }
  }

  void _changeDiscussionStatus(
    Discussion discussion,
    DiscussionRecordStatus nextStatus,
  ) {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    context.read<DiscussionBloc>().add(
      ChangeDiscussionStatusEvent(
        discussionId: discussionId,
        status: nextStatus,
      ),
    );
  }

  void _assignToMe(Discussion discussion) {
    final discussionId = discussion.id;
    final currentUser = context.read<AuthBloc>().state.session?.user;

    if (discussionId == null || discussionId.isEmpty || currentUser == null) {
      return;
    }

    context.read<DiscussionBloc>().add(
      AssignDiscussionToMeEvent(
        discussionId: discussionId,
        currentDeveloperUserId: currentUser.id,
      ),
    );
  }

  Future<void> _openAssignmentsDialog(Discussion discussion) async {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return;
    }

    final bloc = context.read<DiscussionBloc>();
    bloc.add(const LoadAssignableDevelopersEvent());

    final selectedIds = discussion.assignedDevelopers
        .map((developer) => developer.id)
        .toSet();

    final savedIds = await showDialog<Set<String>>(
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
                    onPressed: () => Navigator.pop(
                      dialogContext,
                      Set<String>.from(selectedIds),
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (!mounted || savedIds == null) {
      return;
    }

    bloc.add(
      ReplaceDiscussionAssignmentsEvent(
        discussionId: discussionId,
        developerUserIds: _sortedIds(savedIds),
      ),
    );
  }

  List<String> _sortedIds(Set<String> ids) {
    final list = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final sorted = List<String>.from(list)..sort();
    return sorted;
  }

  String _statusLabel(DiscussionRecordStatus status) {
    switch (status) {
      case DiscussionRecordStatus.newDiscussion:
        return 'Entrada';
      case DiscussionRecordStatus.review:
        return 'Revisión';
      case DiscussionRecordStatus.inProgress:
        return 'Trabajando';
      case DiscussionRecordStatus.resolved:
        return 'Resuelto';
      case DiscussionRecordStatus.unknown:
        return 'Desconocido';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DwKanbanColumn extends StatelessWidget {
  const _DwKanbanColumn({
    required this.title,
    required this.accent,
    required this.items,
    required this.state,
    required this.isDeveloper,
    required this.onOpen,
    required this.onManageAssignments,
    required this.onAssignToMe,
    required this.onChangeStatus,
  });

  final String title;
  final Color accent;
  final List<Discussion> items;
  final DiscussionState state;
  final bool isDeveloper;
  final Future<void> Function({required String? discussionId}) onOpen;
  final Future<void> Function(Discussion discussion) onManageAssignments;
  final void Function(Discussion discussion) onAssignToMe;
  final void Function(Discussion discussion, DiscussionRecordStatus nextStatus)
  onChangeStatus;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${items.length}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: accent),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).colorScheme.outline),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'Sin discussions',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final discussion = items[index];
                        return DiscussionBoardCard(
                          discussion: discussion,
                          isDeveloper: isDeveloper,
                          isBusy: _isBusy(state, discussion.id),
                          onOpen: () => onOpen(discussionId: discussion.id),
                          onManageAssignments: () =>
                              onManageAssignments(discussion),
                          onAssignToMe: () => onAssignToMe(discussion),
                          onChangeStatus: (nextStatus) =>
                              onChangeStatus(discussion, nextStatus),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isBusy(DiscussionState state, String? discussionId) {
    if (discussionId == null || discussionId.isEmpty) {
      return false;
    }

    return state.operationDiscussionId == discussionId &&
        (state.isUpdatingAssignments || state.isUpdatingStatus);
  }
}

class _AdvancedFilterSelection {
  const _AdvancedFilterSelection({
    required this.type,
    required this.applicationIds,
    required this.indicatorIds,
    required this.tagIds,
  });

  final DiscussionType? type;
  final Set<String> applicationIds;
  final Set<String> indicatorIds;
  final Set<String> tagIds;
}

class _AdvancedFiltersContent extends StatefulWidget {
  const _AdvancedFiltersContent({
    required this.initialType,
    required this.initialApplicationIds,
    required this.initialIndicatorIds,
    required this.initialTagIds,
    required this.applications,
    required this.indicators,
    required this.tags,
    required this.onClose,
  });

  final DiscussionType? initialType;
  final Set<String> initialApplicationIds;
  final Set<String> initialIndicatorIds;
  final Set<String> initialTagIds;
  final List<Application> applications;
  final List<Indicator> indicators;
  final List<Tag> tags;
  final ValueChanged<_AdvancedFilterSelection?> onClose;

  @override
  State<_AdvancedFiltersContent> createState() =>
      _AdvancedFiltersContentState();
}

class _AdvancedFiltersContentState extends State<_AdvancedFiltersContent> {
  late DiscussionType? _type;
  late Set<String> _applicationIds;
  late Set<String> _indicatorIds;
  late Set<String> _tagIds;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _applicationIds = Set<String>.from(widget.initialApplicationIds);
    _indicatorIds = Set<String>.from(widget.initialIndicatorIds);
    _tagIds = Set<String>.from(widget.initialTagIds);
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
                      items: widget.applications
                          .where((item) => item.id != null)
                          .toList(growable: false),
                      selectedIds: _applicationIds,
                      idBuilder: (item) => item.id,
                      labelBuilder: (item) => item.name,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSelectorSection(
                      title: 'Indicadores',
                      items: widget.indicators
                          .where((item) => item.id != null)
                          .toList(growable: false),
                      selectedIds: _indicatorIds,
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
                      _applicationIds.clear();
                      _indicatorIds.clear();
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
                      _AdvancedFilterSelection(
                        type: _type,
                        applicationIds: Set<String>.from(_applicationIds),
                        indicatorIds: Set<String>.from(_indicatorIds),
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
