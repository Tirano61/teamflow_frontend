import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_developer.dart';
import '../../domain/entities/discussion_filters.dart';
import '../../domain/entities/discussion_page.dart';

enum DiscussionStatus { initial, loading, success, error }

class DiscussionState {
  const DiscussionState({
    this.status = DiscussionStatus.initial,
    this.page = DiscussionPage.empty,
    this.filters = const DiscussionFilters(),
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
  final DiscussionPage page;
  final DiscussionFilters filters;
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

  List<Discussion> get discussions => page.data;

  DiscussionState copyWith({
    DiscussionStatus? status,
    DiscussionPage? page,
    DiscussionFilters? filters,
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
      page: page ?? this.page,
      filters: filters ?? this.filters,
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
