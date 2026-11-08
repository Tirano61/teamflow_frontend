import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_developer.dart';
import '../../domain/entities/discussion_page.dart';
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

  Future<void> _onLoadDiscussions(
    LoadDiscussionsEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    if (!event.silent) {
      emit(
        state.copyWith(
          status: DiscussionStatus.loading,
          filters: event.filters,
          errorMessage: '',
          operationMessage: '',
        ),
      );
    } else {
      emit(
        state.copyWith(
          filters: event.filters,
          errorMessage: '',
          operationMessage: '',
        ),
      );
    }

    final requestReadMarkSequence = _readMarkSequence;
    final result = await _getDiscussions(filters: event.filters);

    if (result is Success<DiscussionPage>) {
      final page = result.data.copyWith(
        data: result.data.data
            .map(
              (discussion) =>
                  _applyConfirmedRead(discussion, requestReadMarkSequence),
            )
            .toList(growable: false),
      );
      final selectedDiscussionId = _resolveSelectedDiscussionId();
      final selectedDiscussion = _findById(page.data, selectedDiscussionId);

      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          page: page,
          filters: event.filters,
          selectedDiscussion: selectedDiscussion,
          selectedDiscussionId: selectedDiscussionId,
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionPage>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.error,
          errorMessage: result.failure.message,
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
      // Abrir un detalle nunca dispara una recarga del listado: si un filtro
      // no se puede decidir localmente, la copia del listado se reemplaza o se
      // deja como esta.
      final merged = _mergeDiscussionIntoPage(state.page, selected);
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: selected,
          selectedDiscussionId: selected.id,
          page: merged.page,
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

    if (result is Success<DiscussionReadState>) {
      if (!result.data.isUnread) {
        _readMarkSequenceById[discussionId] = ++_readMarkSequence;
      }

      final nextPage = _updateDiscussionReadState(
        current: state.page,
        discussionId: discussionId,
        isUnread: result.data.isUnread,
      );

      Discussion? nextSelectedDiscussion = state.selectedDiscussion;
      if (nextSelectedDiscussion != null &&
          nextSelectedDiscussion.id == discussionId) {
        nextSelectedDiscussion = nextSelectedDiscussion.copyWith(
          isUnread: result.data.isUnread,
        );
      }

      final nextInProgress = Set<String>.from(state.markingAsReadDiscussionIds)
        ..remove(discussionId);

      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          page: nextPage,
          selectedDiscussion: nextSelectedDiscussion,
          markingAsReadDiscussionIds: nextInProgress,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionReadState>) {
      final nextInProgress = Set<String>.from(state.markingAsReadDiscussionIds)
        ..remove(discussionId);

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

    if (result is Success<Discussion>) {
      final created = result.data;
      final merged = _mergeDiscussionIntoPage(
        state.page,
        created,
        createdByCurrentUser: true,
      );
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: created,
          selectedDiscussionId: created.id,
          page: merged.page,
          errorMessage: '',
        ),
      );
      if (merged.needsReload) {
        add(LoadDiscussionsEvent(filters: state.filters, silent: true));
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

    if (result is Success<Discussion>) {
      final updated = _withKnownReadState(result.data);
      final merged = _mergeDiscussionIntoPage(state.page, updated);
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: updated,
          selectedDiscussionId: updated.id,
          page: merged.page,
          errorMessage: '',
        ),
      );
      if (merged.needsReload) {
        add(LoadDiscussionsEvent(filters: state.filters, silent: true));
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
    final merged = _mergeDiscussionIntoPage(
      state.page,
      saved,
      createdByCurrentUser: event.created,
    );
    final isSelected =
        saved.id != null && saved.id == _resolveSelectedDiscussionId();

    emit(
      state.copyWith(
        page: merged.page,
        selectedDiscussion: isSelected ? saved : null,
      ),
    );

    if (merged.needsReload) {
      add(LoadDiscussionsEvent(filters: state.filters, silent: true));
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
        selectedDiscussion: _findById(state.page.data, discussionId),
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

    await _handleDiscussionOperationResult(
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

    await _handleDiscussionOperationResult(
      emit: emit,
      result: result,
      successMessage: 'Asignaciones actualizadas correctamente.',
      clearAssignmentOperation: true,
      assignmentsChanged: true,
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

    await _handleDiscussionOperationResult(
      emit: emit,
      result: result,
      successMessage: 'Asignaciones actualizadas correctamente.',
      clearAssignmentOperation: true,
      assignmentsChanged: true,
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

    await _handleDiscussionOperationResult(
      emit: emit,
      result: result,
      successMessage: 'Asignacion removida correctamente.',
      clearAssignmentOperation: true,
      assignmentsChanged: true,
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

    await _handleDiscussionOperationResult(
      emit: emit,
      result: result,
      successMessage: 'La discussion fue asignada a tu usuario.',
      clearAssignmentOperation: true,
      assignmentsChanged: true,
    );
  }

  void _onClearOperationMessage(
    ClearDiscussionOperationMessageEvent event,
    Emitter<DiscussionState> emit,
  ) {
    emit(state.copyWith(operationMessage: '', errorMessage: ''));
  }

  Future<void> _handleDiscussionOperationResult({
    required Emitter<DiscussionState> emit,
    required Result<Discussion> result,
    required String successMessage,
    bool clearStatusOperation = false,
    bool clearAssignmentOperation = false,
    bool assignmentsChanged = false,
  }) async {
    if (result is Success<Discussion>) {
      final updated = _withKnownReadState(result.data);
      final merged = _mergeDiscussionIntoPage(
        state.page,
        updated,
        assignmentsChanged: assignmentsChanged,
      );
      final selectedId = _resolveSelectedDiscussionId(updated);

      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          page: merged.page,
          selectedDiscussionId: selectedId,
          // La respuesta es la version vigente aunque los filtros del tablero
          // la saquen del listado (el detalle la sigue mostrando).
          selectedDiscussion: selectedId == updated.id
              ? updated
              : _findById(merged.page.data, selectedId),
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
      // listado); solo se recarga cuando los filtros activos no permiten
      // decidir localmente si sigue perteneciendo al listado.
      if (merged.needsReload) {
        add(LoadDiscussionsEvent(filters: state.filters, silent: true));
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

  /// Incorpora al listado una discussion confirmada por el backend (respuesta
  /// de un `GET`/`POST`/`PATCH`) respetando los filtros activos, el orden del
  /// backend (`createdAt` descendente) y el tamaño de pagina.
  ///
  /// `needsReload` es `true` solo cuando un filtro no se puede decidir
  /// localmente (`mine`/`assignedToMe` dependen del usuario autenticado, que
  /// el bloc no conoce) y la operacion pudo cambiar la pertenencia al
  /// listado; en ese caso hace falta pedir el listado de nuevo.
  ({DiscussionPage page, bool needsReload}) _mergeDiscussionIntoPage(
    DiscussionPage current,
    Discussion discussion, {
    bool createdByCurrentUser = false,
    bool assignmentsChanged = false,
  }) {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return (page: current, needsReload: false);
    }

    final index = current.data.indexWhere((item) => item.id == discussionId);
    final exists = index >= 0;
    final matches = _matchesActiveFilters(
      discussion,
      createdByCurrentUser: createdByCurrentUser,
    );

    if (matches == null) {
      final membershipMayChange =
          !exists || (assignmentsChanged && state.filters.assignedToMe);
      if (membershipMayChange) {
        return (
          page: exists
              ? current.copyWith(
                  data: _replaceAt(current.data, index, discussion),
                )
              : current,
          needsReload: true,
        );
      }
    }

    if (matches == false) {
      if (!exists) {
        return (page: current, needsReload: false);
      }

      // Si el backend tiene mas resultados que los cargados, al sacarla el
      // primero de la pagina siguiente deberia ocupar su lugar y localmente no
      // se conoce: se recarga para que el listado sea el mismo que devolveria
      // el servidor.
      final hasMoreResults = current.total > current.data.length;
      final data = List<Discussion>.from(current.data)..removeAt(index);
      return (
        page: _withTotals(current, data, current.total - 1),
        needsReload: hasMoreResults,
      );
    }

    if (exists) {
      return (
        page: current.copyWith(
          data: _replaceAt(current.data, index, discussion),
        ),
        needsReload: false,
      );
    }

    // Nueva en el listado: se ubica en el orden del backend (`createdAt`
    // descendente, `id` ascendente). Una recien creada queda primera; una que
    // vuelve a cumplir los filtros recupera su posicion. Solo se calcula sobre
    // la primera pagina (la que usa el tablero) y con `createdAt` conocido.
    if (current.page != 1 || discussion.createdAt == null) {
      return (page: current, needsReload: true);
    }

    final data = List<Discussion>.from(current.data);
    final position = data.indexWhere(
      (item) => _compareByBackendOrder(discussion, item) < 0,
    );
    data.insert(position < 0 ? data.length : position, discussion);

    // Si la pagina ya estaba completa, la ultima pasa a la pagina siguiente
    // (puede ser la propia discussion si es mas antigua que todas).
    if (current.limit > 0 && data.length > current.limit) {
      data.removeLast();
    }

    return (
      page: _withTotals(current, data, current.total + 1),
      needsReload: false,
    );
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
  /// `moduleIds`/`componentIds`/`tagIds` basta con coincidir en uno).
  /// Devuelve `null` si el resultado depende del usuario autenticado.
  bool? _matchesActiveFilters(
    Discussion discussion, {
    bool createdByCurrentUser = false,
  }) {
    final filters = state.filters;

    final type = filters.type;
    if (type != null &&
        type != DiscussionType.unknown &&
        discussion.type != type) {
      return false;
    }

    final status = filters.status;
    if (status != null &&
        status != DiscussionRecordStatus.unknown &&
        discussion.status != status) {
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

    if (filters.assignedToMe) {
      if (discussion.assignedDevelopers.isEmpty) {
        return false;
      }
      return null;
    }

    if (filters.mine && !createdByCurrentUser) {
      return null;
    }

    return true;
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

  DiscussionPage _withTotals(
    DiscussionPage current,
    List<Discussion> data,
    int total,
  ) {
    final normalizedTotal = total < data.length ? data.length : total;
    final totalPages = normalizedTotal == 0
        ? 0
        : current.limit > 0
        ? (normalizedTotal / current.limit).ceil()
        : current.totalPages;

    return current.copyWith(
      data: List<Discussion>.unmodifiable(data),
      total: normalizedTotal,
      totalPages: totalPages,
    );
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
  /// Se conserva el valor ya conocido y, si la operacion movio `updatedAt`,
  /// queda como no leida: el backend calcula `isUnread` comparando la ultima
  /// lectura del usuario con `GREATEST(updated_at, ultimo mensaje)` y estas
  /// operaciones no registran la lectura de quien las hace. Es lo mismo que
  /// antes mostraba la recarga del listado que seguia a cada operacion.
  Discussion _withKnownReadState(Discussion updated) {
    final discussionId = updated.id;
    if (discussionId == null || discussionId.isEmpty) {
      return updated;
    }

    final known = _findDiscussionInState(discussionId);
    if (known == null) {
      return updated;
    }

    final previousUpdatedAt = known.updatedAt;
    final nextUpdatedAt = updated.updatedAt;
    final activityMoved =
        previousUpdatedAt != null &&
        nextUpdatedAt != null &&
        nextUpdatedAt.isAfter(previousUpdatedAt);

    return updated.copyWith(isUnread: known.isUnread || activityMoved);
  }

  List<Discussion> _applyActiveFilters(List<Discussion> discussions) {
    var filtered = discussions;

    final statusFilter = state.filters.status;
    if (statusFilter != null &&
        statusFilter != DiscussionRecordStatus.unknown) {
      filtered = filtered
          .where((item) => item.status == statusFilter)
          .toList(growable: false);
    }

    final unreadFilter = state.filters.unread;
    if (unreadFilter != null) {
      filtered = filtered
          .where((item) => item.isUnread == unreadFilter)
          .toList(growable: false);
    }

    return filtered;
  }

  DiscussionPage _updateDiscussionReadState({
    required DiscussionPage current,
    required String discussionId,
    required bool isUnread,
  }) {
    final updatedData = current.data
        .map(
          (discussion) => discussion.id == discussionId
              ? discussion.copyWith(isUnread: isUnread)
              : discussion,
        )
        .toList(growable: false);

    final filteredData = _applyActiveFilters(updatedData);
    final total = state.filters.unread == true
        ? filteredData.length
        : current.total;
    final totalPages = total == 0
        ? 0
        : current.limit > 0
        ? (total / current.limit).ceil()
        : current.totalPages;

    return current.copyWith(
      data: filteredData,
      total: total,
      totalPages: totalPages,
    );
  }

  Discussion? _findDiscussionInState(String discussionId) {
    final selected = state.selectedDiscussion;
    if (selected != null && selected.id == discussionId) {
      return selected;
    }

    return _findById(state.page.data, discussionId);
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
}
