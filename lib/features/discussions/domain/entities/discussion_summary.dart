import 'discussion.dart';

/// Contadores globales de `GET .../discussions` (`summary`).
///
/// Los calcula el backend sobre todas las discussions que cumplen los filtros,
/// no sobre las paginas descargadas:
/// - [byStatus] aplica todos los filtros excepto `status` y siempre trae los
///   cuatro estados.
/// - [total] aplica todos los filtros: con filtro `status` es
///   `byStatus[status]`; sin el, la suma de [byStatus].
class DiscussionSummary {
  const DiscussionSummary({required this.total, required this.byStatus});

  /// Estados que el backend cuenta en `byStatus`.
  static const List<DiscussionRecordStatus> countedStatuses = [
    DiscussionRecordStatus.newDiscussion,
    DiscussionRecordStatus.review,
    DiscussionRecordStatus.inProgress,
    DiscussionRecordStatus.resolved,
  ];

  final int total;
  final Map<DiscussionRecordStatus, int> byStatus;

  int countFor(DiscussionRecordStatus status) => byStatus[status] ?? 0;

  /// Mismos contadores vistos con otro filtro `status`: `byStatus` no depende
  /// de ese filtro y `total` se deriva de el (ver la documentacion del
  /// endpoint).
  DiscussionSummary withStatusFilter(DiscussionRecordStatus? status) {
    return DiscussionSummary(
      total: _totalFor(byStatus, status),
      byStatus: byStatus,
    );
  }

  /// Saca una discussion del conteo de [from] y la suma en [to] (cualquiera de
  /// los dos puede ser `null`: no contaba antes / no cuenta despues).
  DiscussionSummary move({
    DiscussionRecordStatus? from,
    DiscussionRecordStatus? to,
    DiscussionRecordStatus? statusFilter,
  }) {
    final next = Map<DiscussionRecordStatus, int>.from(byStatus);
    if (from != null && next.containsKey(from)) {
      final current = next[from]!;
      next[from] = current > 0 ? current - 1 : 0;
    }
    if (to != null && next.containsKey(to)) {
      next[to] = next[to]! + 1;
    }

    final unmodifiable = Map<DiscussionRecordStatus, int>.unmodifiable(next);
    return DiscussionSummary(
      total: _totalFor(unmodifiable, statusFilter),
      byStatus: unmodifiable,
    );
  }

  static int _totalFor(
    Map<DiscussionRecordStatus, int> byStatus,
    DiscussionRecordStatus? status,
  ) {
    if (status != null && status != DiscussionRecordStatus.unknown) {
      return byStatus[status] ?? 0;
    }

    return byStatus.values.fold<int>(0, (sum, count) => sum + count);
  }
}
