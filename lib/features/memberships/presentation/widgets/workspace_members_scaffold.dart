import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_breakpoints.dart';
import 'workspace_members_panel.dart';

/// `Scaffold` de las pantallas principales del Workspace con la accion
/// `Miembros` y su panel.
///
/// Concentra la decision responsive para que ninguna pantalla la repita:
///
/// - Ancho >= `AppBreakpoints.membersPanel`: el panel se integra como columna
///   derecha de ancho acotado y el boton lo muestra/oculta.
/// - Ancho menor: el boton abre el panel como `endDrawer` temporal; al
///   cerrarlo el contenido queda exactamente como estaba.
///
/// La visibilidad es estado de presentacion local de la pantalla: no se
/// persiste. Requiere un `MembershipBloc` provisto por la ruta.
class WorkspaceMembersScaffold extends StatefulWidget {
  const WorkspaceMembersScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
  });

  final Widget title;
  final Widget body;

  /// Acciones de la AppBar que van despues de `Miembros`.
  final List<Widget> actions;

  final Widget? floatingActionButton;

  @override
  State<WorkspaceMembersScaffold> createState() =>
      _WorkspaceMembersScaffoldState();
}

class _WorkspaceMembersScaffoldState extends State<WorkspaceMembersScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Panel integrado visible. Solo aplica en pantallas anchas.
  bool _panelVisible = false;

  void _onMembersPressed({required bool inline}) {
    if (inline) {
      setState(() {
        _panelVisible = !_panelVisible;
      });
      return;
    }

    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _hideInlinePanel() {
    setState(() {
      _panelVisible = false;
    });
  }

  void _closeDrawer() {
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final inline = screenWidth >= AppBreakpoints.membersPanel;
    final showInlinePanel = inline && _panelVisible;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: widget.title,
        actions: [
          _MembersAction(
            selected: showInlinePanel,
            compact: screenWidth < AppBreakpoints.compact,
            onPressed: () => _onMembersPressed(inline: inline),
          ),
          ...widget.actions,
        ],
      ),
      endDrawer: inline
          ? null
          : Drawer(
              width: math.min(320, screenWidth * 0.85),
              child: SafeArea(
                child: WorkspaceMembersPanel(onClose: _closeDrawer),
              ),
            ),
      floatingActionButton: widget.floatingActionButton,
      // El contenido es siempre el primer hijo del Row: mostrar u ocultar el
      // panel no reconstruye su subarbol ni pierde su estado.
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: widget.body),
          if (showInlinePanel) ...[
            const VerticalDivider(width: 1),
            SizedBox(
              width: WorkspaceMembersPanel.width,
              child: WorkspaceMembersPanel(onClose: _hideInlinePanel),
            ),
          ],
        ],
      ),
    );
  }
}

/// Boton `Miembros` de la AppBar. Disponible para cualquier Membership
/// ACTIVE: no depende del rol.
class _MembersAction extends StatelessWidget {
  const _MembersAction({
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  final bool selected;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(selected ? Icons.groups : Icons.groups_outlined);

    if (compact) {
      return IconButton(tooltip: 'Miembros', onPressed: onPressed, icon: icon);
    }

    return Tooltip(
      message: selected ? 'Ocultar miembros' : 'Mostrar miembros',
      child: TextButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: const Text('Miembros'),
      ),
    );
  }
}
