import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_breakpoints.dart';
import '../../../../work_modules/presentation/bloc/work_module_bloc.dart';
import '../../../../work_modules/presentation/bloc/work_module_event.dart';
import '../../../../work_modules/presentation/bloc/work_module_state.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../components/presentation/bloc/component_bloc.dart';
import '../../../../components/presentation/bloc/component_event.dart';
import '../../../../components/presentation/bloc/component_state.dart';
import '../../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../../notifications/presentation/bloc/notification_state.dart';
import '../../../../tags/presentation/bloc/tag_bloc.dart';
import '../../../../tags/presentation/bloc/tag_event.dart';
import '../../../../tags/presentation/bloc/tag_state.dart';
import '../../../domain/entities/discussion.dart';
import '../../../domain/entities/discussion_filters.dart';
import '../../bloc/discussion_bloc.dart';
import '../../bloc/discussion_event.dart';
import '../../bloc/discussion_state.dart';
import '../discussion_route_args.dart';
import 'discussion_advanced_filter_selection.dart';
import 'discussion_view_filter.dart';
import 'discussions_helpers.dart';
import 'widgets/discussion_board_dialogs.dart';
import 'widgets/discussion_board_error_state.dart';
import 'widgets/discussion_board_top_bar.dart';
import 'widgets/discussion_board_with_detail_panel.dart';
import 'widgets/discussion_mobile_list.dart';
import 'widgets/discussion_mobile_status_selector.dart';

class DiscussionsPage extends StatefulWidget {
  const DiscussionsPage({super.key});

  @override
  State<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {
  DiscussionViewFilter _viewFilter = DiscussionViewFilter.all;
  bool _unreadOnly = false;
  DiscussionRecordStatus _mobileStatus = DiscussionRecordStatus.newDiscussion;
  String? _activeDiscussionId;

  DiscussionAdvancedFilterSelection _advancedFilters =
      DiscussionAdvancedFilterSelection.empty;

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
      appBar: AppBar(title: const Text('TeamFlow')),
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
                  return DiscussionBoardErrorState(onRetry: _requestDiscussions);
                }

                final grouped = groupDiscussionsByStatus(state.discussions);
                final mobileItems = discussionsForStatus(grouped, _mobileStatus);
                final useDetailPanel = _shouldUseDetailPanel(
                  maxWidth: constraints.maxWidth,
                );

                return Column(
                  children: [
                    DiscussionBoardTopBar(
                      isDeveloper: isDeveloper,
                      isKanban: isKanban,
                      viewFilter: _viewFilter,
                      unreadOnly: _unreadOnly,
                      hasAdvancedFilters: _advancedFilters.hasSelection,
                      onViewFilterSelected: _setViewFilter,
                      onUnreadOnlyChanged: _setUnreadOnly,
                      onOpenAdvancedFilters: _openAdvancedFilters,
                      onClearAdvancedFilters: _clearAdvancedFilters,
                      onRefresh: _requestDiscussions,
                      onCreateDiscussion: _openDiscussionCreate,
                    ),
                    if (state.status == DiscussionStatus.loading &&
                        state.discussions.isNotEmpty)
                      const LinearProgressIndicator(minHeight: 2),
                    if (!isKanban)
                      DiscussionMobileStatusSelector(
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
                          ? DiscussionBoardWithDetailPanel(
                              grouped: grouped,
                              state: state,
                              isDeveloper: isDeveloper,
                              useDetailPanel: useDetailPanel,
                              maxWidth: constraints.maxWidth,
                              activeDiscussionId: _activeDiscussionId,
                              onCloseDetail: () {
                                setState(() {
                                  _activeDiscussionId = null;
                                });
                              },
                              onOpen: _openDiscussionFromBoard,
                              onAssignToMe: _assignToMe,
                              onManageAssignments: _openAssignmentsDialog,
                              onChangeStatus: _changeDiscussionStatus,
                            )
                          : DiscussionMobileList(
                              items: mobileItems,
                              state: state,
                              isDeveloper: isDeveloper,
                              currentStatusLabel: _statusLabel(_mobileStatus),
                              onOpen: _openDiscussionFromBoard,
                              onAssignToMe: _assignToMe,
                              onManageAssignments: _openAssignmentsDialog,
                              onChangeStatus: _changeDiscussionStatus,
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

  void _setViewFilter(DiscussionViewFilter selected) {
    final nextFilter = _viewFilter == selected
        ? DiscussionViewFilter.all
        : selected;

    setState(() {
      _viewFilter = nextFilter;
    });

    _requestDiscussions();
  }

  void _setUnreadOnly(bool selected) {
    setState(() {
      _unreadOnly = selected;
    });

    _requestDiscussions();
  }

  void _requestDiscussions({bool silent = false}) {
    context.read<DiscussionBloc>().add(
      LoadDiscussionsEvent(filters: _buildFilters(), silent: silent),
    );
  }

  void _loadFilterCatalogs() {
    final appBloc = context.read<WorkModuleBloc>();
    if (appBloc.state.workModules.isEmpty &&
        appBloc.state.status != WorkModuleStatus.loading) {
      appBloc.add(const LoadWorkModulesEvent());
    }

    final componentBloc = context.read<ComponentBloc>();
    if (componentBloc.state.components.isEmpty &&
        componentBloc.state.status != ComponentStatus.loading) {
      componentBloc.add(const LoadComponentsEvent());
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
      type: _advancedFilters.type,
      moduleIds: _sortedIds(_advancedFilters.moduleIds),
      componentIds: _sortedIds(_advancedFilters.componentIds),
      tagIds: _sortedIds(_advancedFilters.tagIds),
      mine: _viewFilter == DiscussionViewFilter.mine,
      assignedToMe: _viewFilter == DiscussionViewFilter.assignedToMe,
      unread: _unreadOnly ? true : null,
    );
  }

  void _clearAdvancedFilters() {
    setState(() {
      _advancedFilters = DiscussionAdvancedFilterSelection.empty;
    });
    _requestDiscussions();
  }

  Future<void> _openAdvancedFilters() async {
    _loadFilterCatalogs();

    final workModules = context.read<WorkModuleBloc>().state.workModules;
    final components = context.read<ComponentBloc>().state.components;
    final tags = context.read<TagBloc>().state.tags;

    final selection = await (_isCompactLayout(context)
        ? showDiscussionAdvancedFiltersSheet(
            context: context,
            selection: _advancedFilters,
            workModules: workModules,
            components: components,
            tags: tags,
          )
        : showDiscussionAdvancedFiltersDialog(
            context: context,
            selection: _advancedFilters,
            workModules: workModules,
            components: components,
            tags: tags,
          ));

    if (!mounted || selection == null) {
      return;
    }

    setState(() {
      _advancedFilters = selection;
    });

    _requestDiscussions();
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

    final savedIds = await showDiscussionBoardAssignmentsDialog(
      context: context,
      bloc: bloc,
      selectedIds: discussion.assignedDevelopers
          .map((developer) => developer.id)
          .toSet(),
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
