import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../models/organization_model.dart';

abstract class OrganizationRemoteDataSource {
  Future<OrganizationModel> createOrganization({required String name});
}

/// `POST /organizations`.
///
/// Endpoint autenticado y global: crea la organizacion y deja al usuario
/// autenticado como `OWNER`, por lo que no depende de `OrganizationContext`.
class OrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  OrganizationRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  /// Limites de `CreateOrganizationDto` en el backend.
  static const int _minNameLength = 2;
  static const int _maxNameLength = 120;

  @override
  Future<OrganizationModel> createOrganization({required String name}) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw const ValidationException(
        'El nombre de la organizacion es obligatorio.',
      );
    }

    if (normalizedName.length < _minNameLength ||
        normalizedName.length > _maxNameLength) {
      throw const ValidationException(
        'El nombre de la organizacion debe tener entre '
        '$_minNameLength y $_maxNameLength caracteres.',
      );
    }

    try {
      final response = await _restClient.post<Object?>(
        ApiEndpoints.organizations,
        body: <String, dynamic>{'name': normalizedName},
      );

      return OrganizationModel.fromJson(_extractOrganizationMap(response.data));
    } on HttpStatusException catch (error) {
      // El backend solo valida `name` en este endpoint: un 400 siempre habla
      // del nombre enviado.
      if (error.statusCode == 400) {
        throw ValidationException(
          'El nombre de la organizacion no es valido: ${error.message}',
        );
      }

      rethrow;
    }
  }

  Map<String, dynamic> _extractOrganizationMap(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }

      final organization = payload['organization'];
      if (organization is Map<String, dynamic>) {
        return organization;
      }

      return payload;
    }

    throw const DataParsingException(
      'Formato inesperado al crear la organizacion.',
    );
  }
}
