import '../../../../core/error/exceptions.dart';
import '../../domain/entities/organization.dart';

/// Organizacion devuelta por `POST /organizations`.
class OrganizationModel {
  const OrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', 'organizationId', '_id']);
    if (id == null) {
      throw const DataParsingException(
        'La organizacion creada no incluye un id valido.',
      );
    }

    return OrganizationModel(
      id: id,
      name: _readString(json, const ['name', 'organizationName']) ?? '',
      slug: _readString(json, const ['slug', 'organizationSlug']) ?? '',
    );
  }

  Organization toEntity() {
    return Organization(id: id, name: name, slug: slug);
  }
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
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
