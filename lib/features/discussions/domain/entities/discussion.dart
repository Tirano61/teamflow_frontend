import '../../../work_modules/domain/entities/work_module.dart';
import '../../../components/domain/entities/component.dart';
import 'discussion_developer.dart';

enum DiscussionType { error, idea, improvement, question, unknown }

extension DiscussionTypeX on DiscussionType {
  String get apiValue {
    switch (this) {
      case DiscussionType.error:
        return 'ERROR';
      case DiscussionType.idea:
        return 'IDEA';
      case DiscussionType.improvement:
        return 'IMPROVEMENT';
      case DiscussionType.question:
        return 'QUESTION';
      case DiscussionType.unknown:
        return 'UNKNOWN';
    }
  }

  static DiscussionType fromApiValue(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'ERROR':
        return DiscussionType.error;
      case 'IDEA':
        return DiscussionType.idea;
      case 'IMPROVEMENT':
        return DiscussionType.improvement;
      case 'QUESTION':
        return DiscussionType.question;
      default:
        return DiscussionType.unknown;
    }
  }
}

enum DiscussionRecordStatus {
  newDiscussion,
  review,
  inProgress,
  resolved,
  unknown,
}

extension DiscussionRecordStatusX on DiscussionRecordStatus {
  String get apiValue {
    switch (this) {
      case DiscussionRecordStatus.newDiscussion:
        return 'NEW';
      case DiscussionRecordStatus.review:
        return 'REVIEW';
      case DiscussionRecordStatus.inProgress:
        return 'IN_PROGRESS';
      case DiscussionRecordStatus.resolved:
        return 'RESOLVED';
      case DiscussionRecordStatus.unknown:
        return 'UNKNOWN';
    }
  }

  static DiscussionRecordStatus fromApiValue(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'NEW':
        return DiscussionRecordStatus.newDiscussion;
      case 'REVIEW':
        return DiscussionRecordStatus.review;
      case 'IN_PROGRESS':
        return DiscussionRecordStatus.inProgress;
      case 'RESOLVED':
        return DiscussionRecordStatus.resolved;
      default:
        return DiscussionRecordStatus.unknown;
    }
  }
}

class DiscussionCreator {
  const DiscussionCreator({required this.id, this.email, this.fullName});

  final String id;
  final String? email;
  final String? fullName;

  DiscussionCreator copyWith({String? id, String? email, String? fullName}) {
    return DiscussionCreator(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
    );
  }
}

class DiscussionTag {
  const DiscussionTag({
    required this.id,
    required this.name,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DiscussionTag copyWith({
    String? id,
    String? name,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiscussionTag(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Discussion {
  const Discussion({
    this.id,
    required this.type,
    required this.title,
    this.initialMessageContent,
    this.status = DiscussionRecordStatus.newDiscussion,
    this.isUnread = false,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.workModules = const [],
    this.components = const [],
    this.tags = const [],
    this.moduleIds = const [],
    this.componentIds = const [],
    this.tagIds = const [],
    this.assignedDevelopers = const [],
  });

  final String? id;
  final DiscussionType type;
  final String title;
  final String? initialMessageContent;
  final DiscussionRecordStatus status;
  final bool isUnread;
  final DiscussionCreator? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<WorkModule> workModules;
  final List<Component> components;
  final List<DiscussionTag> tags;
  final List<String> moduleIds;
  final List<String> componentIds;
  final List<String> tagIds;
  final List<DiscussionAssignedDeveloper> assignedDevelopers;

  List<String> get resolvedModuleIds {
    final ids = <String>{
      ...moduleIds,
      ...workModules
          .where((workModule) => workModule.id != null)
          .map((workModule) => workModule.id!),
    };
    return List<String>.unmodifiable(ids);
  }

  List<String> get resolvedComponentIds {
    final ids = <String>{
      ...componentIds,
      ...components
          .where((component) => component.id != null)
          .map((component) => component.id!),
    };
    return List<String>.unmodifiable(ids);
  }

  List<String> get resolvedTagIds {
    final ids = <String>{...tagIds, ...tags.map((tag) => tag.id)};
    return List<String>.unmodifiable(ids);
  }

  Discussion copyWith({
    String? id,
    DiscussionType? type,
    String? title,
    String? initialMessageContent,
    DiscussionRecordStatus? status,
    bool? isUnread,
    DiscussionCreator? createdBy,
    bool clearCreatedBy = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<WorkModule>? workModules,
    List<Component>? components,
    List<DiscussionTag>? tags,
    List<String>? moduleIds,
    List<String>? componentIds,
    List<String>? tagIds,
    List<DiscussionAssignedDeveloper>? assignedDevelopers,
  }) {
    return Discussion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      initialMessageContent:
          initialMessageContent ?? this.initialMessageContent,
      status: status ?? this.status,
        isUnread: isUnread ?? this.isUnread,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workModules: workModules ?? this.workModules,
      components: components ?? this.components,
      tags: tags ?? this.tags,
      moduleIds: moduleIds ?? this.moduleIds,
      componentIds: componentIds ?? this.componentIds,
      tagIds: tagIds ?? this.tagIds,
      assignedDevelopers: assignedDevelopers ?? this.assignedDevelopers,
    );
  }
}

class DiscussionReadState {
  const DiscussionReadState({
    required this.discussionId,
    this.lastReadAt,
    required this.isUnread,
  });

  final String discussionId;
  final DateTime? lastReadAt;
  final bool isUnread;
}



