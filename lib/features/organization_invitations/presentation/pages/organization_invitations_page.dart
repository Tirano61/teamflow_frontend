import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../user_context/presentation/widgets/organization_role_chip.dart';
import '../../domain/entities/invitation_status.dart';
import '../../domain/entities/organization_invitation.dart';
import '../bloc/organization_invitation_bloc.dart';
import '../bloc/organization_invitation_event.dart';
import '../bloc/organization_invitation_state.dart';

/// Invitaciones enviadas por la organizacion activa.
///
/// La organizacion no se recibe por parametro: el `OrganizationInvitationBloc`
/// que provee la ruta la resuelve contra `OrganizationContext` en cada request.
///
/// Se entra solo desde `Administrar miembros` y solo como OWNER/ADMIN; el
/// backend responde 403 igual si el rol no alcanza.
class OrganizationInvitationsPage extends StatefulWidget {
  const OrganizationInvitationsPage({super.key});

  @override
  State<OrganizationInvitationsPage> createState() =>
      _OrganizationInvitationsPageState();
}

class _OrganizationInvitationsPageState
    extends State<OrganizationInvitationsPage> {
  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  void _loadInvitations() {
    context.read<OrganizationInvitationBloc>().add(
      const LoadOrganizationInvitationsRequested(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitaciones'),
        actions: [
          IconButton(
            onPressed: _loadInvitations,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: BlocConsumer<OrganizationInvitationBloc, OrganizationInvitationState>(
        // El resultado de cancelar se avisa con un snackbar; el listado lo
        // repinta el builder con la fila ya en CANCELLED.
        listenWhen: (previous, current) =>
            previous.cancelStatus != current.cancelStatus,
        listener: (context, state) {
          switch (state.cancelStatus) {
            case CancelInvitationStatus.success:
              _showMessage(context, 'Invitacion cancelada.');
            case CancelInvitationStatus.error:
              _showMessage(
                context,
                state.cancelErrorMessage.trim().isEmpty
                    ? 'No se pudo cancelar la invitacion.'
                    : state.cancelErrorMessage,
              );
            case CancelInvitationStatus.idle:
            case CancelInvitationStatus.cancelling:
              break;
          }
        },
        builder: (context, state) {
          switch (state.listStatus) {
            case InvitationsListStatus.initial:
            case InvitationsListStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case InvitationsListStatus.error:
              return _InvitationsErrorState(
                message: state.listErrorMessage,
                onRetry: _loadInvitations,
              );
            case InvitationsListStatus.success:
              if (state.invitations.isEmpty) {
                return const _InvitationsEmptyState();
              }

              return _InvitationsList(state: state);
          }
        },
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

class _InvitationsList extends StatelessWidget {
  const _InvitationsList({required this.state});

  final OrganizationInvitationState state;

  @override
  Widget build(BuildContext context) {
    final invitations = state.invitations;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: invitations.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, index) {
            final invitation = invitations[index];

            return _InvitationCard(
              invitation: invitation,
              isCancelling: state.isCancellingInvitationId(invitation.id),
              // Mientras hay una cancelacion en curso ninguna otra fila acepta
              // pulsaciones: el bloc igual ignora la segunda.
              isCancelEnabled: !state.isCancellingInvitation,
            );
          },
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.isCancelling,
    required this.isCancelEnabled,
  });

  final OrganizationInvitation invitation;
  final bool isCancelling;
  final bool isCancelEnabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final name = invitation.recipientName;
    final email = invitation.recipientEmail;
    final createdAt = invitation.createdAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InvitationAvatar(name: name),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Invitacion sin destinatario' : name,
                        style: textTheme.titleMedium,
                      ),
                      // El nombre ya cae al email cuando no hay usuario
                      // asociado o no tiene nombre: no se repite abajo.
                      if (email.isNotEmpty && email != name) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(email, style: textTheme.bodySmall),
                      ],
                      if (invitation.invitedUser == null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Invitacion por email, sin usuario registrado '
                          'asociado.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (invitation.role.trim().isNotEmpty)
                            OrganizationRoleChip(role: invitation.role),
                          _InvitationStatusChip(status: invitation.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (createdAt != null)
              _InvitationDetailLine(
                text: 'Enviada el ${_formatDate(createdAt)}',
              ),
            ..._buildStatusDetail(invitation),
            if (invitation.isPending) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: _CancelInvitationButton(
                  invitation: invitation,
                  isCancelling: isCancelling,
                  isEnabled: isCancelEnabled,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Fecha adicional segun el estado: el vencimiento solo interesa mientras la
  /// invitacion sigue viva o si ya vencio, y la aceptacion solo si se acepto.
  List<Widget> _buildStatusDetail(OrganizationInvitation invitation) {
    final expiresAt = invitation.expiresAt;
    final acceptedAt = invitation.acceptedAt;

    switch (invitation.status) {
      case InvitationStatus.pending:
        if (expiresAt == null) {
          return const [];
        }

        return [
          _InvitationDetailLine(text: 'Vence el ${_formatDate(expiresAt)}'),
        ];
      case InvitationStatus.expired:
        if (expiresAt == null) {
          return const [];
        }

        return [
          _InvitationDetailLine(text: 'Vencio el ${_formatDate(expiresAt)}'),
        ];
      case InvitationStatus.accepted:
        if (acceptedAt == null) {
          return const [];
        }

        return [
          _InvitationDetailLine(text: 'Aceptada el ${_formatDate(acceptedAt)}'),
        ];
      case InvitationStatus.cancelled:
      case InvitationStatus.unknown:
        return const [];
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }
}

/// `Cancelar` de una invitacion pendiente.
///
/// Pide confirmacion antes de emitir el evento: la cancelacion no se deshace.
class _CancelInvitationButton extends StatelessWidget {
  const _CancelInvitationButton({
    required this.invitation,
    required this.isCancelling,
    required this.isEnabled,
  });

  final OrganizationInvitation invitation;
  final bool isCancelling;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    if (isCancelling) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return TextButton.icon(
      onPressed: isEnabled ? () => _confirmAndCancel(context) : null,
      icon: const Icon(Icons.cancel_outlined, size: 18),
      label: const Text('Cancelar'),
    );
  }

  Future<void> _confirmAndCancel(BuildContext context) async {
    final bloc = context.read<OrganizationInvitationBloc>();
    final recipient = invitation.recipientName.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar invitacion'),
        content: Text(
          recipient.isEmpty
              ? 'La invitacion dejara de estar disponible para el '
                    'destinatario.'
              : 'La invitacion de $recipient dejara de estar disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancelar invitacion'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    bloc.add(CancelOrganizationInvitationRequested(invitation.id));
  }
}

/// Estado de la invitacion. Distingue las cuatro situaciones posibles: no todas
/// las invitaciones del listado siguen activas.
class _InvitationStatusChip extends StatelessWidget {
  const _InvitationStatusChip({required this.status});

  final InvitationStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (status) {
      InvitationStatus.pending => AppColors.warning,
      InvitationStatus.accepted => AppColors.success,
      InvitationStatus.expired => AppColors.textMuted,
      InvitationStatus.cancelled => AppColors.error,
      InvitationStatus.unknown => theme.colorScheme.outline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: accent),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InvitationDetailLine extends StatelessWidget {
  const _InvitationDetailLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _InvitationAvatar extends StatelessWidget {
  const _InvitationAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Text(
        _initials(name),
        style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

class _InvitationsEmptyState extends StatelessWidget {
  const _InvitationsEmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read_outlined),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Esta organizacion todavia no envio invitaciones.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitationsErrorState extends StatelessWidget {
  const _InvitationsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detail = message.trim();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No se pudieron cargar las invitaciones.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail,
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
