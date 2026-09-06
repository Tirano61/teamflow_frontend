import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../core/organization/organization_context.dart';
import '../models/membership_model.dart';

abstract class MembershipRemoteDataSource {
  Future<List<MembershipModel>> getOrganizationMembers();
}

class MembershipRemoteDataSourceImpl implements MembershipRemoteDataSource {
  MembershipRemoteDataSourceImpl({
    required RestClient restClient,
    required OrganizationContext organizationContext,
  }) : _restClient = restClient,
       _organizationContext = organizationContext;

  final RestClient _restClient;
  final OrganizationContext _organizationContext;

  /// Organizacion activa. Se resuelve en cada request, nunca se cachea en el
  /// constructor: el datasource es singleton y la organizacion activa cambia.
  ///
  /// Lanza [OrganizationNotSelectedException] si no hay ninguna seleccionada.
  String get _organizationId => _organizationContext.organizationId;

  @override
  Future<List<MembershipModel>> getOrganizationMembers() async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.organizationMembers(_organizationId),
    );

    return _extractList(response.data)
        .map((item) => MembershipModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  List<dynamic> _extractList(Object? payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'members']) {
        final value = payload[key];
        if (value is List) {
          return value;
        }
      }
    }

    throw const DataParsingException(
      'Formato inesperado al obtener los miembros de la organizacion.',
    );
  }

  Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw const DataParsingException(
      'Formato inesperado de un miembro de la organizacion.',
    );
  }
}
