import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../models/tag_model.dart';

abstract class TagRemoteDataSource {
  Future<List<TagModel>> getTags({bool includeInactive = false});

  Future<TagModel> createTag(TagModel tag);

  Future<TagModel> updateTag(TagModel tag);

  Future<TagModel> setTagActive({required String id, required bool active});
}

class TagRemoteDataSourceImpl implements TagRemoteDataSource {
  TagRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<List<TagModel>> getTags({bool includeInactive = false}) async {
    final response = await _restClient.get<Object?>(
      includeInactive ? ApiEndpoints.tagsAll() : ApiEndpoints.tags,
    );
    final list = _extractList(response.data, key: 'tags');

    return list
        .map((item) => TagModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<TagModel> createTag(TagModel tag) async {
    final normalizedName = tag.name.trim();
    if (normalizedName.isEmpty) {
      throw const ValidationException(
        'El nombre del Tag es obligatorio para crear.',
      );
    }

    final payloadCandidates = _buildCreatePayloadCandidates(
      name: normalizedName,
      active: tag.active,
    );

    HttpStatusException? firstBadRequest;

    for (final payload in payloadCandidates) {
      try {
        final response = await _restClient.post<Object?>(
          ApiEndpoints.tags,
          body: payload,
        );

        final map = _extractCreatedTagMap(response.data);
        return TagModel.fromJson(map);
      } on HttpStatusException catch (error) {
        if (error.statusCode != 400) {
          rethrow;
        }

        firstBadRequest ??= error;

        if (!_canRetryWithAlternativePayload(error.message)) {
          rethrow;
        }
      }
    }

    if (firstBadRequest != null) {
      throw firstBadRequest;
    }

    throw const DataParsingException(
      'No se pudo crear el Tag por un formato de request inesperado.',
    );
  }

  @override
  Future<TagModel> updateTag(TagModel tag) async {
    final id = tag.id?.trim() ?? '';
    final name = tag.name.trim();

    if (id.isEmpty) {
      throw const ValidationException('Se requiere un id para actualizar Tag.');
    }

    if (name.isEmpty) {
      throw const ValidationException('El nombre del Tag es obligatorio.');
    }

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.tagById(Uri.encodeComponent(id)),
      body: <String, dynamic>{'name': name},
    );

    final map = _extractCreatedTagMap(response.data);
    return TagModel.fromJson(map);
  }

  @override
  Future<TagModel> setTagActive({required String id, required bool active}) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de Tag.');
    }

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.tagActiveById(Uri.encodeComponent(normalizedId)),
      body: <String, dynamic>{'active': active},
    );

    final map = _extractCreatedTagMap(response.data);
    return TagModel.fromJson(map);
  }

  List<dynamic> _extractList(Object? payload, {required String key}) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) {
        return data;
      }

      final items = payload['items'];
      if (items is List) {
        return items;
      }

      final collection = payload[key];
      if (collection is List) {
        return collection;
      }
    }

    throw const DataParsingException(
      'Formato inesperado al obtener listado de Tags.',
    );
  }

  Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw const DataParsingException(
      'Formato inesperado de item en listado de Tags.',
    );
  }

  Map<String, dynamic> _extractCreatedTagMap(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }

      final item = payload['item'];
      if (item is Map<String, dynamic>) {
        return item;
      }

      final tag = payload['tag'];
      if (tag is Map<String, dynamic>) {
        return tag;
      }

      return payload;
    }

    throw const DataParsingException('Formato inesperado al crear Tag.');
  }

  List<Map<String, dynamic>> _buildCreatePayloadCandidates({
    required String name,
    required bool active,
  }) {
    final candidates = <Map<String, dynamic>>[
      <String, dynamic>{'name': name},
      <String, dynamic>{'tagName': name},
      <String, dynamic>{'title': name},
    ];

    if (!active) {
      candidates.add(<String, dynamic>{'name': name, 'active': false});
    }

    return candidates;
  }

  bool _canRetryWithAlternativePayload(String message) {
    final normalized = message.toLowerCase();

    final disallowRetryMarkers = <String>[
      'already',
      'exists',
      'duplicate',
      'duplicado',
      'ya existe',
      'conflict',
      'conflicto',
      'unique',
      'unico',
      'único',
    ];

    if (disallowRetryMarkers.any(normalized.contains)) {
      return false;
    }

    final retryMarkers = <String>[
      'property',
      'required',
      'validation',
      'must be',
      'should',
      'should not exist',
      'unknown',
      'formato',
      'campo',
      'atributo',
      'invalido',
      'inválido',
    ];

    return retryMarkers.any(normalized.contains);
  }
}
