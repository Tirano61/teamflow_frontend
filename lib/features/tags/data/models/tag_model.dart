import '../../domain/entities/tag.dart';

class TagModel {
  const TagModel({
    this.id,
    required this.name,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: _readString(json, const ['id', '_id', 'uuid']),
      name: _readString(json, const ['name', 'title', 'tagName']) ?? '',
      active: _readBool(json, const ['active']) ?? true,
      createdAt: _readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: _readDateTime(json, const ['updatedAt', 'updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': name, 'active': active};

    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  Tag toEntity() {
    return Tag(
      id: id,
      name: name,
      active: active,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory TagModel.fromEntity(Tag entity) {
    return TagModel(
      id: entity.id,
      name: entity.name,
      active: entity.active,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      final parsed = value.toString().trim();
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    return null;
  }

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      if (value is bool) {
        return value;
      }

      if (value is num) {
        return value != 0;
      }

      final parsed = value.toString().trim().toLowerCase();
      if (parsed == 'true' || parsed == '1') {
        return true;
      }
      if (parsed == 'false' || parsed == '0') {
        return false;
      }
    }

    return null;
  }

  static DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
