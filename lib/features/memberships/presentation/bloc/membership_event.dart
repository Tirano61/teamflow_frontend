sealed class MembershipEvent {
  const MembershipEvent();
}

/// Carga los miembros de la organizacion activa.
///
/// No lleva `organizationId`: la organizacion la resuelve el datasource.
class LoadOrganizationMembersEvent extends MembershipEvent {
  const LoadOrganizationMembersEvent();
}
