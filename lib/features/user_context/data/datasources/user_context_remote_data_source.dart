import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../models/user_context_model.dart';

abstract class UserContextRemoteDataSource {
  Future<UserContextModel> getUserContext();
}

/// `GET /me/context`.
///
/// Endpoint autenticado y global: no lleva `organizationId`, por lo que este
/// datasource no depende de `OrganizationContext`.
class UserContextRemoteDataSourceImpl implements UserContextRemoteDataSource {
  UserContextRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<UserContextModel> getUserContext() async {
    final response = await _restClient.get<Object?>(ApiEndpoints.meContext);
    final payload = response.data;

    if (payload is! Map<String, dynamic>) {
      throw const DataParsingException(
        'Formato inesperado al obtener el contexto del usuario.',
      );
    }

    return UserContextModel.fromJson(payload);
  }
}
