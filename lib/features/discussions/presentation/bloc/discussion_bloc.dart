import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_developer.dart';
import '../../domain/entities/discussion_filters.dart';
import '../../domain/entities/discussion_page.dart';
import '../../domain/entities/discussion_summary.dart';
import '../../domain/usecases/add_discussion_assignments.dart';
import '../../domain/usecases/create_discussion.dart';
import '../../domain/usecases/get_assignable_developers.dart';
import '../../domain/usecases/get_discussion.dart';
import '../../domain/usecases/get_discussions.dart';
import '../../domain/usecases/mark_discussion_as_read.dart';
import '../../domain/usecases/remove_discussion_assignment.dart';
import '../../domain/usecases/replace_discussion_assignments.dart';
import '../../domain/usecases/update_discussion.dart';
import '../../domain/usecases/update_discussion_status.dart';
import 'discussion_event.dart';
import 'discussion_state.dart';

class DiscussionBloc extends Bloc<DiscussionEvent, DiscussionState> {
  DiscussionBloc({
    required GetDiscussions getDiscussions,
    required GetDiscussion getDiscussion,
    required MarkDiscussionAsRead markDiscussionAsRead,
    required CreateDiscussion createDiscussion,
    required UpdateDiscussion updateDiscussion,
    required UpdateDiscussionStatus updateDiscussionStatus,
    required GetAssignableDevelopers getAssignableDevelopers,
    required AddDiscussionAssignments addDiscussionAssignments,
    required ReplaceDiscussionAssignments replaceDiscussionAssignments,
    required RemoveDiscussionAssignment removeDiscussionAssignment,
  }) : _getDiscussions = getDiscussions,
       _getDiscussion = getDiscussion,
       _markDiscussionAsRead = markDiscussionAsRead,
       _createDiscussion = createDiscussion,
       _updateDiscussion = updateDiscussion,
       _updateDiscussionStatus = updateDiscussionStatus,
       _getAssignableDevelopers = getAssignableDevelopers,
       _addDiscussionAssignments = addDiscussionAssignments,
       _replaceDiscussionAssignments = replaceDiscussionAssignments,
       _removeDiscussionAssignment = removeDiscussionAssignment,
       super(const DiscussionState()) {
    on<LoadDiscussionsEvent>(_onLoadDiscussions);
    on<LoadNextDiscussionsPageEvent>(_onLoadNextDiscussionsPage);
    on<LoadDiscussionEvent>(_onLoadDiscussion);
    on<MarkDiscussionAsReadEvent>(_onMarkDiscussionAsRead);
    on<CreateDiscussionEvent>(_onCreateDiscussion);
    on<UpdateDiscussionEvent>(_onUpdateDiscussion);
    on<DiscussionSavedEvent>(_onDiscussionSaved);
    on<SelectDiscussionEvent>(_onSelectDiscussion);
    on<LoadAssignableDevelopersEvent>(_onLoadAssignableDevelopers);
    on<ChangeDiscussionStatusEvent>(_onChangeDiscussionStatus);
    on<AddDiscussionAssignmentsEvent>(_onAddDiscussionAssignments);
    on<ReplaceDiscussionAssignmentsEvent>(_onReplaceDiscussionAssignments);
    on<RemoveDiscussionAssignmentEvent>(_onRemoveDiscussionAssignment);
    on<AssignDiscussionToMeEvent>(_onAssignDiscussionToMe);
    on<ClearDiscussionOperationMessageEvent>(_onClearOperationMessage);
  }

  final GetDiscussions _getDiscussions;
  final GetDiscussion _getDiscussion;
  final MarkDiscussionAsRead _markDiscussionAsRead;
  final CreateDiscussion _createDiscussion;
  final UpdateDiscussion _updateDiscussion;
  final UpdateDiscussionStatus _updateDiscussionStatus;
  final GetAssignableDevelopers _getAssignableDevelopers;
  final AddDiscussionAssignments _addDiscussionAssignments;
  final ReplaceDiscussionAssignments _replaceDiscussionAssignments;
  final RemoveDiscussionAssignment _removeDiscussionAssignment;

  /// Orden de las marcas de lectura confirmadas por el backend. Un `GET` que
  /// empezo antes de una marca confirmada pudo calcular `isUnread` antes de
  /// que se guardara la lectura; esa respuesta no debe volver a mostrarla como
  /// no leida (pasa al abrir el detalle: el tablero marca la lectura mientras
  /// el detalle pide la discussion).
  int _readMarkSequence = 0;
  final Map<String, int> _readMarkSequenceById = <String, int>{};

  /// Recorrido paginado vigente. Cambia cuando el listado se reemplaza
  /// (filtros nuevos, refresh explicito o cursor rechazado): una pagina
  /// siguiente pedida con el recorrido anterior se descarta.
  int _listGeneration = 0;

