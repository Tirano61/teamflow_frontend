import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../components/presentation/bloc/component_bloc.dart';
import '../../../tags/presentation/bloc/tag_bloc.dart';
import '../../../work_modules/presentation/bloc/work_module_bloc.dart';
import '../../domain/entities/discussion.dart';
import '../bloc/discussion_bloc.dart';

/// Catalogos de la organizacion activa (modulos, componentes y tags) que ya
/// cargo el tablero. Las rutas de detalle y editor que abre el tablero los
/// reutilizan (sin cerrarlos) en lugar de volver a pedirlos. Pertenecen a la
/// ruta del tablero: al cambiar de organizacion o cerrar sesion la pila se
/// reinicia y se descartan con ella. Despues de administrar un catalogo desde
/// el editor se recargan, asi que el tablero y el detalle ven los cambios.
class DiscussionCatalogBlocs {
  const DiscussionCatalogBlocs({
    required this.workModuleBloc,
    required this.componentBloc,
    required this.tagBloc,
  });

  factory DiscussionCatalogBlocs.of(BuildContext context) {
    return DiscussionCatalogBlocs(
      workModuleBloc: context.read<WorkModuleBloc>(),
      componentBloc: context.read<ComponentBloc>(),
      tagBloc: context.read<TagBloc>(),
    );
  }

  final WorkModuleBloc workModuleBloc;
  final ComponentBloc componentBloc;
  final TagBloc tagBloc;
}

class DiscussionDetailRouteArgs {
  const DiscussionDetailRouteArgs({
    required this.discussionId,
    this.discussionBloc,
    this.catalogBlocs,
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

  final DiscussionCatalogBlocs? catalogBlocs;
}

class DiscussionEditorRouteArgs {
  const DiscussionEditorRouteArgs({
    this.discussion,
    this.discussionId,
    this.catalogBlocs,
  });

  final Discussion? discussion;
  final String? discussionId;

  /// Catalogos ya cargados por quien abre el editor. El editor tiene siempre
  /// su propio `DiscussionBloc`: devuelve el resultado al cerrarse.
  final DiscussionCatalogBlocs? catalogBlocs;
}
