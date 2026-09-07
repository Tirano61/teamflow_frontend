import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../users/domain/entities/user_search_result.dart';
import '../../domain/entities/organization_invitation_role.dart';
import '../bloc/organization_invitation_bloc.dart';
import '../bloc/organization_invitation_event.dart';
import '../bloc/organization_invitation_state.dart';

/// Flujo de invitacion a la organizacion activa.
///
/// Dos pasos sobre el mismo `OrganizationInvitationBloc`: buscar y elegir un
/// usuario registrado, y despues elegir rol y enviar. La organizacion no se
/// recibe por parametro: la resuelve el datasource contra `OrganizationContext`
/// en cada request.
///
/// Al enviar bien, la pantalla se cierra devolviendo el nombre (o email) del
/// destinatario: la confirmacion la muestra quien abrio el flujo, porque esta
/// pantalla ya no esta en el arbol.
class InviteMemberPage extends StatefulWidget {
  const InviteMemberPage({super.key});

  @override
  State<InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends State<InviteMemberPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    context.read<OrganizationInvitationBloc>().add(
      InvitationUserSearchQueryChanged(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitar miembro')),
      body: MultiBlocListener(
        listeners: [
          // El buscador se vacia cuando cambia el destinatario: el texto
          // escrito no sobrevive a la seleccion.
          BlocListener<OrganizationInvitationBloc, OrganizationInvitationState>(
            listenWhen: (previous, current) =>
                previous.selectedUser?.id != current.selectedUser?.id,
            listener: (context, state) => _searchController.clear(),
          ),
          BlocListener<OrganizationInvitationBloc, OrganizationInvitationState>(
            listenWhen: (previous, current) =>
                previous.createStatus != current.createStatus,
            listener: (context, state) {
              if (state.createStatus != CreateInvitationStatus.success) {
                return;
              }

              final recipient = state.selectedUser;
              Navigator.of(context).pop(recipient?.displayName ?? '');
            },
          ),
        ],
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child:
                BlocBuilder<
                  OrganizationInvitationBloc,
                  OrganizationInvitationState
                >(
                  builder: (context, state) {
                    if (state.hasRecipient) {
                      return _InvitationSummaryStep(state: state);
                    }

                    return _UserSearchStep(
                      state: state,
                      controller: _searchController,
                      onQueryChanged: _onQueryChanged,
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }
}

/// Paso 1: buscar y elegir el destinatario.
class _UserSearchStep extends StatelessWidget {
  const _UserSearchStep({
    required this.state,
    required this.controller,
    required this.onQueryChanged,
  });

  final OrganizationInvitationState state;
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: onQueryChanged,
                decoration: const InputDecoration(
                  labelText: 'Buscar usuario',
                  hintText: 'Nombre o email',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Solo se puede invitar a usuarios ya registrados en TeamFlow.',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(child: _UserSearchResults(state: state)),
      ],
    );
  }
}

class _UserSearchResults extends StatelessWidget {
  const _UserSearchResults({required this.state});

  final OrganizationInvitationState state;

  @override
  Widget build(BuildContext context) {
    switch (state.searchStatus) {
      case InvitationUserSearchStatus.idle:
        return _SearchHint(
          icon: Icons.person_search_outlined,
          message:
              'Escribe al menos '
              '${OrganizationInvitationBloc.minSearchQueryLength} caracteres '
              'para buscar por nombre o email.',
        );
      case InvitationUserSearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case InvitationUserSearchStatus.error:
        return _SearchHint(
          icon: Icons.error_outline_rounded,
          message: state.searchErrorMessage.trim().isEmpty
              ? 'No se pudo completar la busqueda.'
              : state.searchErrorMessage,
          onRetry: () => context.read<OrganizationInvitationBloc>().add(
            InvitationUserSearchQueryChanged(state.searchQuery),
          ),
        );
      case InvitationUserSearchStatus.success:
        if (state.searchResults.isEmpty) {
          return _SearchHint(
            icon: Icons.search_off_rounded,
            message: 'Sin resultados para "${state.searchQuery}".',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          itemCount: state.searchResults.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, index) =>
              _UserSearchResultCard(user: state.searchResults[index]),
        );
    }
  }
}

/// Resultado de la busqueda. La invitacion se envia con `user.id`: pulsar la
/// fila es el unico modo de fijar el destinatario.
class _UserSearchResultCard extends StatelessWidget {
  const _UserSearchResultCard({required this.user});

  final UserSearchResult user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = user.fullName.trim();
    final email = user.email.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: _UserAvatar(name: user.displayName),
        title: Text(
          name.isEmpty ? (email.isEmpty ? 'Usuario sin nombre' : email) : name,
          style: textTheme.titleMedium,
        ),
        subtitle: email.isEmpty ? null : Text(email),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.read<OrganizationInvitationBloc>().add(
          InvitationRecipientSelected(user),
        ),
      ),
    );
  }
}

/// Paso 2: destinatario elegido, rol y envio.
class _InvitationSummaryStep extends StatelessWidget {
  const _InvitationSummaryStep({required this.state});

  final OrganizationInvitationState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final recipient = state.selectedUser;
    if (recipient == null) {
      return const SizedBox.shrink();
    }

    final createError = state.createErrorMessage.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Se invitara a', style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          _RecipientCard(recipient: recipient, state: state),
          const SizedBox(height: AppSpacing.xl),
          Text('Rol en la organizacion', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final role in OrganizationInvitationRole.values)
                ChoiceChip(
                  label: Text(role.label),
                  selected: state.selectedRole == role,
                  onSelected: state.isSendingInvitation
                      ? null
                      : (selected) {
                          if (!selected) {
                            return;
                          }

                          context.read<OrganizationInvitationBloc>().add(
                            InvitationRoleChanged(role),
                          );
                        },
                ),
            ],
          ),
          if (createError.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _CreateInvitationError(message: createError),
          ],
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: state.canSendInvitation
                ? () => context.read<OrganizationInvitationBloc>().add(
                    const CreateOrganizationInvitationRequested(),
                  )
                : null,
            child: state.isSendingInvitation
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar invitacion'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'El usuario aparecera en Miembros cuando acepte la invitacion.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.recipient, required this.state});

  final UserSearchResult recipient;
  final OrganizationInvitationState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = recipient.fullName.trim();
    final email = recipient.email.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            _UserAvatar(name: recipient.displayName),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty
                        ? (email.isEmpty ? 'Usuario sin nombre' : email)
                        : name,
                    style: textTheme.titleMedium,
                  ),
                  if (email.isNotEmpty && email != name) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(email, style: textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: state.isSendingInvitation
                  ? null
                  : () => context.read<OrganizationInvitationBloc>().add(
                      const InvitationRecipientCleared(),
                    ),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateInvitationError extends StatelessWidget {
  const _CreateInvitationError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: theme.colorScheme.error,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({required this.icon, required this.message, this.onRetry});

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name});

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
