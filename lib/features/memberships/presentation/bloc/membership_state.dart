import '../../domain/entities/membership.dart';

enum MembershipStatus { initial, loading, success, error }

/// Estado del cambio de rol de un miembro.
///
/// `idle` es tanto el arranque como el estado despues de mostrar el resultado:
/// solo hay un cambio en curso a la vez.
enum ChangeMemberRoleStatus { idle, saving, success, error }

class MembershipState {
  const MembershipState({
    this.status = MembershipStatus.initial,
    this.members = const [],
    this.errorMessage = '',
    this.changeRoleStatus = ChangeMemberRoleStatus.idle,
    this.changingMembershipId = '',
    this.changeRoleErrorMessage = '',
  });

  final MembershipStatus status;
  final List<Membership> members;
  final String errorMessage;

  final ChangeMemberRoleStatus changeRoleStatus;

  /// Miembro cuyo rol se esta cambiando ahora mismo (o el ultimo resuelto).
  ///
  /// Permite mostrar el loading solo en la fila pulsada.
  final String changingMembershipId;

  final String changeRoleErrorMessage;

  /// Hay un cambio de rol en curso: bloquea el doble submit y deshabilita la
  /// accion en el resto de las filas.
  bool get isChangingRole => changeRoleStatus == ChangeMemberRoleStatus.saving;

  /// El miembro [membershipId] es el que se esta actualizando ahora mismo.
  bool isChangingRoleOf(String membershipId) =>
      isChangingRole && changingMembershipId == membershipId.trim();

  /// El miembro [membershipId] tal como esta en el listado, o `null` si ya no
  /// esta.
  Membership? memberById(String membershipId) {
    final normalizedId = membershipId.trim();

    for (final member in members) {
      if (member.id == normalizedId) {
        return member;
      }
    }

    return null;
  }

  /// Copia del listado con [updated] en lugar del miembro del mismo id.
  ///
  /// Refleja el cambio de rol sin recargar: el resto de las filas y el orden
  /// del backend se mantienen.
  List<Membership> membersWithUpdated(Membership updated) {
    return members
        .map((member) => member.id == updated.id ? updated : member)
        .toList(growable: false);
  }

  MembershipState copyWith({
    MembershipStatus? status,
    List<Membership>? members,
    String? errorMessage,
    ChangeMemberRoleStatus? changeRoleStatus,
    String? changingMembershipId,
    String? changeRoleErrorMessage,
  }) {
    return MembershipState(
      status: status ?? this.status,
      members: members ?? this.members,
      errorMessage: errorMessage ?? this.errorMessage,
      changeRoleStatus: changeRoleStatus ?? this.changeRoleStatus,
      changingMembershipId: changingMembershipId ?? this.changingMembershipId,
      changeRoleErrorMessage:
          changeRoleErrorMessage ?? this.changeRoleErrorMessage,
    );
  }
}
