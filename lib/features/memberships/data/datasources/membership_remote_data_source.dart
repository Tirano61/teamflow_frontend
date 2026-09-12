import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../core/organization/organization_context.dart';
import '../../domain/entities/membership_role.dart';
import '../models/membership_model.dart';

abstract class MembershipRemoteDataSource {
  /// Directorio: solo memberships `ACTIVE`.
  Future<List<MembershipModel>> getOrganizationMembers();

  /// Administracion: memberships `ACTIVE` y `SUSPENDED`.
  Future<List<MembershipModel>> getOrganizationMembersForManagement();

  Future<MembershipModel> changeMemberRole({
    required String membershipId,
    required MembershipRole role,
  });

  Future<MembershipModel> suspendMember({required String membershipId});

  Future<MembershipModel> reactivateMember({required String membershipId});
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

  /// `GET /organizations/{organizationId}/members`.
  ///
  /// Directorio general: el backend devuelve solamente memberships `ACTIVE`,
  /// de cualquier rol, y el resultado es identico para todos los roles.
  @override
  Future<List<MembershipModel>> getOrganizationMembers() async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.organizationMembers(_organizationId),
    );

    return _parseList(response.data);
  }

  /// `GET /organizations/{organizationId}/members/manage`.
  ///
  /// Listado administrativo: mismo contrato que el directorio, pero incluye
  /// los memberships `SUSPENDED`. Solo OWNER/ADMIN pueden usarlo; el resto
  /// recibe 403.
  @override
  Future<List<MembershipModel>> getOrganizationMembersForManagement() async {
    try {
      final response = await _restClient.get<Object?>(
        ApiEndpoints.organizationMembersManage(_organizationId),
      );

      return _parseList(response.data);
    } on PermissionDeniedException {
      // El 403 de este endpoint es siempre el rol del requester: el mensaje
      // generico de permisos del cliente HTTP habla de otro caso.
      throw const PermissionDeniedException(
        'No tienes permisos para administrar los miembros de esta '
        'organizacion. Solo OWNER y ADMIN pueden hacerlo.',
      );
    }
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
    final normalizedId = _requireMembershipId(membershipId);

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

  /// `POST /organizations/{organizationId}/members/{membershipId}/suspend`.
  ///
  /// Cambia solo el `status` (`ACTIVE` -> `SUSPENDED`) y devuelve la membresia
  /// actualizada, con el mismo contrato que el listado.
  @override
  Future<MembershipModel> suspendMember({required String membershipId}) {
    return _changeMemberStatus(
      membershipId: membershipId,
      buildPath: ApiEndpoints.organizationMemberSuspend,
      conflictMessage:
          'Ese miembro ya estaba suspendido: su estado cambio mientras tanto.',
    );
  }

  /// `POST /organizations/{organizationId}/members/{membershipId}/reactivate`.
  ///
  /// Cambia solo el `status` (`SUSPENDED` -> `ACTIVE`) conservando el rol que
  /// el miembro tenia antes de la suspension.
  @override
  Future<MembershipModel> reactivateMember({required String membershipId}) {
    return _changeMemberStatus(
      membershipId: membershipId,
      buildPath: ApiEndpoints.organizationMemberReactivate,
      conflictMessage:
          'Ese miembro ya estaba activo: su estado cambio mientras tanto.',
    );
  }

  /// Suspender y reactivar comparten metodo, contrato de respuesta y codigos
  /// de error; solo cambian la ruta y el texto del 409.
  Future<MembershipModel> _changeMemberStatus({
    required String membershipId,
    required String Function(String organizationId, String membershipId)
    buildPath,
    required String conflictMessage,
  }) async {
    final normalizedId = _requireMembershipId(membershipId);

    try {
      final response = await _restClient.post<Object?>(
        buildPath(_organizationId, normalizedId),
      );

      return MembershipModel.fromJson(_extractMap(response.data));
    } on PermissionDeniedException {
      // El 403 de estos endpoints son las reglas de alcance, el OWNER
      // protegido o la auto-modificacion.
      throw const PermissionDeniedException(
        'No tienes permisos para cambiar el estado de este miembro. El OWNER '
        'no se puede suspender, un ADMIN solo alcanza a DEVELOPER y MEMBER, y '
        'nadie puede suspenderse a si mismo.',
      );
    } on HttpStatusException catch (error) {
      throw _translateChangeStatusFailure(error, conflictMessage);
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

  /// Traduce los estados de `suspend` y `reactivate`.
  ///
  /// Mismo criterio que el cambio de rol: el 403 ya viene convertido y el 409
  /// conserva su `statusCode` para que el bloc lo reconozca y refresque el
  /// listado administrativo.
  DataException _translateChangeStatusFailure(
    HttpStatusException error,
    String conflictMessage,
  ) {
    if (error.statusCode == 400) {
      return const ValidationException(
        'El miembro no tiene un id valido. Vuelve a cargar el listado.',
      );
    }

    if (error.statusCode == 404) {
      return const ValidationException(
        'Ese miembro ya no existe en esta organizacion.',
      );
    }

    if (error.statusCode == 409) {
      return HttpStatusException(statusCode: 409, message: conflictMessage);
    }

    return error;
  }

  String _requireMembershipId(String membershipId) {
    final normalizedId = membershipId.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException(
        'El miembro no tiene un id valido. Vuelve a cargar el listado.',
      );
    }

    return normalizedId;
  }

  List<MembershipModel> _parseList(Object? payload) {
    return _extractList(payload)
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
