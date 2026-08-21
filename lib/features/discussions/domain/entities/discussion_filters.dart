import 'discussion.dart';

class DiscussionFilters {
  const DiscussionFilters({
    this.page = 1,
    this.limit = 20,
    this.type,
    this.status,
    this.moduleIds = const [],
    this.componentIds = const [],
    this.tagIds = const [],
    this.createdBy,
    this.mine = false,
    this.assignedToMe = false,
    this.assignedDeveloperId,
    this.unread,
  });

  final int page;
  final int limit;
  final DiscussionType? type;
  final DiscussionRecordStatus? status;
  final List<String> moduleIds;
  final List<String> componentIds;
  final List<String> tagIds;
  final String? createdBy;
  final bool mine;
  final bool assignedToMe;
  final String? assignedDeveloperId;
  final bool? unread;

  DiscussionFilters copyWith({
    int? page,
    int? limit,
    DiscussionType? type,
    bool clearType = false,
    DiscussionRecordStatus? status,
    bool clearStatus = false,
    List<String>? moduleIds,
    List<String>? componentIds,
    List<String>? tagIds,
    String? createdBy,
    bool clearCreatedBy = false,
    bool? mine,
    bool? assignedToMe,
    String? assignedDeveloperId,
    bool clearAssignedDeveloperId = false,
    bool? unread,
    bool clearUnread = false,
  }) {
    return DiscussionFilters(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      type: clearType ? null : type ?? this.type,
      status: clearStatus ? null : status ?? this.status,
      moduleIds: moduleIds ?? this.moduleIds,
      componentIds: componentIds ?? this.componentIds,
      tagIds: tagIds ?? this.tagIds,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      mine: mine ?? this.mine,
      assignedToMe: assignedToMe ?? this.assignedToMe,
      assignedDeveloperId: clearAssignedDeveloperId
          ? null
          : assignedDeveloperId ?? this.assignedDeveloperId,
      unread: clearUnread ? null : unread ?? this.unread,
    );
  }
}



