class AppBreakpoints {
  const AppBreakpoints._();

  static const double compact = 840;
  static const double kanban = 1100;
  static const double discussionPanel = 1500;

  /// Ancho desde el que el panel de miembros del Workspace se integra como
  /// columna derecha en lugar de abrirse como panel temporal.
  ///
  /// Es [kanban] mas el ancho del panel (280): con el panel abierto el
  /// contenido principal sigue teniendo lugar para el tablero en columnas y no
  /// cae al layout movil solo por mostrar la lista de miembros.
  static const double membersPanel = 1380;
}
