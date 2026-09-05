import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../user_context/domain/entities/pending_invitation.dart';
import '../../../user_context/presentation/widgets/organization_role_chip.dart';
import '../bloc/organization_invitation_bloc.dart';
import '../bloc/organization_invitation_event.dart';
import '../bloc/organization_invitation_state.dart';

/// Listado de invitaciones pendientes con la accion `Aceptar`.
///
/// Es el unico lugar donde se pinta y se acepta una invitacion: lo comparten
/// el onboarding (`NoOrganizationPage`) y la seleccion de organizacion
/// (`OrganizationSelectionPage`).
///
/// Requiere un `OrganizationInvitationBloc` en el arbol. Cuando la aceptacion
/// termina bien pide el refresh de `/me/context` a `AuthBloc`: la regla de
/// 0 / 1 / varias organizaciones se resuelve alli y la pantalla resultante la
/// elige `AuthGatePage`.
class PendingInvitationsSection extends StatelessWidget {
  const PendingInvitationsSection({
    super.key,
    required this.invitations,
    this.description,
  });

  final List<PendingInvitation> invitations;

  /// Texto opcional bajo el titulo de la seccion.
  final String? description;

  @override
  Widget build(BuildContext context) {
    if (invitations.isEmpty) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final descriptionText = description?.trim() ?? '';

    return BlocListener<OrganizationInvitationBloc, OrganizationInvitationState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case OrganizationInvitationStatus.success:
            _showMessage(context, 'Invitacion aceptada.');
            // El destino final (workspace, selector u onboarding) lo decide
            // el nuevo `/me/context`, no esta pantalla.
            context.read<AuthBloc>().add(
              const AuthUserContextRefreshRequested(),
            );
          case OrganizationInvitationStatus.error:
            _showMessage(context, state.errorMessage);
          case OrganizationInvitationStatus.initial:
          case OrganizationInvitationStatus.accepting:
            break;
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invitaciones pendientes (${invitations.length})',
            style: textTheme.titleMedium,
          ),
          if (descriptionText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(descriptionText, style: textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.md),
          for (final invitation in invitations) ...[
            _PendingInvitationCard(invitation: invitation),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    final text = message.trim();
    if (text.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _PendingInvitationCard extends StatelessWidget {
  const _PendingInvitationCard({required this.invitation});

  final PendingInvitation invitation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = invitation.organizationName.trim().isEmpty
        ? invitation.organizationSlug
        : invitation.organizationName;
    final slug = invitation.organizationSlug.trim();
    final expiresAt = invitation.expiresAt;

    // Mientras `/me/context` se esta recargando la lista todavia es la vieja:
    // aceptar otra invitacion ahora perderia el refresh siguiente.
    final isRefreshingContext = context
        .watch<AuthBloc>()
        .state
        .isUserContextLoading;

    return BlocBuilder<OrganizationInvitationBloc, OrganizationInvitationState>(
      builder: (context, state) {
        final isAcceptingThis = state.isAcceptingToken(invitation.token);
        final isBlocked = state.isAccepting || isRefreshingContext;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Organizacion sin nombre' : name,
                  style: textTheme.titleMedium,
                ),
                if (slug.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('@$slug', style: textTheme.bodySmall),
                ],
                if (invitation.role.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OrganizationRoleChip(role: invitation.role),
                ],
                if (expiresAt != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Vence el ${_formatDate(expiresAt)}',
                    style: textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    // Mientras hay una aceptacion en curso se bloquean todas
                    // las filas, pero el loading solo se ve en la pulsada.
                    onPressed: isBlocked
                        ? null
                        : () => context.read<OrganizationInvitationBloc>().add(
                            AcceptOrganizationInvitationRequested(
                              invitation.token,
                            ),
                          ),
                    child: isAcceptingThis
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }
}
