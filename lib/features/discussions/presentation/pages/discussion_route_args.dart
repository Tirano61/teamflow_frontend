import '../../domain/entities/discussion.dart';
import '../bloc/discussion_bloc.dart';

class DiscussionDetailRouteArgs {
  const DiscussionDetailRouteArgs({
    required this.discussionId,
    this.discussionBloc,
  });

  final String discussionId;

  /// `DiscussionBloc` del tablero que abre el detalle. Si viene, la ruta lo
  /// reutiliza (sin cerrarlo) en lugar de crear uno propio: lo que se cambia en
  /// el detalle queda aplicado en el tablero sin volver a pedir el listado, y
  /// la discussion se pinta con la copia que ya tiene el tablero mientras llega
  /// el `GET` del detalle. Igual que el panel lateral, que comparte el bloc del
  /// tablero. El bloc pertenece a la ruta del tablero, que se descarta al
  /// cambiar de organizacion, asi que no cruza datos entre organizaciones.
  final DiscussionBloc? discussionBloc;
}

class DiscussionEditorRouteArgs {
  const DiscussionEditorRouteArgs({this.discussion, this.discussionId});

  final Discussion? discussion;
  final String? discussionId;
}
