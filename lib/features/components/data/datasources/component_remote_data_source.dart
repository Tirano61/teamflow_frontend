import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../../work_modules/data/models/work_module_model.dart';
import '../models/component_model.dart';

abstract class ComponentRemoteDataSource {
  Future<List<ComponentModel>> getIndicators({bool includeInactive = false});

  Future<ComponentModel> getIndicatorById(String id);

  Future<ComponentModel> createIndicator(ComponentModel model);

  Future<ComponentModel> updateIndicator(ComponentModel model);

  Future<ComponentModel> setIndicatorActive({
    required String id,
    required bool active,
  });

  Future<List<WorkModuleModel>> getApplicationsByIndicatorId(String componentId);
}

class ComponentRemoteDataSourceImpl implements ComponentRemoteDataSource {
  ComponentRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<List<ComponentModel>> getIndicators({
    bool includeInactive = false,
  }) async {
    final response = await _restClient.get<Object?>(
      includeInactive ? ApiEndpoints.indicatorsAll() : ApiEndpoints.indicators,
    );
    final list = _extractList(response.data, key: 'components');

    return list
        .map((item) => ComponentModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<ComponentModel> getIndicatorById(String id) async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.indicatorById(Uri.encodeComponent(id)),
    );
    final map = _extractEntityMap(response.data, key: 'indicator');
    return ComponentModel.fromJson(map);
  }

  @override
  Future<ComponentModel> createIndicator(ComponentModel model) async {
    final response = await _restClient.post<Object?>(
      ApiEndpoints.indicators,
      body: model.toJson(),
    );
    final map = _extractEntityMap(response.data, key: 'indicator');
    return ComponentModel.fromJson(map);
  }

  @override
  Future<ComponentModel> updateIndicator(ComponentModel model) async {
    final id = model.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'Se requiere un id para actualizar un Component.',
      );
    }

    final payload = model.toJson()..remove('id');

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.indicatorById(Uri.encodeComponent(id)),
      body: payload,
    );
    final map = _extractEntityMap(response.data, key: 'indicator');
    return ComponentModel.fromJson(map);
  }

  @override
  Future<ComponentModel> setIndicatorActive({
    required String id,
    required bool active,
  }) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de Component.');
    }

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.indicatorActiveById(Uri.encodeComponent(normalizedId)),
      body: <String, dynamic>{'active': active},
    );
    final map = _extractEntityMap(response.data, key: 'indicator');
    return ComponentModel.fromJson(map);
  }

  @override
  Future<List<WorkModuleModel>> getApplicationsByIndicatorId(
    String componentId,
  ) async {
    final normalizedId = componentId.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de Component.');
    }

    final response = await _restClient.get<Object?>(
      ApiEndpoints.indicatorApplicationsById(Uri.encodeComponent(normalizedId)),
    );

    final list = _extractList(response.data, key: 'applications');
    return list
        .map((item) => WorkModuleModel.fromJson(_extractMap(item)))
        .toList(growable: false);
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
      'Formato inesperado al obtener listado de Components.',
    );
  }

  Map<String, dynamic> _extractEntityMap(
    Object? payload, {
    required String key,
  }) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }

      final entity = payload[key];
      if (entity is Map<String, dynamic>) {
        return entity;
      }

      return payload;
    }

    throw const DataParsingException(
      'Formato inesperado al obtener un Component.',
    );
  }

  Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw const DataParsingException(
      'Formato inesperado de item en listado de Components.',
    );
  }
}



