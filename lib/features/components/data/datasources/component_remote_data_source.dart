import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../core/organization/organization_context.dart';
import '../../../work_modules/data/models/work_module_model.dart';
import '../models/component_model.dart';

abstract class ComponentRemoteDataSource {
  Future<List<ComponentModel>> getComponents({bool includeInactive = false});

  Future<ComponentModel> getComponentById(String id);

  Future<ComponentModel> createComponent(ComponentModel model);

  Future<ComponentModel> updateComponent(ComponentModel model);

  Future<ComponentModel> setComponentActive({
    required String id,
    required bool active,
  });

  Future<List<WorkModuleModel>> getModulesByComponentId(String componentId);
}

class ComponentRemoteDataSourceImpl implements ComponentRemoteDataSource {
  ComponentRemoteDataSourceImpl({
    required RestClient restClient,
    required OrganizationContext organizationContext,
  }) : _restClient = restClient,
       _organizationContext = organizationContext;

  final RestClient _restClient;
  final OrganizationContext _organizationContext;

  /// Organizacion activa. Lanza [OrganizationNotSelectedException] si no hay.
  String get _organizationId => _organizationContext.organizationId;

  @override
  Future<List<ComponentModel>> getComponents({
    bool includeInactive = false,
  }) async {
    final organizationId = _organizationId;

    final response = await _restClient.get<Object?>(
      includeInactive
          ? ApiEndpoints.componentsAll(organizationId)
          : ApiEndpoints.components(organizationId),
    );
    final list = _extractList(response.data, key: 'components');

    return list
        .map((item) => ComponentModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<ComponentModel> getComponentById(String id) async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.componentById(_organizationId, Uri.encodeComponent(id)),
    );
    final map = _extractEntityMap(response.data, key: 'component');
    return ComponentModel.fromJson(map);
  }

  @override
  Future<ComponentModel> createComponent(ComponentModel model) async {
    final response = await _restClient.post<Object?>(
      ApiEndpoints.components(_organizationId),
      body: model.toJson(),
    );
    final map = _extractEntityMap(response.data, key: 'component');
    return ComponentModel.fromJson(map);
  }

  @override
  Future<ComponentModel> updateComponent(ComponentModel model) async {
    final id = model.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'Se requiere un id para actualizar un Component.',
      );
    }

    final payload = model.toJson()..remove('id');

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.componentById(_organizationId, Uri.encodeComponent(id)),
      body: payload,
    );
    final map = _extractEntityMap(response.data, key: 'component');
    return ComponentModel.fromJson(map);
  }

  @override
  Future<ComponentModel> setComponentActive({
    required String id,
    required bool active,
  }) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de Component.');
    }

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.componentActiveById(
        _organizationId,
        Uri.encodeComponent(normalizedId),
      ),
      body: <String, dynamic>{'active': active},
    );
    final map = _extractEntityMap(response.data, key: 'component');
    return ComponentModel.fromJson(map);
  }

  @override
  Future<List<WorkModuleModel>> getModulesByComponentId(
    String componentId,
  ) async {
    final normalizedId = componentId.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de Component.');
    }

    final response = await _restClient.get<Object?>(
      ApiEndpoints.componentModules(
        _organizationId,
        Uri.encodeComponent(normalizedId),
      ),
    );

    final list = _extractList(response.data, key: 'modules');
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
