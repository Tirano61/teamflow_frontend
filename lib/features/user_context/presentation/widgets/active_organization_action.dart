import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Accion de AppBar que muestra la organizacion activa del Workspace.
///
/// El nombre sale de `AuthState.activeOrganization`, que resuelve
/// `activeOrganizationId` contra el `/me/context` ya cargado: no dispara
/// ninguna llamada adicional.
///
/// Abre siempre el selector reutilizado (`OrganizationSelectionPage` en modo
/// cambio), tenga el usuario una organizacion o varias: ademas de cambiar de
/// organizacion, esa pantalla es el acceso a `Crear organizacion`. Con una sola
/// organizacion cambia el icono y el tooltip, porque no hay nada entre lo que
/// alternar.
class ActiveOrganizationAction extends StatelessWidget {
  const ActiveOrganizationAction({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final organization = state.activeOrganization;
    if (organization == null) {
      return const SizedBox.shrink();
    }

    final label = organization.displayName.isEmpty
        ? 'Organizacion'
        : organization.displayName;

    // El nombre no puede empujar el titulo de la AppBar en pantallas chicas.
    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;
    final maxLabelWidth = isCompact ? 110.0 : 200.0;

    final canSwitch = state.canSwitchOrganization;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Tooltip(
        message: canSwitch ? 'Cambiar organizacion' : 'Tus organizaciones',
        child: TextButton.icon(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.organizationSwitch),
          icon: Icon(
            canSwitch ? Icons.swap_horiz_rounded : Icons.apartment_outlined,
            size: 18,
          ),
          label: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxLabelWidth),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