  /// Ultima primera pagina pedida. Solo se aplica la respuesta de la ultima
  /// (las anteriores llegan fuera de orden o son de filtros previos).
  int _firstPageRequestId = 0;

  /// Ultima discussion devuelta por el backend en el recorrido vigente: la
  /// posicion del cursor. Todo lo que va antes ya se pidio; lo que va despues
  /// llega con las paginas siguientes. No cambia al sacar discussions del
  /// listado localmente.
  Discussion? _loadedRangeEnd;

  /// Cuenta las discussions reconciliadas localmente. Si cambia mientras se
  /// pide una primera pagina, esa respuesta pudo calcularse antes del cambio y
  /// se vuelve a pedir para no mostrar el listado o los contadores viejos.
  int _localChangeSequence = 0;

  Future<void> _onLoadDiscussions(
    LoadDiscussionsEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    final filters = event.filters;
    final currentUserId = _normalizeId(event.currentUserId);
    final sameTraversal =
        state.listStatus == DiscussionListStatus.ready &&
        filters == state.filters;
    final mergeIntoLoaded = sameTraversal && event.silent;

    if (!sameTraversal) {
      // Recorrido nuevo: nada del anterior (discussions, cursor, contadores)
      // se muestra como vigente. Si solo cambia `status`, `byStatus` sigue
      // valiendo y `total` se deriva de el.
      _listGeneration++;
      _loadedRangeEnd = null;
      final previousSummary = state.summary;
      final keepSummary =
          previousSummary != null &&
          filters.equalsIgnoringStatus(state.filters);
      emit(
        state.copyWith(
          listStatus: DiscussionListStatus.loading,
          discussions: const <Discussion>[],
          clearNextCursor: true,
          hasNextPage: false,
          summary: keepSummary
              ? previousSummary.withStatusFilter(_statusFilterOf(filters))
              : null,
          clearSummary: !keepSummary,
          isRefreshingList: false,
          isLoadingNextPage: false,
          nextPageErrorMessage: '',
          filters: filters,
          currentUserId: currentUserId,
          errorMessage: '',
          operationMessage: '',
        ),
      );
    } else if (!mergeIntoLoaded) {
      // Refresh explicito: reemplazara el listado, asi que una pagina
      // siguiente en curso ya no sirve.
      _listGeneration++;
      emit(
        state.copyWith(
          isRefreshingList: true,
          isLoadingNextPage: false,
          nextPageErrorMessage: '',
          currentUserId: currentUserId,
          errorMessage: '',
          operationMessage: '',
        ),
      );
    } else if (currentUserId != null && currentUserId != state.currentUserId) {
      emit(state.copyWith(currentUserId: currentUserId));
    }

    final requestId = ++_firstPageRequestId;
    final requestReadMarkSequence = _readMarkSequence;
    final requestLocalChangeSequence = _localChangeSequence;
    final result = await _getDiscussions(filters: filters);

    if (isClosed || requestId != _firstPageRequestId) {
      return;
    }

    if (result is Success<DiscussionPage>) {
      final page = result.data;
      final fresh = _prepareIncoming(page.items, requestReadMarkSequence);
      final serverLast = page.items.isEmpty ? null : page.items.last;

      List<Discussion> discussions;
      String? nextCursor;
      bool hasNextPage;
      if (mergeIntoLoaded) {
        final merged = _mergeFirstPage(page, fresh, serverLast);
        discussions = merged.discussions;
        nextCursor = merged.nextCursor;
        hasNextPage = merged.hasNextPage;
      } else {
        discussions = fresh;
        nextCursor = page.nextCursor;
        hasNextPage = page.hasNextPage;
        _loadedRangeEnd = serverLast;
      }

      final selectedDiscussionId = _resolveSelectedDiscussionId();
      emit(
        state.copyWith(
          listStatus: DiscussionListStatus.ready,
          discussions: discussions,
          nextCursor: nextCursor,
          clearNextCursor: nextCursor == null,
          hasNextPage: hasNextPage,
          // La primera pagina siempre trae `summary`; nunca se pisa con null.
          summary: page.summary,
          isRefreshingList: false,
          nextPageErrorMessage: mergeIntoLoaded
              ? state.nextPageErrorMessage
              : '',
          selectedDiscussion: _findById(discussions, selectedDiscussionId),
          selectedDiscussionId: selectedDiscussionId,
        ),
      );
      if (requestLocalChangeSequence != _localChangeSequence) {
        _refreshLoadedList();
      }
      return;
    }

    if (result is FailureResult<DiscussionPage>) {
      final hasVisibleList = state.listStatus == DiscussionListStatus.ready;
      emit(
        state.copyWith(
          listStatus: hasVisibleList
              ? DiscussionListStatus.ready
              : DiscussionListStatus.failure,
          isRefreshingList: false,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadNextDiscussionsPage(
    LoadNextDiscussionsPageEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    final cursor = state.nextCursor;
    if (state.listStatus != DiscussionListStatus.ready ||
        state.isRefreshingList ||
        state.isLoadingNextPage ||
        !state.hasNextPage ||
        cursor == null ||
        cursor.isEmpty) {
      return;
    }

    final generation = _listGeneration;
    final filters = state.filters;
    emit(state.copyWith(isLoadingNextPage: true, nextPageErrorMessage: ''));

    final requestReadMarkSequence = _readMarkSequence;
    final result = await _getDiscussions(filters: filters, cursor: cursor);

    if (isClosed || generation != _listGeneration) {
      return;
    }

    if (state.nextCursor != cursor) {
      // Una primera pagina reemplazo el recorrido mientras tanto.
      emit(state.copyWith(isLoadingNextPage: false));
      return;
    }

    if (result is Success<DiscussionPage>) {
      final page = result.data;
      final loadedIds = state.discussions
          .map((discussion) => discussion.id)
          .whereType<String>()
          .toSet();
      final appended = _prepareIncoming(
        page.items,
        requestReadMarkSequence,
      ).where((discussion) => !loadedIds.contains(discussion.id));

      if (page.items.isNotEmpty) {
        _loadedRangeEnd = page.items.last;
      }

      emit(
        state.copyWith(
          discussions: List<Discussion>.unmodifiable([
            ...state.discussions,
            ...appended,
          ]),
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          hasNextPage: page.hasNextPage,
          // Las paginas siguientes traen `summary: null`: se conserva el
          // ultimo valido.
          summary: page.summary,
          isLoadingNextPage: false,
          nextPageErrorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionPage>) {
      final failure = result.failure;
      if (failure is ServerFailure && failure.statusCode == 400) {
        // Los filtros son los mismos con los que la primera pagina respondio
        // 200: un 400 aca es el cursor rechazado (`Invalid cursor` /
        // `Cursor does not match the current filters`). Se descarta el
        // recorrido y se vuelve a pedir la primera pagina.
        emit(
          state.copyWith(
            isLoadingNextPage: false,
            operationMessage: 'El listado se actualizo desde el inicio.',
          ),
        );
        add(
          LoadDiscussionsEvent(
            filters: state.filters,
            currentUserId: state.currentUserId,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isLoadingNextPage: false,
          nextPageErrorMessage: failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadDiscussion(
    LoadDiscussionEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(state.copyWith(status: DiscussionStatus.loading, errorMessage: ''));

    final requestReadMarkSequence = _readMarkSequence;
    final result = await _getDiscussion(event.id);

    if (result is Success<Discussion>) {
      final selected = _applyConfirmedRead(
        result.data,
        requestReadMarkSequence,
      );
      // Abrir un detalle nunca dispara una recarga del listado: si algo no se
      // puede decidir localmente, el listado y los contadores quedan como
      // estan hasta el proximo refresh.
      final reconciled = _reconcile(selected);
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: selected,
          selectedDiscussionId: selected.id,
          discussions: reconciled.discussions,
          summary: reconciled.summary,
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Discussion>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onMarkDiscussionAsRead(
    MarkDiscussionAsReadEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    final discussionId = event.discussionId.trim();
    if (discussionId.isEmpty) {
      return;
    }

    if (state.markingAsReadDiscussionIds.contains(discussionId)) {
      return;
    }

    final discussion = _findDiscussionInState(discussionId);
    if (discussion != null && !discussion.isUnread) {
      return;
    }

    emit(
      state.copyWith(
        markingAsReadDiscussionIds: <String>{
          ...state.markingAsReadDiscussionIds,
          discussionId,
        },
      ),
    );

    final result = await _markDiscussionAsRead(discussionId);
    if (isClosed) {
      return;
    }

    final nextInProgress = Set<String>.from(state.markingAsReadDiscussionIds)
      ..remove(discussionId);

    if (result is Success<DiscussionReadState>) {
      final isUnread = result.data.isUnread;
      if (!isUnread) {
        _readMarkSequenceById[discussionId] = ++_readMarkSequence;
      }

      final known = _findDiscussionInState(discussionId);
      var discussions = state.discussions;
      var summary = state.summary;
      var needsRefresh = false;
      if (known != null && known.isUnread != isUnread) {
        final reconciled = _reconcile(known.copyWith(isUnread: isUnread));
        discussions = reconciled.discussions;
        summary = reconciled.summary;
        needsRefresh = reconciled.needsRefresh;
      } else if (known == null &&
          state.filters.unread != null &&
          state.listStatus == DiscussionListStatus.ready) {
        // Con el filtro de no leidas, una lectura de una discussion que no
        // esta cargada puede cambiar los contadores.
        needsRefresh = true;
      }

      Discussion? nextSelectedDiscussion = state.selectedDiscussion;
      if (nextSelectedDiscussion != null &&
          nextSelectedDiscussion.id == discussionId) {
        nextSelectedDiscussion = nextSelectedDiscussion.copyWith(
          isUnread: isUnread,
        );
      }

      emit(
        state.copyWith(
          discussions: discussions,
          summary: summary,
          selectedDiscussion: nextSelectedDiscussion,
          markingAsReadDiscussionIds: nextInProgress,
        ),
      );
      if (needsRefresh) {
        _refreshLoadedList();
      }
      return;
    }

    if (result is FailureResult<DiscussionReadState>) {
      emit(
        state.copyWith(
          markingAsReadDiscussionIds: nextInProgress,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onCreateDiscussion(
    CreateDiscussionEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(state.copyWith(status: DiscussionStatus.loading, errorMessage: ''));

    final result = await _createDiscussion(event.discussion);
    if (isClosed) {
      return;
    }

    if (result is Success<Discussion>) {
      final created = result.data;
      final reconciled = _reconcile(created, created: true);
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: created,
          selectedDiscussionId: created.id,
          discussions: reconciled.discussions,
          summary: reconciled.summary,
          errorMessage: '',
        ),
      );
      if (reconciled.needsRefresh) {
        _refreshLoadedList();
      }
      return;
    }

    if (result is FailureResult<Discussion>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onUpdateDiscussion(
    UpdateDiscussionEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    if (event.changes.isEmpty) {
      return;
    }

    emit(state.copyWith(status: DiscussionStatus.loading, errorMessage: ''));

    final result = await _updateDiscussion(
      discussionId: event.discussionId,
      changes: event.changes,
    );
    if (isClosed) {
      return;
    }

    if (result is Success<Discussion>) {
      final updated = _withKnownReadState(result.data);
      final reconciled = _reconcile(updated);
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: updated,
          selectedDiscussionId: updated.id,
          discussions: reconciled.discussions,
          summary: reconciled.summary,
          errorMessage: '',
        ),
      );
      if (reconciled.needsRefresh) {
        _refreshLoadedList();
      }
      return;
    }

    if (result is FailureResult<Discussion>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  void _onDiscussionSaved(
    DiscussionSavedEvent event,
    Emitter<DiscussionState> emit,
  ) {
    final saved = event.created
        ? event.discussion
        : _withKnownReadState(event.discussion);
    final reconciled = _reconcile(saved, created: event.created);
    final isSelected =
        saved.id != null && saved.id == _resolveSelectedDiscussionId();

    emit(
      state.copyWith(
        discussions: reconciled.discussions,
        summary: reconciled.summary,
        selectedDiscussion: isSelected ? saved : null,
      ),
    );

    if (reconciled.needsRefresh) {
      _refreshLoadedList();
    }
  }

  void _onSelectDiscussion(
    SelectDiscussionEvent event,
    Emitter<DiscussionState> emit,
  ) {
    final discussionId = event.discussionId?.trim();
    if (discussionId == null || discussionId.isEmpty) {
      emit(
        state.copyWith(
          selectedDiscussionId: null,
          clearSelectedDiscussionId: true,
          selectedDiscussion: null,
          clearSelectedDiscussion: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedDiscussionId: discussionId,
        selectedDiscussion: _findById(state.discussions, discussionId),
      ),
    );
  }

  Future<void> _onLoadAssignableDevelopers(
    LoadAssignableDevelopersEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    if (!event.forceReload && state.assignableDevelopers.isNotEmpty) {
      return;
    }

    emit(
      state.copyWith(
        isLoadingAssignableDevelopers: true,
        errorMessage: '',
        operationMessage: '',
      ),
    );

    final result = await _getAssignableDevelopers();

    if (result is Success<List<AssignableDeveloper>>) {
      emit(
        state.copyWith(
          isLoadingAssignableDevelopers: false,
          assignableDevelopers: result.data,
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<List<AssignableDeveloper>>) {
      emit(
        state.copyWith(
          isLoadingAssignableDevelopers: false,
          status: DiscussionStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onChangeDiscussionStatus(
    ChangeDiscussionStatusEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(
      state.copyWith(
        isUpdatingStatus: true,
        operationDiscussionId: event.discussionId,
        errorMessage: '',
        operationMessage: '',
      ),
    );

    final result = await _updateDiscussionStatus(
      discussionId: event.discussionId,
      status: event.status,
    );

    _handleDiscussionOperationResult(
      emit: emit,
      result: result,
      successMessage: 'Estado actualizado correctamente.',
      clearStatusOperation: true,
    );
  }

  Future<void> _onAddDiscussionAssignments(
    AddDiscussionAssignmentsEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(
      state.copyWith(
        isUpdatingAssignments: true,
        operationDiscussionId: event.discussionId,
        errorMessage: '',
        operationMessage: '',
      ),
    );

    final result = await _addDiscussionAssignments(
      discussionId: event.discussionId,
      developerUserIds: event.developerUserIds,
    );

    _handleDiscussionOperationResult(
      emit: emit,
      result: result,
      successMessage: 'Asignaciones actualizadas correctamente.',
      clearAssignmentOperation: true,
    );
  }

  Future<void> _onReplaceDiscussionAssignments(
    ReplaceDiscussionAssignmentsEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(
      state.copyWith(
        isUpdatingAssignments: true,
        operationDiscussionId: event.discussionId,
        errorMessage: '',
        operationMessage: '',
      ),
    );

    final result = await _replaceDiscussionAssignments(
      discussionId: event.discussionId,
      developerUserIds: event.developerUserIds,
    );

    _handleDiscussionOperationResult(
      emit: emit,
      result: result,
      successMessage: 'Asignaciones actualizadas correctamente.',
      clearAssignmentOperation: true,
    );
  }

  Future<void> _onRemoveDiscussionAssignment(
    RemoveDiscussionAssignmentEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(
      state.copyWith(
        isUpdatingAssignments: true,
        operationDiscussionId: event.discussionId,
        errorMessage: '',
        operationMessage: '',
      ),
    );

    final result = await _removeDiscussionAssignment(
      discussionId: event.discussionId,
      developerUserId: event.developerUserId,
    );

    _handleDiscussionOperationResult(
      emit: emit,
      result: result,
      successMessage: 'Asignacion removida correctamente.',
      clearAssignmentOperation: true,
    );
  }

  Future<void> _onAssignDiscussionToMe(
    AssignDiscussionToMeEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(
      state.copyWith(
        isUpdatingAssignments: true,
        operationDiscussionId: event.discussionId,
        errorMessage: '',
        operationMessage: '',
      ),
    );

    final result = await _addDiscussionAssignments(
      discussionId: event.discussionId,
      developerUserIds: [event.currentDeveloperUserId],
    );

    _handleDiscussionOperationResult(
      emit: emit,
      result: result,
      successMessage: 'La discussion fue asignada a tu usuario.',
      clearAssignmentOperation: true,
    );
  }

  void _onClearOperationMessage(
    ClearDiscussionOperationMessageEvent event,
    Emitter<DiscussionState> emit,
  ) {
    emit(state.copyWith(operationMessage: '', errorMessage: ''));
  }

  void _handleDiscussionOperationResult({
    required Emitter<DiscussionState> emit,
    required Result<Discussion> result,
    required String successMessage,
    bool clearStatusOperation = false,
    bool clearAssignmentOperation = false,
  }) {
    if (isClosed) {
      return;
    }

    if (result is Success<Discussion>) {
      final updated = _withKnownReadState(result.data);
      final reconciled = _reconcile(updated);
      final selectedId = _resolveSelectedDiscussionId(updated);

      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          discussions: reconciled.discussions,
          summary: reconciled.summary,
          selectedDiscussionId: selectedId,
          // La respuesta es la version vigente aunque los filtros del tablero
          // la saquen del listado (el detalle la sigue mostrando).
          selectedDiscussion: selectedId == updated.id
              ? updated
              : _findById(reconciled.discussions, selectedId),
          isUpdatingStatus: clearStatusOperation
              ? false
              : state.isUpdatingStatus,
          isUpdatingAssignments: clearAssignmentOperation
              ? false
              : state.isUpdatingAssignments,
          clearOperationDiscussionId:
              clearStatusOperation || clearAssignmentOperation,
          errorMessage: '',
          operationMessage: successMessage,
        ),
      );

      // La respuesta trae la discussion completa (mismas relaciones que el
      // listado); solo se consulta al servidor cuando el listado o los
      // contadores no se pueden reconciliar localmente.
      if (reconciled.needsRefresh) {
        _refreshLoadedList();
      }
      return;
    }

    if (result is FailureResult<Discussion>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.error,
          isUpdatingStatus: clearStatusOperation
              ? false
              : state.isUpdatingStatus,
          isUpdatingAssignments: clearAssignmentOperation
              ? false
              : state.isUpdatingAssignments,
          clearOperationDiscussionId:
              clearStatusOperation || clearAssignmentOperation,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  /// Actualizacion controlada desde el servidor: vuelve a pedir la primera
  /// pagina (contadores y cabecera del listado) sin descartar las paginas
  /// siguientes ya cargadas ni su cursor.
  void _refreshLoadedList() {
    if (isClosed || state.listStatus != DiscussionListStatus.ready) {
      return;
    }

    add(
      LoadDiscussionsEvent(
        filters: state.filters,
        silent: true,
        currentUserId: state.currentUserId,
      ),
    );
  }

  /// Une una primera pagina recien pedida con el listado ya cargado (mismos
  /// filtros). La primera pagina reemplaza su tramo del listado; lo cargado
  /// despues de su ultima discussion se conserva junto con su cursor, que
  /// sigue apuntando al final de lo cargado.
  ({List<Discussion> discussions, String? nextCursor, bool hasNextPage})
  _mergeFirstPage(
    DiscussionPage page,
    List<Discussion> fresh,
    Discussion? serverLast,
  ) {
    final loaded = state.discussions;
    final rangeEnd = _loadedRangeEnd;

    final takeFirstPage =
        serverLast == null ||
        serverLast.createdAt == null ||
        !page.hasNextPage ||
        loaded.isEmpty ||
        rangeEnd == null ||
        _compareByBackendOrder(serverLast, rangeEnd) >= 0;
    if (takeFirstPage) {
      _loadedRangeEnd = serverLast;
      return (
        discussions: fresh,
        nextCursor: page.nextCursor,
        hasNextPage: page.hasNextPage,
      );
    }

    final freshIds = fresh
        .map((discussion) => discussion.id)
        .whereType<String>()
        .toSet();
    final tail = loaded.where(
      (discussion) =>
          !freshIds.contains(discussion.id) &&
          discussion.createdAt != null &&
          _compareByBackendOrder(discussion, serverLast) > 0,
    );

    return (
      discussions: List<Discussion>.unmodifiable([...fresh, ...tail]),
      nextCursor: state.nextCursor,
      hasNextPage: state.hasNextPage,
    );
  }

  /// Items recibidos del backend listos para el listado: aplica las lecturas
  /// confirmadas despues de que empezo el `GET` y descarta los que por eso
  /// dejan de cumplir el filtro `unread`.
  List<Discussion> _prepareIncoming(
    List<Discussion> items,
    int requestReadMarkSequence,
  ) {
    final unread = state.filters.unread;
    return List<Discussion>.unmodifiable(
      items
          .map(
            (discussion) =>
                _applyConfirmedRead(discussion, requestReadMarkSequence),
          )
          .where(
            (discussion) => unread == null || discussion.isUnread == unread,
          ),
    );
  }

  /// Incorpora al listado y a los contadores una version de la discussion
  /// confirmada por el backend (respuesta de un `GET`/`POST`/`PATCH` o una
  /// lectura), respetando los filtros activos y el orden del backend.
  ///
  /// Con paginacion por cursor:
  /// - Sacar una discussion del listado no mueve el cursor (es una posicion,
  ///   no un offset), asi que no hace falta recargar.
  /// - Una discussion que pasa a cumplir los filtros se inserta solo si su
  ///   posicion cae dentro de lo ya cargado; si cae despues, llegara con su
  ///   pagina (nunca se duplica).
  /// - `summary.byStatus` cuenta con todos los filtros salvo `status`, asi que
  ///   el cambio se calcula comparando la version anterior con la nueva.
  ///
  /// `needsRefresh` es `true` cuando algo no se puede decidir localmente (por
  /// ejemplo `mine`/`assignedToMe` sin usuario conocido, o una version
  /// anterior desconocida); quien llama decide si consulta al servidor.
  ({
    List<Discussion> discussions,
    DiscussionSummary? summary,
    bool needsRefresh,
  })
  _reconcile(Discussion updated, {bool created = false}) {
    final discussions = state.discussions;
    final summary = state.summary;
    final discussionId = updated.id;
    if (discussionId == null ||
        discussionId.isEmpty ||
        state.listStatus != DiscussionListStatus.ready) {
      return (discussions: discussions, summary: summary, needsRefresh: false);
    }

    _localChangeSequence++;
    final index = discussions.indexWhere((item) => item.id == discussionId);
    final inList = index >= 0;
    final withinLoadedRange = _isWithinLoadedRange(updated);
    var needsRefresh = false;

    // 1. Listado.
    var nextDiscussions = discussions;
    final matches = _matchesActiveFilters(
      updated,
      createdByCurrentUser: created,
    );
    if (matches == null) {
      needsRefresh = true;
      if (inList) {
        nextDiscussions = _replaceAt(discussions, index, updated);
      }
    } else if (matches) {
      if (inList) {
        nextDiscussions = _replaceAt(discussions, index, updated);
      } else if (withinLoadedRange) {
        nextDiscussions = _insertInBackendOrder(discussions, updated);
      }
    } else if (inList) {
      nextDiscussions = List<Discussion>.unmodifiable(
        List<Discussion>.from(discussions)..removeAt(index),
      );
    }

    // 2. Contadores.
    if (summary == null) {
      return (
        discussions: nextDiscussions,
        summary: summary,
        needsRefresh: needsRefresh,
      );
    }

    final previous = inList
        ? discussions[index]
        : created
        ? null
        : _selectedVersion(discussionId);
    final countedBefore = inList
        ? true
        : created
        ? false
        : _wasCounted(previous, withinLoadedRange: withinLoadedRange);
    final countedAfter = _matchesActiveFilters(
      updated,
      createdByCurrentUser: created,
      ignoreStatus: true,
    );
    if (countedBefore == null || countedAfter == null) {
      return (
        discussions: nextDiscussions,
        summary: summary,
        needsRefresh: true,
      );
    }

    final nextSummary = summary.move(
      from: countedBefore ? previous?.status : null,
      to: countedAfter ? updated.status : null,
      statusFilter: _statusFilterOf(state.filters),
    );

    return (
      discussions: nextDiscussions,
      summary: nextSummary,
      needsRefresh: needsRefresh,
    );
  }

  /// Si la version anterior (que no esta en el listado) contaba en
  /// `summary.byStatus`. `null` si no se puede saber.
  bool? _wasCounted(Discussion? previous, {required bool withinLoadedRange}) {
    // Sin filtro `status`, el listado cargado contiene todo lo que cuenta
    // hasta el cursor: si no esta y su posicion cae ahi, no contaba.
    if (withinLoadedRange && _statusFilterOf(state.filters) == null) {
      return false;
    }

    if (previous == null) {
      return null;
    }

    return _matchesActiveFilters(previous, ignoreStatus: true);
  }

  /// La posicion de la discussion cae dentro de lo ya pedido al backend (no
  /// llegara en una pagina siguiente).
  bool _isWithinLoadedRange(Discussion discussion) {
    if (!state.hasNextPage) {
      return true;
    }

    final rangeEnd = _loadedRangeEnd;
    if (rangeEnd == null || discussion.createdAt == null) {
      return false;
    }

    return _compareByBackendOrder(discussion, rangeEnd) <= 0;
  }

  List<Discussion> _insertInBackendOrder(
    List<Discussion> current,
    Discussion discussion,
  ) {
    final next = List<Discussion>.from(current);
    final position = next.indexWhere(
      (item) => _compareByBackendOrder(discussion, item) < 0,
    );
    next.insert(position < 0 ? next.length : position, discussion);
    return List<Discussion>.unmodifiable(next);
  }

  /// Orden de `GET .../discussions`: `createdAt` descendente y, a igual
  /// fecha, `id` ascendente. Una discussion sin `createdAt` va al final.
  int _compareByBackendOrder(Discussion a, Discussion b) {
    final aCreatedAt = a.createdAt;
    final bCreatedAt = b.createdAt;
    if (aCreatedAt != null && bCreatedAt != null) {
      final byDate = bCreatedAt.compareTo(aCreatedAt);
      if (byDate != 0) {
        return byDate;
      }
    } else if (aCreatedAt == null && bCreatedAt != null) {
      return 1;
    } else if (aCreatedAt != null && bCreatedAt == null) {
      return -1;
    }

    return (a.id ?? '').compareTo(b.id ?? '');
  }

  /// Mismos criterios que `GET .../discussions` (AND entre filtros; dentro de
  /// `moduleIds`/`componentIds`/`tagIds` basta con coincidir en uno). Con
  /// [ignoreStatus] evalua lo que cuenta `summary.byStatus`.
  ///
  /// Devuelve `null` si `mine`/`assignedToMe` no se pueden decidir (usuario
  /// autenticado desconocido).
  bool? _matchesActiveFilters(
    Discussion discussion, {
    bool createdByCurrentUser = false,
    bool ignoreStatus = false,
  }) {
    final filters = state.filters;

    final type = filters.type;
    if (type != null &&
        type != DiscussionType.unknown &&
        discussion.type != type) {
      return false;
    }

    final status = _statusFilterOf(filters);
    if (!ignoreStatus && status != null && discussion.status != status) {
      return false;
    }

    final unread = filters.unread;
    if (unread != null && discussion.isUnread != unread) {
      return false;
    }

    if (!_containsAnyId(discussion.resolvedModuleIds, filters.moduleIds) ||
        !_containsAnyId(
          discussion.resolvedComponentIds,
          filters.componentIds,
        ) ||
        !_containsAnyId(discussion.resolvedTagIds, filters.tagIds)) {
      return false;
    }

    // Como en el backend, `mine` tiene prioridad sobre `createdBy` y
    // `assignedToMe` sobre `assignedDeveloperId`.
    final createdBy = filters.createdBy?.trim();
    if (!filters.mine &&
        createdBy != null &&
        createdBy.isNotEmpty &&
        discussion.createdBy?.id != createdBy) {
      return false;
    }

    final assignedDeveloperId = filters.assignedDeveloperId?.trim();
    if (!filters.assignedToMe &&
        assignedDeveloperId != null &&
        assignedDeveloperId.isNotEmpty &&
        !discussion.assignedDevelopers.any(
          (developer) => developer.id == assignedDeveloperId,
        )) {
      return false;
    }

    final currentUserId = state.currentUserId;
    var undecided = false;

    if (filters.assignedToMe) {
      if (discussion.assignedDevelopers.isEmpty) {
        return false;
      }
      if (currentUserId == null) {
        undecided = true;
      } else if (!discussion.assignedDevelopers.any(
        (developer) => developer.id == currentUserId,
      )) {
        return false;
      }
    }

    if (filters.mine && !createdByCurrentUser) {
      final creatorId = discussion.createdBy?.id;
      if (currentUserId == null || creatorId == null) {
        undecided = true;
      } else if (creatorId != currentUserId) {
        return false;
      }
    }

    return undecided ? null : true;
  }

  DiscussionRecordStatus? _statusFilterOf(DiscussionFilters filters) {
    final status = filters.status;
    if (status == null || status == DiscussionRecordStatus.unknown) {
      return null;
    }
    return status;
  }

  bool _containsAnyId(List<String> ids, List<String> filterIds) {
    final normalizedFilter = filterIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (normalizedFilter.isEmpty) {
      return true;
    }

    return ids.any((id) => normalizedFilter.contains(id.trim()));
  }

  List<Discussion> _replaceAt(
    List<Discussion> current,
    int index,
    Discussion discussion,
  ) {
    final next = List<Discussion>.from(current);
    next[index] = discussion;
    return List<Discussion>.unmodifiable(next);
  }

  /// Una lectura confirmada despues de que empezo el `GET` prevalece sobre el
  /// `isUnread` de esa respuesta.
  Discussion _applyConfirmedRead(
    Discussion discussion,
    int requestReadMarkSequence,
  ) {
    final discussionId = discussion.id;
    if (!discussion.isUnread || discussionId == null) {
      return discussion;
    }

    final confirmedAt = _readMarkSequenceById[discussionId];
    if (confirmedAt == null || confirmedAt <= requestReadMarkSequence) {
      return discussion;
    }

    return discussion.copyWith(isUnread: false);
  }

  /// `PATCH .../discussions/:id`, `PATCH .../status` y las asignaciones
  /// responden la discussion sin `isUnread` (el modelo lo deja en `false`).
  /// Se conserva el valor ya conocido: el backend no deja la discussion no
  /// leida para quien hace el cambio si ya estaba al dia, y las asignaciones y
  /// el contexto no mueven su actividad.
  Discussion _withKnownReadState(Discussion updated) {
    final discussionId = updated.id;
    if (discussionId == null || discussionId.isEmpty) {
      return updated;
    }

    final known = _findDiscussionInState(discussionId);
    if (known == null) {
      return updated;
    }

    return updated.copyWith(isUnread: known.isUnread);
  }

  Discussion? _selectedVersion(String discussionId) {
    final selected = state.selectedDiscussion;
    if (selected != null && selected.id == discussionId) {
      return selected;
    }
    return null;
  }

  Discussion? _findDiscussionInState(String discussionId) {
    return _selectedVersion(discussionId) ??
        _findById(state.discussions, discussionId);
  }

  String? _resolveSelectedDiscussionId([Discussion? updated]) {
    final directId = updated?.id;
    if (directId != null && directId.isNotEmpty) {
      return directId;
    }

    final stateSelectedId = state.selectedDiscussionId?.trim();
    if (stateSelectedId != null && stateSelectedId.isNotEmpty) {
      return stateSelectedId;
    }

    final selectedEntityId = state.selectedDiscussion?.id?.trim();
    if (selectedEntityId != null && selectedEntityId.isNotEmpty) {
      return selectedEntityId;
    }

    return null;
  }

  Discussion? _findById(List<Discussion> list, String? discussionId) {
    final normalizedId = discussionId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) {
      return null;
    }

    for (final discussion in list) {
      if (discussion.id == normalizedId) {
        return discussion;
      }
    }

    return null;
  }

  String? _normalizeId(String? id) {
    final normalized = id?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
