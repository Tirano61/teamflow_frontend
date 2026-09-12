import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../core/organization/organization_context.dart';
import '../../domain/entities/membership_role.dart';
import '../models/membership_model.dart';

abstract class MembershipRemoteDataSource {
  Future<List<MembershipModel>> getOrganizationMembers();

  Future<MembershipModel> changeMemberRole({
    required String membershipId,
    required MembershipRole role,
  });
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

  /// `PATCH /organizations/{organizationId}/members/{membershipId}/role`.
  ///
  /// Devuelve la membresia ya actualizada, con la misma forma que las filas
  /// del listado, asi que quien llama puede reemplazar la fila sin recargar.
  ///
  /// El 409 se propaga como [HttpStatusException] a proposito: el bloc lo
  /// distingue del resto de los errores para refrescar el listado, que quedo
  /// viejo si el miembro cambio por otro lado.
  @override
  Future<MembershipModel> changeMemberRole({
    required String membershipId,
    required MembershipRole role,
  }) async {
    final normalizedId = membershipId.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException(
        'El miembro no tiene un id valido. Vuelve a cargar el listado.',
      );
    }

    try {
      final response = await _restClient.patch<Object?>(
        ApiEndpoints.organizationMemberRole(_organizationId, normalizedId),
        body: <String, dynamic>{'role': role.apiValue},
      );

      return MembershipModel.fromJson(_extractMap(response.data));
    } on PermissionDeniedException {
      // El 403 de este endpoint siempre son las reglas de rol: el mensaje
      // generico de permisos del cliente HTTP habla de otro caso.
      throw const PermissionDeniedException(
        'No tienes permisos para cambiar el rol de este miembro. El OWNER no '
        'se puede modificar y un ADMIN solo puede asignar DEVELOPER o '
        'MEMBER.',
      );
    } on HttpStatusException catch (error) {
      throw _translateChangeRoleFailure(error);
    }
  }

  /// Traduce los estados que devuelve `changeMemberRole` en el backend.
  ///
  /// El 403 no llega aca: el cliente HTTP lo convierte antes en
  /// [PermissionDeniedException]. El 409 conserva su `statusCode` porque es el
  /// unico error que el bloc necesita reconocer. Cualquier estado no
  /// contemplado se propaga tal cual para no inventar reglas.
  DataException _translateChangeRoleFailure(HttpStatusException error) {
    if (error.statusCode == 400) {
      return const ValidationException(
        'El rol seleccionado no es valido para esta organizacion.',
      );
    }

    if (error.statusCode == 404) {
      return const ValidationException(
        'Ese miembro ya no existe en esta organizacion.',
      );
    }

    if (error.statusCode == 409) {
      return const HttpStatusException(
        statusCode: 409,
        message:
            'El miembro cambio mientras tanto: su rol ya no es el que se '
            'mostraba o dejo de estar activo.',
      );
    }

    return error;
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
