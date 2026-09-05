import '../../../../core/error/exceptions.dart';
import '../../domain/entities/context_user.dart';
import '../../domain/entities/pending_invitation.dart';
import '../../domain/entities/user_context.dart';
import '../../domain/entities/user_organization.dart';

/// Usuario devuelto por `GET /me/context`.
class ContextUserModel {
  const ContextUserModel({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final String id;
  final String email;
  final String fullName;

  factory ContextUserModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', 'userId', '_id']);
    if (id == null) {
      throw const DataParsingException(
        'El contexto del usuario no incluye un id valido.',
      );
    }

    return ContextUserModel(
      id: id,
      email: _readString(json, const ['email']) ?? '',
      fullName: _readString(json, const ['fullName', 'name']) ?? '',
    );
  }

  ContextUser toEntity() {
    return ContextUser(id: id, email: email, fullName: fullName);
  }
}

/// Organizacion del usuario devuelta por `GET /me/context`.
class UserOrganizationModel {
  const UserOrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String role;
  final DateTime? joinedAt;

  factory UserOrganizationModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', 'organizationId', '_id']);
    if (id == null) {
      throw const DataParsingException(
        'Una organizacion del contexto no incluye un id valido.',
      );
    }

    return UserOrganizationModel(
      id: id,
      name: _readString(json, const ['name', 'organizationName']) ?? '',
      slug: _readString(json, const ['slug', 'organizationSlug']) ?? '',
      role: _readString(json, const ['role']) ?? '',
      joinedAt: _readDateTime(json, const ['joinedAt', 'joined_at']),
    );
  }

  UserOrganization toEntity() {
    return UserOrganization(
      id: id,
      name: name,
      slug: slug,
      role: role,
      joinedAt: joinedAt,
    );
  }
}

/// Invitacion pendiente devuelta por `GET /me/context`.
class PendingInvitationModel {
  const PendingInvitationModel({
    required this.invitationId,
    required this.organizationId,
    required this.organizationName,
    required this.organizationSlug,
    required this.role,
    required this.token,
    this.expiresAt,
  });

  final String invitationId;
  final String organizationId;
  final String organizationName;
  final String organizationSlug;
  final String role;
  final String token;
  final DateTime? expiresAt;

  factory PendingInvitationModel.fromJson(Map<String, dynamic> json) {
    final invitationId = _readString(json, const [
      'invitationId',
      'id',
      '_id',
    ]);
    if (invitationId == null) {
      throw const DataParsingException(
        'Una invitacion pendiente no incluye un id valido.',
      );
    }

    return PendingInvitationModel(
      invitationId: invitationId,
      organizationId: _readString(json, const ['organizationId']) ?? '',
      organizationName: _readString(json, const ['organizationName']) ?? '',
      organizationSlug: _readString(json, const ['organizationSlug']) ?? '',
      role: _readString(json, const ['role']) ?? '',
      token: _readString(json, const ['token']) ?? '',
      expiresAt: _readDateTime(json, const ['expiresAt', 'expires_at']),
    );
  }

  PendingInvitation toEntity() {
    return PendingInvitation(
      invitationId: invitationId,
      organizationId: organizationId,
      organizationName: organizationName,
      organizationSlug: organizationSlug,
      role: role,
      token: token,
      expiresAt: expiresAt,
    );
  }
}

/// Contexto completo devuelto por `GET /me/context`.
class UserContextModel {
  const UserContextModel({
    required this.user,
    required this.organizations,
    required this.pendingInvitations,
    required this.organizationCount,
  });

  final ContextUserModel user;
  final List<UserOrganizationModel> organizations;
  final List<PendingInvitationModel> pendingInvitations;
  final int organizationCount;

  factory UserContextModel.fromJson(Map<String, dynamic> json) {
    final payload = _extractPayload(json);

    final userJson = _readMap(payload, const ['user']);
    if (userJson == null) {
      throw const DataParsingException(
        'La respuesta de /me/context no incluye el usuario.',
      );
    }

    final organizations = _readList(payload, const ['organizations'])
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(UserOrganizationModel.fromJson)
        .toList(growable: false);

    final pendingInvitations =
        _readList(payload, const ['pendingInvitations', 'invitations'])
            .map(_asMap)
            .whereType<Map<String, dynamic>>()
            .map(PendingInvitationModel.fromJson)
            .toList(growable: false);

    return UserContextModel(
      user: ContextUserModel.fromJson(userJson),
      organizations: organizations,
      pendingInvitations: pendingInvitations,
      organizationCount:
          _readInt(payload, const ['organizationCount', 'organizationsCount']) ??
          organizations.length,
    );
  }

  UserContext toEntity() {
    return UserContext(
      user: user.toEntity(),
      organizations: organizations
          .map((organization) => organization.toEntity())
          .toList(growable: false),
      pendingInvitations: pendingInvitations
          .map((invitation) => invitation.toEntity())
          .toList(growable: false),
      organizationCount: organizationCount,
    );
  }
}

Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    return data;
  }

  return json;
}

Map<String, dynamic>? _asMap(Object? value) {
  return value is Map<String, dynamic> ? value : null;
}

Map<String, dynamic>? _readMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _asMap(json[key]);
    if (value != null) {
      return value;
    }
  }

  return null;
}

List<dynamic> _readList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value;
    }
  }

  return const [];
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

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toInt();
    }

    final parsed = int.tryParse(value?.toString().trim() ?? '');
    if (parsed != null) {
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
