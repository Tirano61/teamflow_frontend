import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';

abstract class OrganizationInvitationRemoteDataSource {
  Future<void> acceptInvitation({required String token});
}

/// `POST /organization-invitations/{token}/accept`.
///
/// Endpoint autenticado y global: la organizacion la determina la propia
/// invitacion, por lo que no depende de `OrganizationContext`. La respuesta
/// (la membresia creada) no se usa: el estado real lo confirma el refresh
/// posterior de `/me/context`.
class OrganizationInvitationRemoteDataSourceImpl
    implements OrganizationInvitationRemoteDataSource {
  OrganizationInvitationRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

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
}
