import '../../domain/entities/indicator.dart';

class IndicatorModel {
  const IndicatorModel({
    this.id,
    required this.name,
    this.description,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final String? description;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory IndicatorModel.fromJson(Map<String, dynamic> json) {
    return IndicatorModel(
      id: _readString(json, const ['id', '_id', 'uuid']),
      name: _readString(json, const ['name', 'title', 'indicatorName']) ?? '',
      description: _readString(json, const ['description', 'detail']),
      active: _readBool(json, const ['active']) ?? true,
      createdAt: _readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: _readDateTime(json, const ['updatedAt', 'updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
    };

    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  Indicator toEntity() {
    return Indicator(
      id: id,
      name: name,
      description: description,
      active: active,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory IndicatorModel.fromEntity(Indicator entity) {
    return IndicatorModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
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

  static DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value);
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
}
