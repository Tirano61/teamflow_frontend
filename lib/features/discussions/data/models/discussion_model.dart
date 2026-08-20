import '../../../../core/error/exceptions.dart';
import '../../../applications/data/models/application_model.dart';
import '../../../indicators/data/models/indicator_model.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_developer.dart';
import '../../domain/entities/discussion_page.dart';

class DiscussionAssignedDeveloperModel {
  const DiscussionAssignedDeveloperModel({
    required this.id,
    required this.fullName,
    this.email,
  });

  final String id;
  final String fullName;
  final String? email;

  factory DiscussionAssignedDeveloperModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', '_id', 'uuid', 'userId']);
    final fullName = _readString(json, const ['fullName', 'full_name', 'name']);

    if (id == null || id.isEmpty || fullName == null || fullName.isEmpty) {
      throw const DataParsingException(
        'Assigned developer fields are missing in backend payload.',
      );
    }

    return DiscussionAssignedDeveloperModel(
      id: id,
      fullName: fullName,
      email: _readString(json, const ['email', 'mail']),
    );
  }

  DiscussionAssignedDeveloper toEntity() {
    return DiscussionAssignedDeveloper(id: id, fullName: fullName);
  }
}

class AssignableDeveloperModel {
  const AssignableDeveloperModel({
    required this.id,
    required this.fullName,
    this.email,
  });

  final String id;
  final String fullName;
  final String? email;

  factory AssignableDeveloperModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', '_id', 'uuid', 'userId']);
    final fullName = _readString(json, const ['fullName', 'full_name', 'name']);

    if (id == null || id.isEmpty || fullName == null || fullName.isEmpty) {
      throw const DataParsingException(
        'Assignable developer fields are missing in backend payload.',
      );
    }

    return AssignableDeveloperModel(
      id: id,
      fullName: fullName,
      email: _readString(json, const ['email', 'mail']),
    );
  }

  AssignableDeveloper toEntity() {
    return AssignableDeveloper(id: id, fullName: fullName, email: email);
  }
}

class DiscussionCreatorModel {
  const DiscussionCreatorModel({required this.id, this.email, this.fullName});

  final String id;
  final String? email;
  final String? fullName;

  factory DiscussionCreatorModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', '_id', 'uuid']);
    if (id == null || id.isEmpty) {
      throw const DataParsingException(
        'Discussion creator id is missing in backend payload.',
      );
    }

    return DiscussionCreatorModel(
      id: id,
      email: _readString(json, const ['email', 'mail']),
      fullName: _readString(json, const ['fullName', 'full_name', 'name']),
    );
  }

  DiscussionCreator toEntity() {
    return DiscussionCreator(id: id, email: email, fullName: fullName);
  }

  factory DiscussionCreatorModel.fromEntity(DiscussionCreator entity) {
    return DiscussionCreatorModel(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
    );
  }
}

class DiscussionTagModel {
  const DiscussionTagModel({
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

  factory DiscussionTagModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', '_id', 'uuid']);
    final name = _readString(json, const ['name', 'tag', 'title']);

    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      throw const DataParsingException(
        'Discussion tag fields are missing in backend payload.',
      );
    }

    return DiscussionTagModel(
      id: id,
      name: name,
      active: _readBool(json, const ['active']) ?? true,
      createdAt: _readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: _readDateTime(json, const ['updatedAt', 'updated_at']),
    );
  }

