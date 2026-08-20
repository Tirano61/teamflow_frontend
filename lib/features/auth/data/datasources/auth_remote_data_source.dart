import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../models/auth_session_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _restClient.post<Object?>(
      ApiEndpoints.authLogin,
      body: <String, dynamic>{'email': email.trim(), 'password': password},
    );

    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw const DataParsingException(
        'Formato de login invalido: se esperaba un objeto JSON.',
      );
    }

    return AuthSessionModel.fromApiJson(payload);
  }
}
