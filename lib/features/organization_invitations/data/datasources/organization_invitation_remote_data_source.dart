import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../core/organization/organization_context.dart';
import '../../domain/entities/organization_invitation_role.dart';
import '../models/organization_invitation_model.dart';

abstract class OrganizationInvitationRemoteDataSource {
  Future<void> acceptInvitation({required String token});

  Future<void> createInvitation({
    required String userId,
    required OrganizationInvitationRole role,
  });

  Future<List<OrganizationInvitationModel>> getInvitations();

  Future<void> cancelInvitation({required String invitationId});
}

/// Invitaciones de organizacion.
///
/// Convive con dos familias de endpoints:
/// - `POST /organization-invitations/{token}/accept`: global, la organizacion
///   la determina la propia invitacion.
/// - `POST /organizations/{organizationId}/invitations`: tenant, el
///   `organizationId` se resuelve contra `OrganizationContext` en cada
///   request.
///
/// Los endpoints tenant son tres: crear, listar
/// (`GET /organizations/{organizationId}/invitations`) y cancelar
/// (`POST .../invitations/{invitationId}/cancel`).
///
/// Solo se parsea la respuesta del listado: en aceptar, el estado real lo
/// confirma el refresh posterior de `/me/context`; en crear, la membresia no
/// existe hasta que el invitado acepta; en cancelar, el backend no devuelve la
/// invitacion actualizada.
class OrganizationInvitationRemoteDataSourceImpl
    implements OrganizationInvitationRemoteDataSource {
  OrganizationInvitationRemoteDataSourceImpl({
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
  Future<void> acceptInvitation({required String token}) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw const ValidationException(
        'La invitacion no incluye un token valido. Vuelve a cargar tu '
        'contexto o pide una invitacion nueva.',
      );
    }

    try {
      await _restClient.post<Object?>(
        ApiEndpoints.organizationInvitationAccept(normalizedToken),
      );
    } on PermissionDeniedException {
      // El unico 403 de este endpoint es el email que no coincide: el mensaje
      // generico de permisos del cliente HTTP no aplica aca.
      throw const PermissionDeniedException(
        'La invitacion fue enviada a otro email. Inicia sesion con la cuenta '
        'invitada para aceptarla.',
      );
    } on HttpStatusException catch (error) {
      throw _translateAcceptFailure(error);
    }
  }

  /// `POST /organizations/{organizationId}/invitations`.
  ///
  /// El destinatario es un usuario ya registrado, identificado por su
  /// `userId`: nunca se envia un email escrito a mano.
  @override
  Future<void> createInvitation({
    required String userId,
    required OrganizationInvitationRole role,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const ValidationException(
        'Selecciona un usuario de la busqueda para enviar la invitacion.',
      );
    }

    try {
      await _restClient.post<Object?>(
        ApiEndpoints.organizationInvitationsByOrganization(_organizationId),
        body: <String, dynamic>{
          'userId': normalizedUserId,
          'role': role.apiValue,
        },
      );
    } on PermissionDeniedException {
      // El 403 de este endpoint siempre es el rol del invitante: el mensaje
      // generico de permisos del cliente HTTP habla de otro caso.
      throw const PermissionDeniedException(
        'No tienes permisos para invitar miembros. Solo el OWNER o un ADMIN '
        'de la organizacion pueden hacerlo.',
      );
    } on HttpStatusException catch (error) {
      throw _translateCreateFailure(error);
    }
  }

  /// `GET /organizations/{organizationId}/invitations`.
  ///
  /// Devuelve todas las invitaciones enviadas por la organizacion activa, en
  /// cualquier estado y con las mas recientes primero: el orden lo define el
  /// backend y no se reordena aca.
  @override
  Future<List<OrganizationInvitationModel>> getInvitations() async {
    try {
      final response = await _restClient.get<Object?>(
        ApiEndpoints.organizationInvitationsByOrganization(_organizationId),
      );

      return _extractList(response.data)
          .map((item) => OrganizationInvitationModel.fromJson(_extractMap(item)))
          .toList(growable: false);
    } on PermissionDeniedException {
      // El 403 de este endpoint siempre es el rol: el mensaje generico de
      // permisos del cliente HTTP habla de otro caso.
      throw const PermissionDeniedException(
        'No tienes permisos para ver las invitaciones. Solo el OWNER o un '
        'ADMIN de la organizacion pueden consultarlas.',
      );
    }
  }

  /// `POST /organizations/{organizationId}/invitations/{invitationId}/cancel`.
  ///
  /// Sin body. El 409 se propaga como [HttpStatusException] a proposito: el
  /// bloc lo distingue del resto de los errores para refrescar el listado, que
  /// quedo viejo si la invitacion cambio de estado por otro lado.
  @override
  Future<void> cancelInvitation({required String invitationId}) async {
    final normalizedId = invitationId.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException(
        'La invitacion no tiene un id valido. Vuelve a cargar el listado.',
      );
    }

    try {
      await _restClient.post<Object?>(
        ApiEndpoints.organizationInvitationCancel(_organizationId, normalizedId),
      );
    } on PermissionDeniedException {
      throw const PermissionDeniedException(
        'No tienes permisos para cancelar invitaciones. Solo el OWNER o un '
        'ADMIN de la organizacion pueden hacerlo.',
      );
    } on HttpStatusException catch (error) {
      throw _translateCancelFailure(error);
    }
  }

  /// Traduce los estados que devuelve `cancelInvitation` en el backend.
  ///
  /// El 409 conserva su `statusCode`: es el unico error que el bloc necesita
  /// reconocer. Cualquier estado no contemplado se propaga tal cual para no
  /// inventar reglas.
  DataException _translateCancelFailure(HttpStatusException error) {
    if (error.statusCode == 404) {
      return const ValidationException(
        'La invitacion ya no existe en esta organizacion.',
      );
    }

    if (error.statusCode == 409) {
      return const HttpStatusException(
        statusCode: 409,
        message:
            'La invitacion ya no esta pendiente: fue aceptada, cancelada o '
            'vencio.',
      );
    }

    return error;
  }

  List<dynamic> _extractList(Object? payload) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in const ['data', 'items', 'invitations']) {
        final value = payload[key];
        if (value is List) {
          return value;
        }
      }
    }

    throw const DataParsingException(
      'Formato inesperado al obtener las invitaciones de la organizacion.',
    );
  }

  Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw const DataParsingException(
      'Formato inesperado de una invitacion de la organizacion.',
    );
  }

  /// Traduce los errores conocidos de `acceptInvitation` en el backend.
  ///
  /// Cualquier otro estado se propaga tal cual para no inventar reglas.
  DataException _translateAcceptFailure(HttpStatusException error) {
    if (error.statusCode == 404) {
      return const ValidationException(
        'La invitacion ya no existe. Pide una invitacion nueva.',
      );
    }

    if (error.statusCode != 400) {
      return error;
    }

    final message = error.message.toLowerCase();

    if (message.contains('expired')) {
      return const ValidationException(
        'La invitacion expiro. Pide una invitacion nueva al administrador.',
      );
    }

    if (message.contains('not pending')) {
      return const ValidationException(
        'La invitacion ya fue aceptada o cancelada.',
      );
    }

    if (message.contains('already belongs')) {
      return const ValidationException('Ya perteneces a esta organizacion.');
    }

    return error;
  }

  /// Traduce los estados que devuelve `createInvitation` en el backend.
  ///
  /// El 403 no llega aca: el cliente HTTP lo convierte antes en
  /// [PermissionDeniedException]. Cualquier estado no contemplado se propaga
  /// tal cual para no inventar reglas.
  DataException _translateCreateFailure(HttpStatusException error) {
    final message = error.message.toLowerCase();

    if (error.statusCode == 404) {
      return const ValidationException(
        'El usuario invitado ya no existe. Busca el usuario otra vez.',
      );
    }

    if (error.statusCode == 409) {
      if (message.contains('pending') || message.contains('invitation')) {
        return const ValidationException(
          'Ese usuario ya tiene una invitacion pendiente en esta '
          'organizacion.',
        );
      }

      return const ValidationException(
        'Ese usuario ya pertenece a esta organizacion o ya tiene una '
        'invitacion pendiente.',
      );
    }

    if (error.statusCode != 400) {
      return error;
    }

    if (message.contains('yourself') || message.contains('self')) {
      return const ValidationException('No puedes invitarte a ti mismo.');
    }

    return ValidationException(
      'Los datos de la invitacion no son validos: ${error.message}',
    );
  }
}
