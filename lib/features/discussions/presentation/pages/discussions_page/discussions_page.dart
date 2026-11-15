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
import '../../../../memberships/presentation/widgets/workspace_members_scaffold.dart';
import '../../../../notifications/presentation/bloc/notification_bloc.dart';
import '../../../../notifications/presentation/bloc/notification_state.dart';
import '../../../../tags/presentation/bloc/tag_bloc.dart';
import '../../../../tags/presentation/bloc/tag_event.dart';
import '../../../../tags/presentation/bloc/tag_state.dart';
import '../../../domain/entities/discussion.dart';
import '../../../domain/entities/discussion_filters.dart';
import '../../../domain/entities/discussion_permissions.dart';
import '../../bloc/discussion_bloc.dart';
import '../../bloc/discussion_event.dart';
import '../../bloc/discussion_state.dart';
import '../discussion_permissions_resolver.dart';
import '../discussion_route_args.dart';
import 'discussion_advanced_filter_selection.dart';
import 'discussion_view_filter.dart';
import 'discussions_helpers.dart';
import 'widgets/discussion_board_dialogs.dart';
import 'widgets/discussion_board_error_state.dart';
import 'widgets/discussion_board_top_bar.dart';
import 'widgets/discussion_board_with_detail_panel.dart';
import 'widgets/discussion_kanban_board.dart';
import 'widgets/discussion_mobile_list.dart';
import 'widgets/discussion_mobile_status_selector.dart';

class DiscussionsPage extends StatefulWidget {
  const DiscussionsPage({super.key});

