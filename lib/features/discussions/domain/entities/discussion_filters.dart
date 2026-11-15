import 'discussion.dart';

/// Filtros de `GET .../discussions`. Identifican un recorrido paginado: el
/// cursor de una pagina solo sirve con los mismos filtros (el `limit` no forma
/// parte del cursor).
class DiscussionFilters {
  const DiscussionFilters({
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

  /// Mismos filtros salvo `status`: los contadores `byStatus` de uno sirven
  /// para el otro.
  bool equalsIgnoringStatus(DiscussionFilters other) {
    return limit == other.limit &&
        type == other.type &&
        _sameIds(moduleIds, other.moduleIds) &&
        _sameIds(componentIds, other.componentIds) &&
        _sameIds(tagIds, other.tagIds) &&
        createdBy == other.createdBy &&
        mine == other.mine &&
        assignedToMe == other.assignedToMe &&
        assignedDeveloperId == other.assignedDeveloperId &&
        unread == other.unread;
  }

  @override
  bool operator ==(Object other) {
    return other is DiscussionFilters &&
        status == other.status &&
        equalsIgnoringStatus(other);
  }

  @override
  int get hashCode => Object.hash(
    limit,
    type,
    status,
    Object.hashAll(moduleIds),
    Object.hashAll(componentIds),
    Object.hashAll(tagIds),
    createdBy,
    mine,
    assignedToMe,
    assignedDeveloperId,
    unread,
  );

  static bool _sameIds(List<String> a, List<String> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
