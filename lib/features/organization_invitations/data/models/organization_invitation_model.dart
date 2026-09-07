import '../../../../core/error/exceptions.dart';
import '../../domain/entities/invitation_status.dart';
import '../../domain/entities/organization_invitation.dart';

/// Invitacion devuelta por `GET /organizations/{organizationId}/invitations`.
///
/// El backend responde una lista plana, mas recientes primero, sin envoltorio
/// ni paginacion:
///
/// ```json
/// [
///   {
///     "invitationId": "<uuid>",
///     "invitedUser": {
///       "id": "<userId>",
///       "email": "usuario@email.com",
///       "fullName": "Nombre"
///     },
///     "email": "usuario@email.com",
///     "role": "MEMBER",
///     "status": "PENDING",
///     "expiresAt": "2026-01-22T12:00:00.000Z",
///     "acceptedAt": null,
///     "createdAt": "2026-01-15T12:00:00.000Z"
///   }
/// ]
/// ```
///
/// `invitedUser` llega null solo en invitaciones legacy, creadas cuando se
/// invitaba por email a alguien sin cuenta. El `token` no viaja en este
/// endpoint: es la vista de quien invita, no de quien acepta.
class OrganizationInvitationModel {
  const OrganizationInvitationModel({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.invitedUser,
    this.expiresAt,
    this.acceptedAt,
    this.createdAt,
  });

  final String id;
  final String email;
  final String role;
  final String status;
  final OrganizationInvitationUserModel? invitedUser;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? createdAt;

  factory OrganizationInvitationModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['invitationId', 'id', '_id']);
    if (id == null) {
      throw const DataParsingException(
        'Una invitacion de la organizacion no incluye un id valido.',
      );
    }

    final invitedUser = _readMap(json, const ['invitedUser', 'user']);

    return OrganizationInvitationModel(
      id: id,
      email: _readString(json, const ['email']) ?? '',
      role: _readString(json, const ['role']) ?? '',
      status: _readString(json, const ['status']) ?? '',
      invitedUser: invitedUser == null
          ? null
          : OrganizationInvitationUserModel.fromJson(invitedUser),
      expiresAt: _readDateTime(json, const ['expiresAt', 'expires_at']),
      acceptedAt: _readDateTime(json, const ['acceptedAt', 'accepted_at']),
      createdAt: _readDateTime(json, const ['createdAt', 'created_at']),
    );
  }

  OrganizationInvitation toEntity() {
    return OrganizationInvitation(
      id: id,
      email: email,
      role: role,
      status: InvitationStatus.fromApiValue(status),
      invitedUser: invitedUser?.toEntity(),
      expiresAt: expiresAt,
      acceptedAt: acceptedAt,
      createdAt: createdAt,
    );
  }
}

/// Bloque `invitedUser` de la invitacion.
///
/// Un `invitedUser` presente pero incompleto no invalida la invitacion: la
/// pantalla solo muestra nombre y email, y el email tambien viaja en la raiz.
class OrganizationInvitationUserModel {
  const OrganizationInvitationUserModel({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final String id;
  final String email;
  final String fullName;

  factory OrganizationInvitationUserModel.fromJson(Map<String, dynamic> json) {
    return OrganizationInvitationUserModel(
      id: _readString(json, const ['id', 'userId', '_id']) ?? '',
      email: _readString(json, const ['email']) ?? '',
      fullName: _readString(json, const ['fullName', 'name']) ?? '',
    );
  }

  OrganizationInvitationUser toEntity() {
    return OrganizationInvitationUser(id: id, email: email, fullName: fullName);
  }
}

Map<String, dynamic>? _readMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
  }

  return null;
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }

    final parsed = value.toString().trim();
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }

  return null;
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value);
}