  @override
  State<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {
  /// Discussions por pagina (el default del backend).
  static const int _pageSize = 20;

  DiscussionViewFilter _viewFilter = DiscussionViewFilter.all;
  bool _unreadOnly = false;
  DiscussionRecordStatus _mobileStatus = DiscussionRecordStatus.newDiscussion;
  String? _activeDiscussionId;

  /// Ancho real del tablero en el ultimo layout. Con el panel de miembros
  /// integrado es menor que el de la pantalla, y es el que decide si el detalle
  /// se abre en el panel lateral o navegando.
  double? _boardMaxWidth;

  DiscussionAdvancedFilterSelection _advancedFilters =
      DiscussionAdvancedFilterSelection.empty;

  /// Los catalogos (filtros avanzados, selectores del detalle y editor) se
  /// piden cuando termina la primera carga del listado, para no competir con
  /// el `GET` que pinta el tablero.
  bool _filterCatalogsRequested = false;

  /// Layout con el que se pidio el listado (`null` hasta el primer layout).
  /// El kanban pide todos los estados en un solo recorrido; el layout
  /// compacto filtra por el estado elegido en el backend. Al cruzar el
  /// breakpoint cambian los filtros y se pide la primera pagina de nuevo.
  bool? _listLayoutIsKanban;

  @override
  Widget build(BuildContext context) {
    // Permisos segun el MembershipRole en la organizacion activa (nunca el rol
    // global del usuario). Se observa AuthBloc para reflejar cambios de
    // contexto; el tablero en si es visible para cualquier Membership ACTIVE.
    final permissions = context.watch<AuthBloc>().state.discussionPermissions;

    return WorkspaceMembersScaffold(
      title: const Text('TeamFlow'),
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
            if (!_filterCatalogsRequested &&
                (state.listStatus == DiscussionListStatus.ready ||
                    state.listStatus == DiscussionListStatus.failure)) {
              _filterCatalogsRequested = true;
              _loadFilterCatalogs();
            }

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
                _boardMaxWidth = constraints.maxWidth;
                final isKanban = constraints.maxWidth >= AppBreakpoints.kanban;
                _syncListLayout(isKanban);

                return Column(
                  children: [
                    DiscussionBoardTopBar(
                      permissions: permissions,
                      isKanban: isKanban,
                      viewFilter: _viewFilter,
                      unreadOnly: _unreadOnly,
                      hasAdvancedFilters: _advancedFilters.hasSelection,
                      totalCount: isKanban ? state.summary?.total : null,
                      onViewFilterSelected: _setViewFilter,
                      onUnreadOnlyChanged: _setUnreadOnly,
                      onOpenAdvancedFilters: _openAdvancedFilters,
                      onClearAdvancedFilters: _clearAdvancedFilters,
                      onRefresh: _requestDiscussions,
                      onCreateDiscussion: _openDiscussionCreate,
                    ),
                    if (state.isRefreshingList)
                      const LinearProgressIndicator(minHeight: 2),
                    if (!isKanban)
                      DiscussionMobileStatusSelector(
                        summary: state.summary,
                        currentStatus: _mobileStatus,
                        onStatusSelected: _setMobileStatus,
                      ),
                    Expanded(
                      child: isKanban
                          ? DiscussionBoardWithDetailPanel(
                              board: _buildListContent(
                                state: state,
                                permissions: permissions,
                                isKanban: true,
                              ),
                              useDetailPanel: _shouldUseDetailPanel(
                                maxWidth: constraints.maxWidth,
                              ),
                              maxWidth: constraints.maxWidth,
                              activeDiscussionId: _activeDiscussionId,
                              onCloseDetail: () {
                                setState(() {
                                  _activeDiscussionId = null;
                                });
                              },
                            )
                          : _buildListContent(
                              state: state,
                              permissions: permissions,
                              isKanban: false,
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

  /// Listado (kanban o columna compacta), o su estado de carga/error cuando
  /// todavia no hay una primera pagina para los filtros vigentes.
  Widget _buildListContent({
    required DiscussionState state,
    required DiscussionPermissions permissions,
    required bool isKanban,
  }) {
    switch (state.listStatus) {
      case DiscussionListStatus.initial:
      case DiscussionListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case DiscussionListStatus.failure:
        return DiscussionBoardErrorState(onRetry: _requestDiscussions);
      case DiscussionListStatus.ready:
        break;
    }

    final grouped = groupDiscussionsByStatus(state.discussions);
    if (isKanban) {
      return DiscussionKanbanBoard(
        grouped: grouped,
        state: state,
        permissions: permissions,
        useOuterPadding: false,
        onOpen: _openDiscussionFromBoard,
        onAssignToMe: _assignToMe,
        onManageAssignments: _openAssignmentsDialog,
        onChangeStatus: _changeDiscussionStatus,
        onLoadMore: _loadNextPage,
      );
    }

    return DiscussionMobileList(
      items: discussionsForStatus(grouped, _mobileStatus),
      state: state,
      permissions: permissions,
      currentStatusLabel: _statusLabel(_mobileStatus),
      onOpen: _openDiscussionFromBoard,
      onAssignToMe: _assignToMe,
      onManageAssignments: _openAssignmentsDialog,
      onChangeStatus: _changeDiscussionStatus,
      onLoadMore: _loadNextPage,
    );
  }

  /// Pide la primera pagina con el layout actual (primer layout o cambio de
  /// breakpoint). Se difiere al final del frame: no se despachan eventos
  /// durante el build.
  void _syncListLayout(bool isKanban) {
    if (_listLayoutIsKanban == isKanban) {
      return;
    }

    _listLayoutIsKanban = isKanban;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestDiscussions();
      }
    });
  }

  void _setMobileStatus(DiscussionRecordStatus status) {
    if (status == _mobileStatus) {
      return;
    }

    setState(() {
      _mobileStatus = status;
    });
    _requestDiscussions();
  }

  /// [status]: columna del kanban que pide mas (ver
  /// [LoadNextDiscussionsPageEvent.status]).
  void _loadNextPage([DiscussionRecordStatus? status]) {
    context.read<DiscussionBloc>().add(
      LoadNextDiscussionsPageEvent(status: status),
    );
  }

  Future<void> _openDiscussionCreate() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.discussionCreate,
      arguments: DiscussionEditorRouteArgs(
        catalogBlocs: DiscussionCatalogBlocs.of(context),
      ),
    );

    if (!mounted) {
      return;
    }

    // El editor devuelve la discussion que respondio el POST: se incorpora al
    // listado respetando filtros y orden, sin pedirlo completo de nuevo.
    if (result is Discussion) {
      context.read<DiscussionBloc>().add(
        DiscussionSavedEvent(result, created: true),
      );
      return;
    }

    if (result == true) {
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
    final isKanban = _listLayoutIsKanban;
    if (isKanban == null) {
      // Todavia no hubo layout: la primera carga la hace _syncListLayout.
      return;
    }

    context.read<DiscussionBloc>().add(
      LoadDiscussionsEvent(
        filters: _buildFilters(isKanban: isKanban),
        silent: silent,
        currentUserId: context.read<AuthBloc>().state.session?.user.id,
      ),
    );
  }

  /// Solo pide los catalogos que todavia no se cargaron (o fallaron): un
  /// catalogo vacio ya cargado no se vuelve a pedir. Los blocs son de esta
  /// ruta y los comparten el detalle y el editor.
  void _loadFilterCatalogs() {
    final appBloc = context.read<WorkModuleBloc>();
    if (appBloc.state.status == WorkModuleStatus.initial ||
        appBloc.state.status == WorkModuleStatus.error) {
      appBloc.add(const LoadWorkModulesEvent());
    }

    final componentBloc = context.read<ComponentBloc>();
    if (componentBloc.state.status == ComponentStatus.initial ||
        componentBloc.state.status == ComponentStatus.error) {
      componentBloc.add(const LoadComponentsEvent());
    }

    final tagBloc = context.read<TagBloc>();
    if (tagBloc.state.status == TagStatus.initial ||
        tagBloc.state.status == TagStatus.error) {
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

  /// Filtros del recorrido paginado. Todos se aplican en el backend; el
  /// layout compacto ademas filtra por el estado elegido.
  DiscussionFilters _buildFilters({required bool isKanban}) {
    return DiscussionFilters(
      limit: _pageSize,
      type: _advancedFilters.type,
      status: isKanban ? null : _mobileStatus,
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

    final boardWidth = _boardMaxWidth ?? MediaQuery.sizeOf(context).width;
    if (_shouldUseDetailPanel(maxWidth: boardWidth)) {
      setState(() {
        _activeDiscussionId = discussionId;
      });
      return;
    }

    // El detalle comparte el bloc del tablero: todo lo que cambia alli (estado,
    // asignaciones, contexto, titulo/tipo, lectura) ya queda aplicado en el
    // listado, asi que al volver no hace falta pedirlo de nuevo.
    await Navigator.pushNamed(
      context,
      AppRoutes.discussionDetail,
      arguments: DiscussionDetailRouteArgs(
        discussionId: discussionId,
        discussionBloc: context.read<DiscussionBloc>(),
        catalogBlocs: DiscussionCatalogBlocs.of(context),
      ),
    );
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
