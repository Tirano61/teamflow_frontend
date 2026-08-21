import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../../components/data/models/component_model.dart';
import '../models/work_module_model.dart';

abstract class WorkModuleRemoteDataSource {
  Future<List<WorkModuleModel>> getApplications({bool includeInactive = false});

  Future<WorkModuleModel> getApplicationById(String id);

  Future<WorkModuleModel> createApplication(WorkModuleModel model);

  Future<WorkModuleModel> updateApplication(WorkModuleModel model);

  Future<WorkModuleModel> setApplicationActive({
    required String id,
    required bool active,
  });

  Future<List<ComponentModel>> getIndicatorsByApplicationId(String workModuleId);

  Future<void> addIndicatorToApplication({
    required String workModuleId,
    required String componentId,
  });

  Future<void> removeIndicatorFromApplication({
    required String workModuleId,
    required String componentId,
  });
}

class WorkModuleRemoteDataSourceImpl implements WorkModuleRemoteDataSource {
  WorkModuleRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<List<WorkModuleModel>> getApplications({
    bool includeInactive = false,
  }) async {
    final response = await _restClient.get<Object?>(
      includeInactive ? ApiEndpoints.applicationsAll() : ApiEndpoints.applications,
    );
    final list = _extractList(response.data, key: 'applications');

    return list
        .map((item) => WorkModuleModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<WorkModuleModel> getApplicationById(String id) async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.applicationById(Uri.encodeComponent(id)),
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return WorkModuleModel.fromJson(map);
  }

  @override
  Future<WorkModuleModel> createApplication(WorkModuleModel model) async {
    final response = await _restClient.post<Object?>(
      ApiEndpoints.applications,
      body: model.toJson(),
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return WorkModuleModel.fromJson(map);
  }

  @override
  Future<WorkModuleModel> updateApplication(WorkModuleModel model) async {
    final id = model.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'Se requiere un id para actualizar una WorkModule.',
      );
    }

    final payload = model.toJson()..remove('id');

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.applicationById(Uri.encodeComponent(id)),
      body: payload,
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return WorkModuleModel.fromJson(map);
  }

  @override
  Future<WorkModuleModel> setApplicationActive({
    required String id,
    required bool active,
  }) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de WorkModule.');
    }

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.applicationActiveById(Uri.encodeComponent(normalizedId)),
      body: <String, dynamic>{'active': active},
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return WorkModuleModel.fromJson(map);
  }

  @override
  Future<List<ComponentModel>> getIndicatorsByApplicationId(
    String workModuleId,
  ) async {
    final normalizedId = workModuleId.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de WorkModule.');
    }

    final response = await _restClient.get<Object?>(
      ApiEndpoints.applicationIndicatorsById(Uri.encodeComponent(normalizedId)),
    );

    final list = _extractList(response.data, key: 'components');
    return list
        .map((item) => ComponentModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<void> addIndicatorToApplication({
    required String workModuleId,
    required String componentId,
  }) async {
    final normalizedApplicationId = workModuleId.trim();
    final normalizedIndicatorId = componentId.trim();
    if (normalizedApplicationId.isEmpty || normalizedIndicatorId.isEmpty) {
      throw const ValidationException(
        'Se requieren workModuleId e componentId para asociar.',
      );
    }

    await _restClient.post<Object?>(
      ApiEndpoints.applicationIndicatorByIds(
        Uri.encodeComponent(normalizedApplicationId),
        Uri.encodeComponent(normalizedIndicatorId),
      ),
      body: const <String, dynamic>{},
    );
  }

  @override
  Future<void> removeIndicatorFromApplication({
    required String workModuleId,
    required String componentId,
  }) async {
    final normalizedApplicationId = workModuleId.trim();
    final normalizedIndicatorId = componentId.trim();
    if (normalizedApplicationId.isEmpty || normalizedIndicatorId.isEmpty) {
      throw const ValidationException(
        'Se requieren workModuleId e componentId para desasociar.',
      );
    }

    await _restClient.delete<Object?>(
      ApiEndpoints.applicationIndicatorByIds(
        Uri.encodeComponent(normalizedApplicationId),
        Uri.encodeComponent(normalizedIndicatorId),
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



