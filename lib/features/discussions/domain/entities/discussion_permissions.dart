import '../../../memberships/domain/entities/membership_role.dart';
import 'discussion.dart';

/// Permisos efectivos del usuario autenticado sobre Discussions dentro de la
/// organizacion activa.
///
/// Replica la matriz del backend para decidir que acciones se pintan. Depende
/// unicamente del `MembershipRole` en la organizacion activa y del id del
/// usuario autenticado: nunca del rol global `developer` del `User`. Es control
/// visual; la autoridad final sigue siendo el backend, que responde 403 cuando
/// el rol no alcanza.
class DiscussionPermissions {
  const DiscussionPermissions({
    required this.canManageDiscussions,
    required this.currentUserId,
  });

  /// Permisos sin organizacion activa o sin sesion: solo lectura.
  static const DiscussionPermissions none = DiscussionPermissions(
    canManageDiscussions: false,
    currentUserId: '',
  );

  /// Resuelve los permisos a partir del rol de membresia en la organizacion
  /// activa ([membershipRole], tal como llega en `/me/context`) y del id del
  /// usuario autenticado.
  factory DiscussionPermissions.forMember({
    required String membershipRole,
    required String currentUserId,
  }) {
    return DiscussionPermissions(
      canManageDiscussions: MembershipRole.canManageDiscussions(membershipRole),
      currentUserId: currentUserId.trim(),
    );
  }

  /// `OWNER`, `ADMIN` o `DEVELOPER` en la organizacion activa.
  ///
  /// Habilita status, asignaciones y relaciones/contexto (modulos, componentes
  /// y tags). `MEMBER` participa (lee, crea, escribe mensajes) pero no
  /// administra.
  final bool canManageDiscussions;

  /// Id del usuario autenticado. Vacio si no hay sesion.
  final String currentUserId;

  /// Cambiar `DiscussionStatus`.
  bool get canChangeStatus => canManageDiscussions;

  /// Agregar, reemplazar o quitar asignaciones.
  bool get canManageAssignments => canManageDiscussions;

  /// Modificar `moduleIds`, `componentIds` y `tagIds` (tambien via PATCH).
  /// El creador `MEMBER` no puede, aunque la discussion sea suya.
  bool get canManageContext => canManageDiscussions;

  /// El usuario autenticado es el creador de [discussion].
  ///
  /// Compara ids: nunca nombre ni email. Sin `createdBy` o sin sesion no se
  /// asume autoria.
  bool isCreatorOf(Discussion discussion) {
    return isCurrentUser(discussion.createdBy?.id);
  }

  /// Editar `title` y `type` de [discussion]: el creador (cualquier rol
  /// ACTIVE) o un rol de gestion.
  bool canEditTitleAndType(Discussion discussion) {
    return canManageDiscussions || isCreatorOf(discussion);
  }

  /// [userId] coincide con el usuario autenticado. Sirve para autor de
  /// mensajes y creador de discussions; nunca se otorga por rol.
  bool isCurrentUser(String? userId) {
    final normalized = userId?.trim() ?? '';
    return currentUserId.isNotEmpty && normalized == currentUserId;
  }
}
