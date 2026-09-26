import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/discussion_permissions.dart';

/// Resuelve [DiscussionPermissions] desde el estado de Auth.
///
/// Unico punto donde las pantallas de Discussions leen el rol de la
/// organizacion activa y el id del usuario autenticado, para que todas usen la
/// misma fuente. El rol sale de `activeOrganization` (`/me/context`), nunca de
/// `session.user.roles`.
extension DiscussionPermissionsResolver on AuthState {
  DiscussionPermissions get discussionPermissions {
    final role = activeOrganization?.role ?? '';
    final userId = session?.user.id ?? '';
    if (role.isEmpty && userId.isEmpty) {
      return DiscussionPermissions.none;
    }

    return DiscussionPermissions.forMember(
      membershipRole: role,
      currentUserId: userId,
    );
  }
}
