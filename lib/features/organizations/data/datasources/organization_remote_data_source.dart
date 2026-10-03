import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../core/organization/organization_context.dart';
import '../../domain/entities/security_verification.dart';
import '../models/organization_model.dart';
import '../models/security_verification_model.dart';

abstract class OrganizationRemoteDataSource {
  Future<OrganizationModel> createOrganization({required String name});

  /// Pide el codigo de seguridad `DELETE_ORGANIZATION` de la organizacion
  /// activa. El backend lo envia al email del usuario autenticado.
  Future<RequestedSecurityVerificationModel> requestOrganizationDeletionCode();

  /// Verifica el [code] de la verificacion [verificationId] de la
  /// organizacion activa. No elimina nada.
  Future<VerifiedSecurityVerificationModel> verifySecurityCode({
    required String verificationId,
    required String code,
  });

  /// Elimina definitivamente la organizacion activa.
  Future<void> deleteActiveOrganization();
}

/// Ciclo de vida de una organizacion.
///
/// - `POST /organizations` es global: crea la organizacion y deja al usuario
///   autenticado como `OWNER`, por lo que no depende de `OrganizationContext`.
/// - La eliminacion segura (codigo de seguridad, verificacion y `DELETE`) es
///   tenant: opera siempre sobre la organizacion activa, resuelta contra
///   `OrganizationContext` en cada request.
class OrganizationRemoteDataSourceImpl implements OrganizationRemoteDataSource {
  OrganizationRemoteDataSourceImpl({
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

  /// Formato que exige `VerifySecurityVerificationDto` en el backend.
  static final RegExp _codePattern = RegExp(r'^\d{6}$');

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

  /// `POST /organizations/{organizationId}/security-verifications`.
  ///
  /// El body lleva solo `purpose`: el backend toma el usuario (y su email) del
  /// JWT y la organizacion del path, y rechaza cualquier otra propiedad.
  @override
  Future<RequestedSecurityVerificationModel>
  requestOrganizationDeletionCode() async {
    try {
      final response = await _restClient.post<Object?>(
        ApiEndpoints.organizationSecurityVerifications(_organizationId),
        body: <String, dynamic>{
          'purpose': SecurityVerificationPurpose.deleteOrganization.apiValue,
        },
      );

      return RequestedSecurityVerificationModel.fromJson(
        _requireMap(response.data),
      );
    } on PermissionDeniedException {
      // El 403 de este endpoint es pertenencia, membresia no activa o role
      // distinto de OWNER: el mensaje generico del cliente HTTP habla de otro
      // caso.
      throw const PermissionDeniedException(
        'Solo el propietario (OWNER) de la organizacion, con su membresia '
        'activa, puede eliminarla.',
      );
    } on HttpStatusException catch (error) {
      throw _translateRequestCodeFailure(error);
    }
  }

  /// `POST /organizations/{organizationId}/security-verifications/{verificationId}/verify`.
  ///
  /// El body lleva solo `code`. El backend busca la verificacion por
  /// `verificationId` + usuario + organizacion: una ajena responde 404.
  @override
  Future<VerifiedSecurityVerificationModel> verifySecurityCode({
    required String verificationId,
    required String code,
  }) async {
    final normalizedId = verificationId.trim();
    if (normalizedId.isEmpty) {
      throw const ValidationException(
        'No hay un codigo de seguridad pendiente. Solicita uno nuevo.',
      );
    }

    // Un body invalido no consume intentos en el backend, pero se evita el
    // request: el formato lo valida la UI antes de habilitar la accion.
    final normalizedCode = code.trim();
    if (!_codePattern.hasMatch(normalizedCode)) {
      throw const ValidationException(
        'El codigo tiene que tener exactamente 6 digitos.',
      );
    }

    try {
      final response = await _restClient.post<Object?>(
        ApiEndpoints.organizationSecurityVerificationVerify(
          _organizationId,
          normalizedId,
        ),
        body: <String, dynamic>{'code': normalizedCode},
      );

      return VerifiedSecurityVerificationModel.fromJson(
        _requireMap(response.data),
      );
    } on PermissionDeniedException {
      throw const PermissionDeniedException(
        'Ya no tienes permisos para eliminar esta organizacion.',
      );
    } on HttpStatusException catch (error) {
      throw _translateVerifyCodeFailure(error);
    }
  }

  /// `DELETE /organizations/{organizationId}`.
  ///
  /// Sin body: no se envia `verificationId` ni `code`. El backend busca la
  /// autorizacion `VERIFIED` por usuario + organizacion + purpose y la
  /// consume en la misma transaccion del borrado. Exito: `204` sin body.
  @override
  Future<void> deleteActiveOrganization() async {
    try {
      await _restClient.delete<Object?>(
        ApiEndpoints.organizationById(_organizationId),
      );
    } on PermissionDeniedException {
      // El backend usa 403 para varios casos (ya no pertenece, membresia no
      // activa, ya no es OWNER, autorizacion vencida o inexistente) y solo los
      // distingue por un mensaje en ingles. No se adivina cual fue.
      throw const PermissionDeniedException(
        'No se pudo eliminar la organizacion. Puede que la autorizacion del '
        'codigo haya vencido o que tus permisos hayan cambiado.',
      );
    } on HttpStatusException catch (error) {
      throw _translateDeleteFailure(error);
    }
  }

  /// Traduce los estados de la solicitud del codigo.
  ///
  /// El 403 no llega aca: el cliente HTTP lo convierte antes en
  /// [PermissionDeniedException]. 429 y 503 conservan su `statusCode`.
  DataException _translateRequestCodeFailure(HttpStatusException error) {
    switch (error.statusCode) {
      case 400:
        return const ValidationException(
          'No se pudo solicitar el codigo: la solicitud no es valida.',
        );
      case 429:
        return const HttpStatusException(
          statusCode: 429,
          message:
              'Ya se solicito un codigo hace muy poco. Espera un momento antes '
              'de pedir otro.',
        );
      case 503:
        return const HttpStatusException(
          statusCode: 503,
          message:
              'No pudimos enviar el email con el codigo. Intenta de nuevo en '
              'unos minutos.',
        );
    }

    if (error.statusCode >= 500) {
      return HttpStatusException(
        statusCode: error.statusCode,
        message:
            'No se pudo solicitar el codigo de seguridad. Intenta de nuevo mas '
            'tarde.',
      );
    }

    return error;
  }

  /// Traduce los estados de la verificacion del codigo.
  ///
  /// - 400: codigo incorrecto (intentos 1 a 4); la verificacion sigue
  ///   utilizable.
  /// - 404, 409 y 429: la verificacion ya no se puede usar (inexistente,
  ///   vencida, reemplazada, ya usada o bloqueada); hay que pedir otro codigo.
  ///
  /// Se decide solo por `statusCode`, nunca leyendo el mensaje en ingles.
  DataException _translateVerifyCodeFailure(HttpStatusException error) {
    switch (error.statusCode) {
      case 400:
        return const ValidationException(
          'El codigo ingresado no es correcto. Revisalo e intenta de nuevo.',
        );
      case 404:
        return const HttpStatusException(
          statusCode: 404,
          message: 'Este codigo ya no es valido. Solicita uno nuevo.',
        );
      case 409:
        return const HttpStatusException(
          statusCode: 409,
          message:
              'Este codigo vencio o ya no es valido: pudo ser reemplazado por '
              'uno mas reciente. Solicita uno nuevo.',
        );
      case 429:
        return const HttpStatusException(
          statusCode: 429,
          message:
              'Se alcanzo el maximo de intentos para este codigo. Solicita uno '
              'nuevo.',
        );
    }

    if (error.statusCode >= 500) {
      return HttpStatusException(
        statusCode: error.statusCode,
        message: 'No se pudo verificar el codigo. Intenta de nuevo mas tarde.',
      );
    }

    return error;
  }

  /// Traduce los estados del `DELETE`.
  ///
  /// Solo el 409 (cambio concurrente detectado por el backend) garantiza que
  /// no se borro nada y que la autorizacion sigue `VERIFIED`. Cualquier otro
  /// estado se propaga tal cual: el bloc lo trata como resultado no
  /// confirmado.
  DataException _translateDeleteFailure(HttpStatusException error) {
    if (error.statusCode == 409) {
      return const HttpStatusException(
        statusCode: 409,
        message:
            'La organizacion se modifico mientras se eliminaba y no se elimino '
            'nada. Puedes volver a intentarlo.',
      );
    }

    return error;
  }

  /// Las responses de Security Verifications son el objeto plano documentado,
  /// sin wrapper.
  Map<String, dynamic> _requireMap(Object? payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }

    throw const DataParsingException(
      'Formato inesperado en la verificacion de seguridad.',
    );
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
