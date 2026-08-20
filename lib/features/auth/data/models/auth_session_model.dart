import '../../../../core/error/exceptions.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roles,
    required this.token,
  });

  final String id;
  final String email;
  final String fullName;
  final List<String> roles;
  final String token;

  factory AuthSessionModel.fromApiJson(Map<String, dynamic> json) {
    final payload = _extractPayload(json);

    final token = _readString(payload, const ['token', 'accessToken']);
    final id = _readString(payload, const ['id', 'userId', '_id']);
    final email = _readString(payload, const ['email']);
    final fullName = _readString(payload, const ['fullName', 'name']);

    if (token == null ||
        token.isEmpty ||
        id == null ||
        id.isEmpty ||
        email == null ||
        email.isEmpty ||
        fullName == null ||
        fullName.isEmpty) {
      throw const DataParsingException(
        'No se pudo interpretar la sesion desde la respuesta de login.',
      );
    }

    return AuthSessionModel(
      id: id,
      email: email,
      fullName: fullName,
      roles: _readRoles(payload),
      token: token,
    );
  }

  factory AuthSessionModel.fromStorageJson(Map<String, dynamic> json) {
    final token = _readString(json, const ['token']);
    final id = _readString(json, const ['id']);
    final email = _readString(json, const ['email']);
    final fullName = _readString(json, const ['fullName']);

    if (token == null ||
        token.isEmpty ||
        id == null ||
        id.isEmpty ||
        email == null ||
        email.isEmpty ||
        fullName == null ||
        fullName.isEmpty) {
      throw const DataParsingException(
        'No se pudo recuperar la sesion local almacenada.',
      );
    }

    return AuthSessionModel(
      id: id,
      email: email,
      fullName: fullName,
      roles: _readRoles(json),
      token: token,
    );
  }

  AuthSession toEntity() {
    return AuthSession(
      accessToken: token,
      user: AuthUser(id: id, email: email, fullName: fullName, roles: roles),
    );
  }

  Map<String, dynamic> toStorageJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'fullName': fullName,
      'roles': roles,
      'token': token,
    };
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    return json;
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

  static List<String> _readRoles(Map<String, dynamic> json) {
    final value = json['roles'];
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }
}
