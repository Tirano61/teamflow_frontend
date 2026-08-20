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

    final result = await _getDiscussions(filters: event.filters);

    if (result is Success<DiscussionPage>) {
      final selectedDiscussionId = _resolveSelectedDiscussionId();
      final selectedDiscussion = _findById(result.data.data, selectedDiscussionId);

      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          page: result.data,
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

    final result = await _getDiscussion(event.id);

    if (result is Success<Discussion>) {
      final selected = result.data;
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: selected,
          selectedDiscussionId: selected.id,
          page: _mergeDiscussionIntoPage(state.page, selected),
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
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: created,
          selectedDiscussionId: created.id,
          page: _mergeDiscussionIntoPage(state.page, created),
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

  Future<void> _onUpdateDiscussion(
    UpdateDiscussionEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(state.copyWith(status: DiscussionStatus.loading, errorMessage: ''));

    final result = await _updateDiscussion(event.discussion);

    if (result is Success<Discussion>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: updated,
          selectedDiscussionId: updated.id,
          page: _mergeDiscussionIntoPage(state.page, updated),
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
  }) async {
    if (result is Success<Discussion>) {
      final updated = result.data;
      final nextPage = _mergeDiscussionIntoPage(state.page, updated);
      final selectedId = _resolveSelectedDiscussionId(updated);

      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          page: nextPage,
          selectedDiscussionId: selectedId,
          selectedDiscussion: _findById(nextPage.data, selectedId),
          isUpdatingStatus: clearStatusOperation ? false : state.isUpdatingStatus,
          isUpdatingAssignments: clearAssignmentOperation
              ? false
              : state.isUpdatingAssignments,
          clearOperationDiscussionId:
              clearStatusOperation || clearAssignmentOperation,
          errorMessage: '',
          operationMessage: successMessage,
        ),
      );

      add(LoadDiscussionsEvent(filters: state.filters, silent: true));
      return;
    }

    if (result is FailureResult<Discussion>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.error,
          isUpdatingStatus: clearStatusOperation ? false : state.isUpdatingStatus,
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

  DiscussionPage _mergeDiscussionIntoPage(
    DiscussionPage current,
    Discussion discussion,
  ) {
    final alreadyExists = _containsDiscussion(current.data, discussion);
    var mergedData = _upsertById(current.data, discussion);
    mergedData = _applyActiveFilters(mergedData);

    var mergedTotal = current.total;
    if (!alreadyExists) {
      mergedTotal = current.total > 0 ? current.total + 1 : mergedData.length;
    }

    if (mergedTotal < mergedData.length) {
      mergedTotal = mergedData.length;
    }

    final mergedTotalPages = mergedTotal == 0
        ? 0
        : current.limit > 0
        ? (mergedTotal / current.limit).ceil()
        : current.totalPages;

    return current.copyWith(
      data: mergedData,
      total: mergedTotal,
      totalPages: mergedTotalPages,
    );
  }

  List<Discussion> _applyActiveFilters(List<Discussion> discussions) {
    var filtered = discussions;

    final statusFilter = state.filters.status;
    if (statusFilter != null && statusFilter != DiscussionRecordStatus.unknown) {
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

    return current.copyWith(data: filteredData, total: total, totalPages: totalPages);
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

  bool _containsDiscussion(List<Discussion> current, Discussion discussion) {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return false;
    }

    return current.any((item) => item.id == discussionId);
  }

  List<Discussion> _upsertById(
    List<Discussion> current,
    Discussion discussion,
  ) {
    final next = List<Discussion>.from(current);
    final index = next.indexWhere(
      (item) =>
          item.id != null && discussion.id != null && item.id == discussion.id,
    );

    if (index >= 0) {
      next[index] = discussion;
      return List<Discussion>.unmodifiable(next);
    }

    next.insert(0, discussion);
    return List<Discussion>.unmodifiable(next);
  }
}
