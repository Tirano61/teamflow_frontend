import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../models/user_search_result_model.dart';

abstract class UserRemoteDataSource {
  Future<List<UserSearchResultModel>> searchUsers({
    required String query,
    required int limit,
  });
}

/// `GET /users/search?q={query}&limit={limit}`.
///
/// Endpoint autenticado y global: busca entre todos los usuarios registrados
/// de TeamFlow, no entre los miembros de una organizacion, por lo que no
/// depende de `OrganizationContext`.
///
/// El backend ya aplica las reglas de la busqueda (minimo 2 caracteres,
/// coincidencia parcial por `email` y `fullName`, excluye al usuario
/// autenticado y a los inactivos): aca solo se corta la request corta para no
/// gastar un viaje que el backend rechazaria igual.
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  UserRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  /// Minimo que exige `GET /users/search` en el backend.
  static const int minQueryLength = 2;

  @override
  Future<List<UserSearchResultModel>> searchUsers({
    required String query,
    required int limit,
  }) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.length < minQueryLength) {
      throw const ValidationException(
        'Escribe al menos $minQueryLength caracteres para buscar un usuario.',
      );
    }

    final response = await _restClient.get<Object?>(
      ApiEndpoints.userSearch,
      queryParameters: <String, dynamic>{'q': normalizedQuery, 'limit': limit},
    );

    return _extractList(response.data)
        .map((item) => UserSearchResultModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  List<dynamic> _extractList(Object? payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'users', 'results']) {
        final value = payload[key];
        if (value is List) {
          return value;
        }
      }
    }

    throw const DataParsingException('Formato inesperado al buscar usuarios.');
  }

  Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw const DataParsingException(
      'Formato inesperado de un usuario en la busqueda.',
    );
  }
}
