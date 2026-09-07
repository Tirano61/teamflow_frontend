import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_search_result.dart';

/// Usuario devuelto por `GET /users/search?q={query}&limit={limit}`.
///
/// El backend responde una lista plana, sin envoltorio ni paginacion:
///
/// ```json
/// [
///   {
///     "id": "<userId>",
///     "email": "dev@teamflow.com",
///     "fullName": "Dev TeamFlow"
///   }
/// ]
/// ```
///
/// El endpoint ya excluye al usuario autenticado y a los inactivos, asi que no
/// se modela `isActive` ni ningun otro campo que no venga.
class UserSearchResultModel {
  const UserSearchResultModel({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final String id;
  final String email;
  final String fullName;

  factory UserSearchResultModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', 'userId', '_id']);
    if (id == null) {
      throw const DataParsingException(
        'Un resultado de la busqueda de usuarios no incluye un id valido.',
      );
    }

    return UserSearchResultModel(
      id: id,
      email: _readString(json, const ['email']) ?? '',
      fullName: _readString(json, const ['fullName', 'name']) ?? '',
    );
  }

  UserSearchResult toEntity() {
    return UserSearchResult(id: id, email: email, fullName: fullName);
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
}