  DiscussionTag toEntity() {
    return DiscussionTag(
      id: id,
      name: name,
      active: active,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory DiscussionTagModel.fromEntity(DiscussionTag entity) {
    return DiscussionTagModel(
      id: entity.id,
      name: entity.name,
      active: entity.active,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

class DiscussionModel {
  const DiscussionModel({
    this.id,
    required this.type,
    required this.title,
    this.initialMessageContent,
    this.status = DiscussionRecordStatus.newDiscussion,
    this.isUnread = false,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.applications = const [],
    this.indicators = const [],
    this.tags = const [],
    this.applicationIds = const [],
    this.indicatorIds = const [],
    this.tagIds = const [],
    this.assignedDevelopers = const [],
  });

  final String? id;
  final DiscussionType type;
  final String title;
  final String? initialMessageContent;
  final DiscussionRecordStatus status;
  final bool isUnread;
  final DiscussionCreatorModel? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ApplicationModel> applications;
  final List<IndicatorModel> indicators;
  final List<DiscussionTagModel> tags;
  final List<String> applicationIds;
  final List<String> indicatorIds;
  final List<String> tagIds;
  final List<DiscussionAssignedDeveloperModel> assignedDevelopers;

  factory DiscussionModel.fromJson(Map<String, dynamic> json) {
    final applications = _readApplicationModels(json);
    final indicators = _readIndicatorModels(json);
    final tags = _readTagModels(json);

    final parsedApplicationIds = _readStringList(json, const [
      'applicationIds',
      'application_ids',
    ]);
    final parsedIndicatorIds = _readStringList(json, const [
      'indicatorIds',
      'indicator_ids',
    ]);
    final parsedTagIds = _readStringList(json, const ['tagIds', 'tag_ids']);
    final assignedDevelopers = _readAssignedDeveloperModels(json);

    return DiscussionModel(
      id: _readString(json, const ['id', '_id', 'uuid']),
      type: DiscussionTypeX.fromApiValue(_readString(json, const ['type'])),
      title: _readString(json, const ['title']) ?? '',
      status: DiscussionRecordStatusX.fromApiValue(
        _readString(json, const ['status']),
      ),
      isUnread: _readBool(json, const ['isUnread', 'is_unread']) ?? false,
      createdBy: _readCreator(json),
      createdAt: _readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: _readDateTime(json, const ['updatedAt', 'updated_at']),
      applications: applications,
      indicators: indicators,
      tags: tags,
      applicationIds: _mergeIds(
        parsedApplicationIds,
        applications
            .map((application) => application.id)
            .whereType<String>()
            .toList(growable: false),
      ),
      indicatorIds: _mergeIds(
        parsedIndicatorIds,
        indicators
            .map((indicator) => indicator.id)
            .whereType<String>()
            .toList(growable: false),
      ),
      tagIds: _mergeIds(
        parsedTagIds,
        tags.map((tag) => tag.id).toList(growable: false),
      ),
      assignedDevelopers: assignedDevelopers,
    );
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'type': type.apiValue,
      'title': title.trim(),
      'applicationIds': _mergeIds(
        applicationIds,
        applications
            .map((application) => application.id)
            .whereType<String>()
            .toList(growable: false),
      ),
      'indicatorIds': _mergeIds(
        indicatorIds,
        indicators
            .map((indicator) => indicator.id)
            .whereType<String>()
            .toList(growable: false),
      ),
      'tagIds': _mergeIds(
        tagIds,
        tags.map((tag) => tag.id).toList(growable: false),
      ),
    };

    final normalizedInitialMessage = initialMessageContent?.trim();
    if (normalizedInitialMessage != null &&
        normalizedInitialMessage.isNotEmpty) {
      payload['initialMessageContent'] = normalizedInitialMessage;
    }

    if (id != null && id!.isNotEmpty) {
      payload['id'] = id;
    }

    return payload;
  }

  Discussion toEntity() {
    return Discussion(
      id: id,
      type: type,
      title: title,
      initialMessageContent: initialMessageContent,
      status: status,
      isUnread: isUnread,
      createdBy: createdBy?.toEntity(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      applications: applications
          .map((application) => application.toEntity())
          .toList(growable: false),
      indicators: indicators
          .map((indicator) => indicator.toEntity())
          .toList(growable: false),
      tags: tags.map((tag) => tag.toEntity()).toList(growable: false),
      applicationIds: applicationIds,
      indicatorIds: indicatorIds,
      tagIds: tagIds,
      assignedDevelopers: assignedDevelopers
          .map((developer) => developer.toEntity())
          .toList(growable: false),
    );
  }

  factory DiscussionModel.fromEntity(Discussion entity) {
    return DiscussionModel(
      id: entity.id,
      type: entity.type,
      title: entity.title,
      initialMessageContent: entity.initialMessageContent,
      status: entity.status,
        isUnread: entity.isUnread,
      createdBy: entity.createdBy != null
          ? DiscussionCreatorModel.fromEntity(entity.createdBy!)
          : null,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      applications: entity.applications
          .map(ApplicationModel.fromEntity)
          .toList(growable: false),
      indicators: entity.indicators
          .map(IndicatorModel.fromEntity)
          .toList(growable: false),
      tags: entity.tags
          .map(DiscussionTagModel.fromEntity)
          .toList(growable: false),
      applicationIds: entity.resolvedApplicationIds,
      indicatorIds: entity.resolvedIndicatorIds,
      tagIds: entity.resolvedTagIds,
      assignedDevelopers: entity.assignedDevelopers
          .map(
            (developer) => DiscussionAssignedDeveloperModel(
              id: developer.id,
              fullName: developer.fullName,
            ),
          )
          .toList(growable: false),
    );
  }

  static DiscussionCreatorModel? _readCreator(Map<String, dynamic> json) {
    final rawCreator = _readFirst(json, const [
      'createdBy',
      'created_by',
      'creator',
      'user',
    ]);

    if (rawCreator == null) {
      return null;
    }

    if (rawCreator is String && rawCreator.trim().isNotEmpty) {
      return DiscussionCreatorModel(id: rawCreator.trim());
    }

    if (rawCreator is Map<String, dynamic>) {
      return DiscussionCreatorModel.fromJson(rawCreator);
    }

    throw const DataParsingException(
      'Unexpected discussion creator payload format.',
    );
  }

  static List<ApplicationModel> _readApplicationModels(
    Map<String, dynamic> json,
  ) {
    final list = _readList(json, const [
      'applications',
      'applicationList',
      'apps',
    ]);

    if (list == null) {
      return const [];
    }

    return list
        .map((item) => ApplicationModel.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  static List<IndicatorModel> _readIndicatorModels(Map<String, dynamic> json) {
    final list = _readList(json, const ['indicators', 'indicatorList']);

    if (list == null) {
      return const [];
    }

    return list
        .map((item) => IndicatorModel.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  static List<DiscussionTagModel> _readTagModels(Map<String, dynamic> json) {
    final list = _readList(json, const ['tags', 'tagList']);

    if (list == null) {
      return const [];
    }

    return list
        .map((item) => DiscussionTagModel.fromJson(_asMap(item)))
        .toList(growable: false);
  }

  static List<DiscussionAssignedDeveloperModel> _readAssignedDeveloperModels(
    Map<String, dynamic> json,
  ) {
    final list = _readList(json, const [
      'assignedDevelopers',
      'assigned_developers',
      'developers',
      'assignees',
    ]);

    if (list == null) {
      return const [];
    }

    return list
        .map((item) => DiscussionAssignedDeveloperModel.fromJson(_asMap(item)))
        .toList(growable: false);
  }
}

class DiscussionPageModel {
  const DiscussionPageModel({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<DiscussionModel> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory DiscussionPageModel.fromPayload(Object? payload) {
    if (payload is List) {
      final list = payload
          .map((item) => DiscussionModel.fromJson(_asMap(item)))
          .toList(growable: false);

      return DiscussionPageModel(
        data: list,
        page: 1,
        limit: list.isEmpty ? 20 : list.length,
        total: list.length,
        totalPages: list.isEmpty ? 0 : 1,
      );
    }

    if (payload is Map<String, dynamic>) {
      final list = _extractDiscussionList(payload)
          .map((item) => DiscussionModel.fromJson(_asMap(item)))
          .toList(growable: false);

      final page = _readInt(payload, const ['page']) ?? 1;
      final limit = _readInt(payload, const ['limit']) ?? 20;
      final total = _readInt(payload, const ['total']) ?? list.length;
      final totalPages =
          _readInt(payload, const ['totalPages']) ??
          (limit > 0 ? (total / limit).ceil() : 0);

      return DiscussionPageModel(
        data: list,
        page: page,
        limit: limit,
        total: total,
        totalPages: totalPages,
      );
    }

    throw const DataParsingException(
      'Unexpected payload format for discussion list response.',
    );
  }

  DiscussionPage toEntity() {
    return DiscussionPage(
      data: data.map((item) => item.toEntity()).toList(growable: false),
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  static List<dynamic> _extractDiscussionList(Map<String, dynamic> map) {
    final data = map['data'];
    if (data is List) {
      return data;
    }

    final discussions = map['discussions'];
    if (discussions is List) {
      return discussions;
    }

    final items = map['items'];
    if (items is List) {
      return items;
    }

    final results = map['results'];
    if (results is List) {
      return results;
    }

    throw const DataParsingException(
      'Discussion list response does not include a data array.',
    );
  }
}

class DiscussionReadStateModel {
  const DiscussionReadStateModel({
    required this.discussionId,
    this.lastReadAt,
    required this.isUnread,
  });

  final String discussionId;
  final DateTime? lastReadAt;
  final bool isUnread;

  factory DiscussionReadStateModel.fromPayload(
    Object? payload, {
    required String fallbackDiscussionId,
  }) {
    if (payload is Map<String, dynamic>) {
      final source = _unwrapReadPayload(payload);
      final parsedDiscussionId = _readString(source, const [
        'discussionId',
        'discussion_id',
      ]);

      return DiscussionReadStateModel(
        discussionId: (parsedDiscussionId ?? fallbackDiscussionId).trim(),
        lastReadAt: _readDateTime(source, const ['lastReadAt', 'last_read_at']),
        isUnread: _readBool(source, const ['isUnread', 'is_unread']) ?? false,
      );
    }

    return DiscussionReadStateModel(
      discussionId: fallbackDiscussionId.trim(),
      isUnread: false,
    );
  }

  DiscussionReadState toEntity() {
    return DiscussionReadState(
      discussionId: discussionId,
      lastReadAt: lastReadAt,
      isUnread: isUnread,
    );
  }

  static Map<String, dynamic> _unwrapReadPayload(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return payload;
  }
}

class AssignableDeveloperListModel {
  const AssignableDeveloperListModel({required this.data});

  final List<AssignableDeveloperModel> data;

  factory AssignableDeveloperListModel.fromPayload(Object? payload) {
    if (payload is List) {
      return AssignableDeveloperListModel(
        data: payload
            .map((item) => AssignableDeveloperModel.fromJson(_asMap(item)))
            .toList(growable: false),
      );
    }

    if (payload is Map<String, dynamic>) {
      final rawList = _extractList(payload, const [
        'data',
        'developers',
        'items',
        'results',
      ]);

      return AssignableDeveloperListModel(
        data: rawList
            .map((item) => AssignableDeveloperModel.fromJson(_asMap(item)))
            .toList(growable: false),
      );
    }

    throw const DataParsingException(
      'Unexpected payload format for assignable developers response.',
    );
  }

  List<AssignableDeveloper> toEntity() {
    return data.map((item) => item.toEntity()).toList(growable: false);
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  throw const DataParsingException(
    'Unexpected item format while parsing discussion payload.',
  );
}

Object? _readFirst(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}

List<dynamic> _extractList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value;
    }
  }

  throw const DataParsingException('Expected a list value in backend payload.');
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  final value = _readFirst(json, keys);
  if (value == null) {
    return null;
  }

  final parsed = value.toString().trim();
  if (parsed.isEmpty) {
    return null;
  }

  return parsed;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  final value = _readFirst(json, keys);
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim());
  }

  return null;
}

bool? _readBool(Map<String, dynamic> json, List<String> keys) {
  final value = _readFirst(json, keys);
  if (value == null) {
    return null;
  }

  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
  }

  return null;
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value);
}

List<dynamic>? _readList(Map<String, dynamic> json, List<String> keys) {
  final value = _readFirst(json, keys);
  if (value == null) {
    return null;
  }

  if (value is List) {
    return value;
  }

  throw const DataParsingException(
    'Expected a list value in discussion payload.',
  );
}

List<String> _readStringList(Map<String, dynamic> json, List<String> keys) {
  final value = _readFirst(json, keys);

  if (value == null) {
    return const [];
  }

  if (value is List) {
    final parsed = value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return parsed;
  }

  if (value is String) {
    final parsed = value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return parsed;
  }

  throw const DataParsingException(
    'Expected a string list value in discussion payload.',
  );
}

List<String> _mergeIds(List<String> primary, List<String> secondary) {
  return <String>{
    ...primary.map((item) => item.trim()).where((item) => item.isNotEmpty),
    ...secondary.map((item) => item.trim()).where((item) => item.isNotEmpty),
  }.toList(growable: false);
}
