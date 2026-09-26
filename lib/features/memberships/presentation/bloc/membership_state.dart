import '../../domain/entities/membership.dart';
import '../../domain/entities/membership_role.dart';

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

/// Miembros del directorio que comparten un `MembershipRole`.
///
/// Es solo agrupacion visual para el panel de miembros del Workspace: no
/// agrega prioridad ni permisos.
class MemberRoleGroup {
  const MemberRoleGroup({required this.role, required this.members});

  /// Rol del grupo tal como lo devuelve el backend (`OWNER`, `ADMIN`,
  /// `DEVELOPER`, `MEMBER`). Vacio para el grupo de roles que este frontend
  /// no conoce.
  final String role;

  final List<Membership> members;

  bool get isUnknownRole => role.isEmpty;
}

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

  /// Orden de los grupos del panel de miembros.
  static const List<String> _roleGroupOrder = [
    MembershipRole.ownerApiValue,
    'ADMIN',
    'DEVELOPER',
    'MEMBER',
  ];

  /// [members] agrupados por rol: `OWNER`, `ADMIN`, `DEVELOPER`, `MEMBER`.
  ///
  /// Solo aparecen los grupos con miembros. Dentro de cada grupo el orden es
  /// por nombre visible (sin distinguir mayusculas) y, a igual nombre, por id
  /// de membership, para que sea estable entre cargas. Un rol desconocido no
  /// se descarta: va a un grupo final con `role` vacio.
  List<MemberRoleGroup> get membersGroupedByRole {
    final byRole = <String, List<Membership>>{};

    for (final member in members) {
      final normalized = member.role.trim().toUpperCase();
      final key = _roleGroupOrder.contains(normalized) ? normalized : '';
      byRole.putIfAbsent(key, () => <Membership>[]).add(member);
    }

    int compare(Membership a, Membership b) {
      final byName = a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      );
      return byName != 0 ? byName : a.id.compareTo(b.id);
    }

    return [
      for (final role in [..._roleGroupOrder, ''])
        if (byRole[role] case final group? when group.isNotEmpty)
          MemberRoleGroup(
            role: role,
            members: List<Membership>.unmodifiable(group..sort(compare)),
          ),
    ];
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
