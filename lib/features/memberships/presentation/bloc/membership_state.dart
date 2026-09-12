import '../../domain/entities/membership.dart';

/// Que listado tiene cargado el bloc.
///
/// El directorio y la administracion no comparten endpoint ni permisos: el
/// scope deja explicito de cual son los miembros que estan en el estado y
/// evita que una accion administrativa se aplique sobre el directorio.
enum MembershipListScope {
  /// `GET .../members`: solo miembros `ACTIVE`, vista informativa.
  directory,

  /// `GET .../members/manage`: miembros `ACTIVE` y `SUSPENDED`, solo
  /// OWNER/ADMIN.
  management,
}

enum MembershipListStatus { initial, loading, success, error }

/// Accion administrativa sobre un miembro.
///
/// Solo hay una en curso a la vez: el bloc ignora la segunda mientras la
/// primera no termina.
enum MemberActionType { none, changeRole, suspend, reactivate }

/// Estado de la accion administrativa en curso.
///
/// `idle` es tanto el arranque como el estado despues de mostrar el resultado.
enum MemberActionStatus { idle, running, success, error }

class MembershipState {
  const MembershipState({
    this.scope = MembershipListScope.directory,
    this.listStatus = MembershipListStatus.initial,
    this.members = const [],
    this.listErrorMessage = '',
    this.actionType = MemberActionType.none,
    this.actionStatus = MemberActionStatus.idle,
    this.actionMembershipId = '',
    this.actionErrorMessage = '',
  });

  /// Listado que esta cargado (o cargandose) ahora mismo.
  final MembershipListScope scope;

  final MembershipListStatus listStatus;
  final List<Membership> members;
  final String listErrorMessage;

  /// Accion administrativa en curso (o la ultima resuelta).
  final MemberActionType actionType;

  final MemberActionStatus actionStatus;

  /// Miembro sobre el que se esta actuando ahora mismo (o el ultimo
  /// resuelto).
  ///
  /// Permite mostrar el loading solo en la fila afectada, sin bloquear toda la
  /// pantalla.
  final String actionMembershipId;

  final String actionErrorMessage;

  /// El estado corresponde al listado administrativo.
  bool get isManagementScope => scope == MembershipListScope.management;

  /// Hay una accion administrativa en curso: bloquea el doble submit y
  /// deshabilita las acciones del resto de las filas.
  bool get isRunningAction => actionStatus == MemberActionStatus.running;

  /// El miembro [membershipId] es el que se esta actualizando ahora mismo.
  bool isRunningActionOn(String membershipId) =>
      isRunningAction && actionMembershipId == membershipId.trim();

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
  /// Refleja el cambio de rol o de status sin recargar: el resto de las filas y
  /// el orden del backend se mantienen.
  List<Membership> membersWithUpdated(Membership updated) {
    return members
        .map((member) => member.id == updated.id ? updated : member)
        .toList(growable: false);
  }

  MembershipState copyWith({
    MembershipListScope? scope,
    MembershipListStatus? listStatus,
    List<Membership>? members,
    String? listErrorMessage,
    MemberActionType? actionType,
    MemberActionStatus? actionStatus,
    String? actionMembershipId,
    String? actionErrorMessage,
  }) {
    return MembershipState(
      scope: scope ?? this.scope,
      listStatus: listStatus ?? this.listStatus,
      members: members ?? this.members,
      listErrorMessage: listErrorMessage ?? this.listErrorMessage,
      actionType: actionType ?? this.actionType,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMembershipId: actionMembershipId ?? this.actionMembershipId,
      actionErrorMessage: actionErrorMessage ?? this.actionErrorMessage,
    );
  }
}
