import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../core/organization/organization_context.dart';
import '../../../components/data/models/component_model.dart';
import '../models/work_module_model.dart';

abstract class WorkModuleRemoteDataSource {
  Future<List<WorkModuleModel>> getModules({bool includeInactive = false});

  Future<WorkModuleModel> getModuleById(String id);

  Future<WorkModuleModel> createModule(WorkModuleModel model);

  Future<WorkModuleModel> updateModule(WorkModuleModel model);

  Future<WorkModuleModel> setModuleActive({
    required String id,
    required bool active,
  });

  Future<List<ComponentModel>> getComponentsByModuleId(String workModuleId);

  Future<void> addComponentToModule({
    required String workModuleId,
    required String componentId,
  });

  Future<void> removeComponentFromModule({
    required String workModuleId,
    required String componentId,
  });
}

class WorkModuleRemoteDataSourceImpl implements WorkModuleRemoteDataSource {
  WorkModuleRemoteDataSourceImpl({
    required RestClient restClient,
    required OrganizationContext organizationContext,
  }) : _restClient = restClient,
       _organizationContext = organizationContext;

  final RestClient _restClient;
  final OrganizationContext _organizationContext;

  /// Organizacion activa. Lanza [OrganizationNotSelectedException] si no hay.
  String get _organizationId => _organizationContext.organizationId;

  @override
  Future<List<WorkModuleModel>> getModules({bool includeInactive = false}) async {
    final organizationId = _organizationId;

    final response = await _restClient.get<Object?>(
      includeInactive
          ? ApiEndpoints.modulesAll(organizationId)
          : ApiEndpoints.modules(organizationId),
    );
    final list = _extractList(response.data, key: 'modules');

    return list
        .map((item) => WorkModuleModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<WorkModuleModel> getModuleById(String id) async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.moduleById(_organizationId, Uri.encodeComponent(id)),
    );
    final map = _extractEntityMap(response.data, key: 'module');
    return WorkModuleModel.fromJson(map);
  }

  @override
  Future<WorkModuleModel> createModule(WorkModuleModel model) async {
    final response = await _restClient.post<Object?>(
      ApiEndpoints.modules(_organizationId),
      body: model.toJson(),
    );
    final map = _extractEntityMap(response.data, key: 'module');
    return WorkModuleModel.fromJson(map);
  }

  @override
  Future<WorkModuleModel> updateModule(WorkModuleModel model) async {
    final id = model.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'Se requiere un id para actualizar una WorkModule.',
      );
    }

    final payload = model.toJson()..remove('id');

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.moduleById(_organizationId, Uri.encodeComponent(id)),
      body: payload,
    );
    final map = _extractEntityMap(response.data, key: 'module');
    return WorkModuleModel.fromJson(map);
  }

  @override
  Future<WorkModuleModel> setModuleActive({
    required String id,
    required bool active,
  }) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de WorkModule.');
    }

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.moduleActiveById(
        _organizationId,
        Uri.encodeComponent(normalizedId),
      ),
      body: <String, dynamic>{'active': active},
    );
    final map = _extractEntityMap(response.data, key: 'module');
    return WorkModuleModel.fromJson(map);
  }

  @override
  Future<List<ComponentModel>> getComponentsByModuleId(
    String workModuleId,
  ) async {
    final normalizedId = workModuleId.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de WorkModule.');
    }

    final response = await _restClient.get<Object?>(
      ApiEndpoints.moduleComponents(
        _organizationId,
        Uri.encodeComponent(normalizedId),
      ),
    );

    final list = _extractList(response.data, key: 'components');
    return list
        .map((item) => ComponentModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<void> addComponentToModule({
    required String workModuleId,
    required String componentId,
  }) async {
    final normalizedModuleId = workModuleId.trim();
    final normalizedComponentId = componentId.trim();
    if (normalizedModuleId.isEmpty || normalizedComponentId.isEmpty) {
      throw const ValidationException(
        'Se requieren workModuleId e componentId para asociar.',
      );
    }

    await _restClient.post<Object?>(
      ApiEndpoints.moduleComponentByIds(
        _organizationId,
        Uri.encodeComponent(normalizedModuleId),
        Uri.encodeComponent(normalizedComponentId),
      ),
      body: const <String, dynamic>{},
    );
  }

  @override
  Future<void> removeComponentFromModule({
    required String workModuleId,
    required String componentId,
  }) async {
    final normalizedModuleId = workModuleId.trim();
    final normalizedComponentId = componentId.trim();
    if (normalizedModuleId.isEmpty || normalizedComponentId.isEmpty) {
      throw const ValidationException(
        'Se requieren workModuleId e componentId para desasociar.',
      );
    }

    await _restClient.delete<Object?>(
      ApiEndpoints.moduleComponentByIds(
        _organizationId,
        Uri.encodeComponent(normalizedModuleId),
        Uri.encodeComponent(normalizedComponentId),
      ),
    );
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
      'Formato inesperado al obtener listado de WorkModules.',
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
      'Formato inesperado al obtener una WorkModule.',
    );
  }

  Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw const DataParsingException(
      'Formato inesperado de item en listado de WorkModules.',
    );
  }
}
