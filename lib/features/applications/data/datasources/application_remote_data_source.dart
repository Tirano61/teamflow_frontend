import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../../indicators/data/models/indicator_model.dart';
import '../models/application_model.dart';

abstract class ApplicationRemoteDataSource {
  Future<List<ApplicationModel>> getApplications({bool includeInactive = false});

  Future<ApplicationModel> getApplicationById(String id);

  Future<ApplicationModel> createApplication(ApplicationModel model);

  Future<ApplicationModel> updateApplication(ApplicationModel model);

  Future<ApplicationModel> setApplicationActive({
    required String id,
    required bool active,
  });

  Future<List<IndicatorModel>> getIndicatorsByApplicationId(String applicationId);

  Future<void> addIndicatorToApplication({
    required String applicationId,
    required String indicatorId,
  });

  Future<void> removeIndicatorFromApplication({
    required String applicationId,
    required String indicatorId,
  });
}

class ApplicationRemoteDataSourceImpl implements ApplicationRemoteDataSource {
  ApplicationRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<List<ApplicationModel>> getApplications({
    bool includeInactive = false,
  }) async {
    final response = await _restClient.get<Object?>(
      includeInactive ? ApiEndpoints.applicationsAll() : ApiEndpoints.applications,
    );
    final list = _extractList(response.data, key: 'applications');

    return list
        .map((item) => ApplicationModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<ApplicationModel> getApplicationById(String id) async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.applicationById(Uri.encodeComponent(id)),
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return ApplicationModel.fromJson(map);
  }

  @override
  Future<ApplicationModel> createApplication(ApplicationModel model) async {
    final response = await _restClient.post<Object?>(
      ApiEndpoints.applications,
      body: model.toJson(),
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return ApplicationModel.fromJson(map);
  }

  @override
  Future<ApplicationModel> updateApplication(ApplicationModel model) async {
    final id = model.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'Se requiere un id para actualizar una Application.',
      );
    }

    final payload = model.toJson()..remove('id');

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.applicationById(Uri.encodeComponent(id)),
      body: payload,
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return ApplicationModel.fromJson(map);
  }

  @override
  Future<ApplicationModel> setApplicationActive({
    required String id,
    required bool active,
  }) async {
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de Application.');
    }

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.applicationActiveById(Uri.encodeComponent(normalizedId)),
      body: <String, dynamic>{'active': active},
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return ApplicationModel.fromJson(map);
  }

  @override
  Future<List<IndicatorModel>> getIndicatorsByApplicationId(
    String applicationId,
  ) async {
    final normalizedId = applicationId.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException('Se requiere un id de Application.');
    }

    final response = await _restClient.get<Object?>(
      ApiEndpoints.applicationIndicatorsById(Uri.encodeComponent(normalizedId)),
    );

    final list = _extractList(response.data, key: 'indicators');
    return list
        .map((item) => IndicatorModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<void> addIndicatorToApplication({
    required String applicationId,
    required String indicatorId,
  }) async {
    final normalizedApplicationId = applicationId.trim();
    final normalizedIndicatorId = indicatorId.trim();
    if (normalizedApplicationId.isEmpty || normalizedIndicatorId.isEmpty) {
      throw const ValidationException(
        'Se requieren applicationId e indicatorId para asociar.',
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
    required String applicationId,
    required String indicatorId,
  }) async {
    final normalizedApplicationId = applicationId.trim();
    final normalizedIndicatorId = indicatorId.trim();
    if (normalizedApplicationId.isEmpty || normalizedIndicatorId.isEmpty) {
      throw const ValidationException(
        'Se requieren applicationId e indicatorId para desasociar.',
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
      'Formato inesperado al obtener listado de Applications.',
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
      'Formato inesperado al obtener una Application.',
    );
  }

  Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw const DataParsingException(
      'Formato inesperado de item en listado de Applications.',
    );
  }
}
