/// Usuario registrado devuelto por `GET /users/search`.
///
/// Es el minimo publico que expone el backend para elegir un destinatario de
/// invitacion: no es el usuario autenticado ni un miembro de la organizacion.
class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.email,
    required this.fullName,
  });

  /// `userId` que viaja en el body de `POST .../invitations`.
  final String id;

  final String email;
  final String fullName;

  /// Nombre visible del usuario.
  ///
  /// Cae al email cuando el usuario no tiene nombre cargado. Puede quedar
  /// vacio: el texto de reemplazo lo decide cada pantalla.
  String get displayName {
    final trimmedName = fullName.trim();
    return trimmedName.isEmpty ? email.trim() : trimmedName;
  }
}
