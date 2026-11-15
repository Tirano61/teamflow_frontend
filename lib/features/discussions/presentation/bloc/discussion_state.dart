import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_developer.dart';
import '../../domain/entities/discussion_filters.dart';
import '../../domain/entities/discussion_summary.dart';

/// Estado de las operaciones sobre una discussion (detalle, creacion,
/// edicion). El listado paginado usa [DiscussionListStatus].
enum DiscussionStatus { initial, loading, success, error }

/// Estado de la primera pagina del listado para los filtros vigentes.
enum DiscussionListStatus {
  /// Todavia no se pidio el listado.
  initial,

  /// Primera pagina en curso sin discussions que mostrar (primera carga o
  /// cambio de filtros).
  loading,

  /// Hay una primera pagina cargada para los filtros vigentes.
  ready,

  /// Fallo la primera pagina y no hay discussions que mostrar.
  failure,
}

class DiscussionState {
  const DiscussionState({
    this.status = DiscussionStatus.initial,
    this.listStatus = DiscussionListStatus.initial,
    this.discussions = const [],
    this.nextCursor,
    this.hasNextPage = false,
    this.summary,
    this.isRefreshingList = false,
    this.isLoadingNextPage = false,
    this.nextPageErrorMessage = '',
    this.filters = const DiscussionFilters(),
    this.currentUserId,
    this.selectedDiscussion,
    this.selectedDiscussionId,
    this.assignableDevelopers = const [],
    this.isLoadingAssignableDevelopers = false,
    this.isUpdatingStatus = false,
    this.isUpdatingAssignments = false,
    this.markingAsReadDiscussionIds = const <String>{},
    this.operationDiscussionId,
    this.errorMessage = '',
    this.operationMessage = '',
  });

  final DiscussionStatus status;
  final DiscussionListStatus listStatus;

  /// Discussions acumuladas de todas las paginas cargadas, en el orden del
  /// backend (`createdAt` DESC, `id` ASC).
  final List<Discussion> discussions;

  /// Cursor opaco para la pagina siguiente del recorrido vigente.
  final String? nextCursor;
  final bool hasNextPage;

  /// Ultimo `summary` valido para los filtros vigentes. `null` mientras se
  /// carga la primera pagina de filtros nuevos (no se muestran contadores del
  /// filtro anterior).
  final DiscussionSummary? summary;

  /// Primera pagina en curso por un refresh explicito, con las discussions
  /// anteriores todavia visibles.
  final bool isRefreshingList;
  final bool isLoadingNextPage;

  /// Error de la ultima pagina siguiente. Las discussions cargadas se
  /// conservan y se puede reintentar.
  final String nextPageErrorMessage;

  final DiscussionFilters filters;

  /// Usuario autenticado. Permite decidir localmente los filtros `mine` y
  /// `assignedToMe` sin volver a pedir el listado.
  final String? currentUserId;

  final Discussion? selectedDiscussion;
  final String? selectedDiscussionId;
  final List<AssignableDeveloper> assignableDevelopers;
  final bool isLoadingAssignableDevelopers;
  final bool isUpdatingStatus;
  final bool isUpdatingAssignments;
  final Set<String> markingAsReadDiscussionIds;
  final String? operationDiscussionId;
  final String errorMessage;
  final String operationMessage;

  /// Se puede pedir la pagina siguiente automaticamente (sin error pendiente).
  bool get canLoadNextPage =>
      listStatus == DiscussionListStatus.ready &&
      hasNextPage &&
      !isLoadingNextPage &&
      nextPageErrorMessage.isEmpty;

  DiscussionState copyWith({
    DiscussionStatus? status,
    DiscussionListStatus? listStatus,
    List<Discussion>? discussions,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? hasNextPage,
    DiscussionSummary? summary,
    bool clearSummary = false,
    bool? isRefreshingList,
    bool? isLoadingNextPage,
    String? nextPageErrorMessage,
    DiscussionFilters? filters,
    String? currentUserId,
    Discussion? selectedDiscussion,
    bool clearSelectedDiscussion = false,
    String? selectedDiscussionId,
    bool clearSelectedDiscussionId = false,
    List<AssignableDeveloper>? assignableDevelopers,
    bool? isLoadingAssignableDevelopers,
    bool? isUpdatingStatus,
    bool? isUpdatingAssignments,
    Set<String>? markingAsReadDiscussionIds,
    String? operationDiscussionId,
    bool clearOperationDiscussionId = false,
    String? errorMessage,
    String? operationMessage,
  }) {
    return DiscussionState(
      status: status ?? this.status,
      listStatus: listStatus ?? this.listStatus,
      discussions: discussions ?? this.discussions,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      summary: clearSummary ? null : summary ?? this.summary,
      isRefreshingList: isRefreshingList ?? this.isRefreshingList,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      nextPageErrorMessage: nextPageErrorMessage ?? this.nextPageErrorMessage,
      filters: filters ?? this.filters,
      currentUserId: currentUserId ?? this.currentUserId,
      selectedDiscussion: clearSelectedDiscussion
          ? null
          : selectedDiscussion ?? this.selectedDiscussion,
      selectedDiscussionId: clearSelectedDiscussionId
          ? null
          : selectedDiscussionId ?? this.selectedDiscussionId,
      assignableDevelopers: assignableDevelopers ?? this.assignableDevelopers,
      isLoadingAssignableDevelopers:
          isLoadingAssignableDevelopers ?? this.isLoadingAssignableDevelopers,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      isUpdatingAssignments:
          isUpdatingAssignments ?? this.isUpdatingAssignments,
      markingAsReadDiscussionIds:
          markingAsReadDiscussionIds ?? this.markingAsReadDiscussionIds,
      operationDiscussionId: clearOperationDiscussionId
          ? null
          : operationDiscussionId ?? this.operationDiscussionId,
      errorMessage: errorMessage ?? this.errorMessage,
      operationMessage: operationMessage ?? this.operationMessage,
    );
  }
}
