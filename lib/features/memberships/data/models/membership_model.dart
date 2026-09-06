import '../../../../core/error/exceptions.dart';
import '../../domain/entities/membership.dart';

/// Miembro devuelto por `GET /organizations/{organizationId}/members`.
///
/// El backend serializa la entidad `Membership` de TypeORM con la relacion
/// `user` incluida, sin envoltorio ni DTO:
///
/// ```json
/// {
///   "id": "<membershipId>",
///   "role": "OWNER",
///   "status": "ACTIVE",
///   "joinedAt": "2026-01-15T12:00:00.000Z",
///   "createdAt": "...",
///   "updatedAt": "...",
///   "user": {
///     "id": "<userId>",
///     "email": "dev@teamflow.com",
///     "fullName": "Dev TeamFlow",
///     "isActive": true,
///     "roles": ["user"],
///     "created_at": "...",
///     "updated_at": "..."
///   }
/// }
/// ```
///
/// La relacion `organization` no viene en este endpoint y `password` esta
/// marcado como `select: false`, asi que no se modelan.
class MembershipModel {
  const MembershipModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final DateTime? joinedAt;

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', 'membershipId', '_id']);
    if (id == null) {
      throw const DataParsingException(
        'Un miembro de la organizacion no incluye un id valido.',
      );
    }

    // Los datos del usuario llegan anidados en `user`; si alguna vez vinieran
    // planos en la membership, se leen igual desde la raiz.
    final user = _readMap(json, const ['user']) ?? json;

    return MembershipModel(
      id: id,
      userId: _readString(user, const ['id', 'userId', '_id']) ?? '',
      fullName: _readString(user, const ['fullName', 'name']) ?? '',
      email: _readString(user, const ['email']) ?? '',
      role: _readString(json, const ['role']) ?? '',
      status: _readString(json, const ['status']) ?? '',
      joinedAt: _readDateTime(json, const ['joinedAt', 'joined_at']),
    );
  }

  Membership toEntity() {
    return Membership(
      id: id,
      userId: userId,
      fullName: fullName,
      email: email,
      role: role,
      status: status,
      joinedAt: joinedAt,
    );
  }

  static Map<String, dynamic>? _readMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }

    return null;
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
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

  static DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
