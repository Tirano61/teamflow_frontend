import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/organization_deletion_bloc.dart';
import '../bloc/organization_deletion_event.dart';
import '../bloc/organization_deletion_state.dart';

/// `Eliminar organizacion` de la Zona de peligro (solo OWNER).
///
/// Es solo el punto de entrada: muestra la advertencia y abre el flujo, que
/// avanza segun `OrganizationDeletionBloc`. Ni este widget ni los dialogos
/// conocen el `organizationId`, hacen HTTP o tocan `OrganizationContext`.
///
/// Requiere un `OrganizationDeletionBloc` y un `AuthBloc` en el arbol.
class DeleteOrganizationTile extends StatelessWidget {
  const DeleteOrganizationTile({super.key, required this.organizationName});

  /// Nombre real de la organizacion activa (nunca el slug). Es el texto que el
  /// OWNER tiene que escribir para confirmar.
  final String organizationName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = context
        .select<OrganizationDeletionBloc, OrganizationDeletionStatus>(
          (bloc) => bloc.state.status,
        );
    final isRefreshingContext = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.isUserContextLoading,
    );

    final name = organizationName.trim();
    // Despues del 204 (o de un resultado incierto) la organizacion la vuelve a
    // resolver `/me/context`: hasta entonces no se puede iniciar otro flujo.
    final isRefreshing =
        status == OrganizationDeletionStatus.deleted ||
        (status == OrganizationDeletionStatus.aborted && isRefreshingContext);
    final isEnabled = name.isNotEmpty && !isRefreshing;

    return ListTile(
      enabled: isEnabled,
      leading: Icon(Icons.delete_forever_outlined, color: colorScheme.error),
      title: Text(
        'Eliminar organizacion',
        style: TextStyle(color: isEnabled ? colorScheme.error : null),
      ),
      subtitle: Text(
        isRefreshing
            ? 'Actualizando tus organizaciones...'
            : 'Elimina de forma permanente la organizacion y todos sus datos '
                  'para todos sus miembros. Requiere un codigo enviado a tu '
                  'email.',
      ),
      trailing: isRefreshing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: isEnabled ? () => _startFlow(context, name) : null,
    );
  }

  Future<void> _startFlow(BuildContext context, String name) async {
    final bloc = context.read<OrganizationDeletionBloc>();
    final email = context.read<AuthBloc>().state.userContext?.user.email ?? '';

    // Primera advertencia: todavia no se llama al backend.
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteOrganizationWarningDialog(organizationName: name),
    );

    if (proceed != true || !context.mounted) {
      return;
    }

    // Un flujo anterior cerrado sin terminar (por ejemplo, un resultado ya
    // informado) no debe arrastrarse al nuevo.
    bloc.add(const OrganizationDeletionCancelled());

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider<OrganizationDeletionBloc>.value(
        value: bloc,
        child: _DeleteOrganizationFlowDialog(
          organizationName: name,
          email: email.trim(),
        ),
      ),
    );
  }
}

/// Primera confirmacion: que se elimina y que no.
class _DeleteOrganizationWarningDialog extends StatelessWidget {
  const _DeleteOrganizationWarningDialog({required this.organizationName});

  final String organizationName;

  static const List<String> _deletedItems = [
    'Miembros y membresias de la organizacion',
    'Invitaciones',
    'Modulos de trabajo, componentes y tags',
    'Discusiones y sus mensajes',
    'Archivos adjuntos',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      scrollable: true,
      title: Text('Eliminar $organizationName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vas a eliminar $organizationName de forma permanente. No se puede '
            'deshacer ni recuperar.',
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Se eliminara, entre otros:'),
          const SizedBox(height: AppSpacing.xs),
          for (final item in _deletedItems)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Las cuentas de usuario no se eliminan: tus miembros conservan su '
            'cuenta y sus otras organizaciones.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Para continuar tendras que confirmar el nombre y un codigo que '
            'enviaremos a tu email.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

/// Flujo guiado por `OrganizationDeletionBloc`: nombre -> codigo ->
/// confirmacion final -> eliminacion.
///
/// El paso visible sale del estado del bloc; aca solo viven los textos que el
/// usuario esta escribiendo. Mientras hay un request en curso, o despues del
/// 204, el dialogo no se puede cerrar.
class _DeleteOrganizationFlowDialog extends StatefulWidget {
  const _DeleteOrganizationFlowDialog({
    required this.organizationName,
    required this.email,
  });

  final String organizationName;

  /// Email del usuario autenticado segun `/me/context`. Puede estar vacio.
  final String email;

  @override
  State<_DeleteOrganizationFlowDialog> createState() =>
      _DeleteOrganizationFlowDialogState();
}

class _DeleteOrganizationFlowDialogState
    extends State<_DeleteOrganizationFlowDialog> {
  static const int _codeLength = 6;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// La comparacion es exacta contra el nombre mostrado.
  bool get _nameMatches => _nameController.text == widget.organizationName;

  bool get _codeIsComplete => _codeController.text.length == _codeLength;

  OrganizationDeletionBloc get _bloc =>
      context.read<OrganizationDeletionBloc>();

  void _close() {
    if (!_bloc.state.canCancel) {
      return;
    }

    _bloc.add(const OrganizationDeletionCancelled());
    Navigator.of(context).pop();
  }

  void _onStateChanged(BuildContext context, OrganizationDeletionState state) {
    // Codigo nuevo: el texto ingresado era del anterior.
    _codeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isRefreshingContext = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.isUserContextLoading,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _close();
        }
      },
      child: BlocConsumer<OrganizationDeletionBloc, OrganizationDeletionState>(
        listenWhen: (previous, current) =>
            previous.verification?.verificationId !=
            current.verification?.verificationId,
        listener: _onStateChanged,
        builder: (context, state) {
          switch (state.status) {
            case OrganizationDeletionStatus.idle:
              return _buildNameStep(state);
            case OrganizationDeletionStatus.requestingCode:
              return state.verification == null
                  ? _buildNameStep(state)
                  : _buildCodeStep(state);
            case OrganizationDeletionStatus.awaitingCode:
            case OrganizationDeletionStatus.verifyingCode:
              return _buildCodeStep(state);
            case OrganizationDeletionStatus.verified:
            case OrganizationDeletionStatus.deleting:
              return _buildFinalStep(state);
            case OrganizationDeletionStatus.deleted:
              return _buildDeletedStep();
            case OrganizationDeletionStatus.aborted:
              return _buildAbortedStep(
                state,
                isRefreshingContext: isRefreshingContext,
              );
          }
        },
      ),
    );
  }

  /// Confirmacion escribiendo el nombre exacto. Recien aca se pide el codigo.
  Widget _buildNameStep(OrganizationDeletionState state) {
    final isRequesting =
        state.status == OrganizationDeletionStatus.requestingCode;
    final name = widget.organizationName;

    return AlertDialog(
      scrollable: true,
      title: const Text('Confirma el nombre'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Escribe "$name" para continuar.'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _nameController,
            autofocus: true,
            enabled: !isRequesting,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Nombre de la organizacion',
              hintText: name,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          const _HintText(
            'Al continuar enviaremos un codigo de 6 digitos a tu email.',
          ),
          _ErrorText(state.requestErrorMessage),
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.canCancel ? _close : null,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _nameMatches && !isRequesting
              ? () => _bloc.add(const OrganizationDeletionCodeRequested())
              : null,
          child: isRequesting
              ? const _ButtonProgress()
              : const Text('Enviar codigo'),
        ),
      ],
    );
  }

  /// Ingreso del codigo. Verificar es siempre una accion explicita.
  Widget _buildCodeStep(OrganizationDeletionState state) {
    final verification = state.verification;
    final isVerifying =
        state.status == OrganizationDeletionStatus.verifyingCode;
    final isResending =
        state.status == OrganizationDeletionStatus.requestingCode;
    final canResendNow =
        state.canResend &&
        state.status == OrganizationDeletionStatus.awaitingCode;
    final recipient = widget.email.isEmpty ? 'tu email' : widget.email;

    return AlertDialog(
      scrollable: true,
      title: const Text('Ingresa el codigo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enviamos un codigo de 6 digitos a $recipient.'),
          const SizedBox(height: AppSpacing.xs),
          _HintText(
            verification == null
                ? 'Puede tardar unos minutos en llegar.'
                : 'Puede tardar unos minutos en llegar. Vence a las '
                      '${_formatTime(verification.expiresAt)}.',
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _codeController,
            autofocus: true,
            enabled: state.canSubmitCode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: _codeLength,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_codeLength),
            ],
            decoration: const InputDecoration(
              labelText: 'Codigo de seguridad',
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          _ErrorText(state.verifyErrorMessage),
          _ErrorText(state.requestErrorMessage),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: canResendNow
                  ? () => _bloc.add(const OrganizationDeletionCodeRequested())
                  : null,
              icon: isResending
                  ? const _ButtonProgress()
                  : const Icon(Icons.refresh_rounded),
              label: const Text('Enviar un nuevo codigo'),
            ),
          ),
          if (!state.canResend && verification != null)
            _HintText(
              'Podras pedir un nuevo codigo a partir de las '
              '${_formatTime(verification.resendAvailableAt, withSeconds: true)}.',
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.canCancel ? _close : null,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: state.canSubmitCode && _codeIsComplete
              ? () => _bloc.add(
                  OrganizationDeletionCodeSubmitted(_codeController.text),
                )
              : null,
          child: isVerifying
              ? const _ButtonProgress()
              : const Text('Verificar codigo'),
        ),
      ],
    );
  }

  /// Ultima confirmacion. Solo este boton ejecuta el `DELETE`.
  Widget _buildFinalStep(OrganizationDeletionState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDeleting = state.status == OrganizationDeletionStatus.deleting;
    final name = widget.organizationName;

    return AlertDialog(
      scrollable: true,
      title: Text('Eliminar $name definitivamente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Codigo verificado.'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Esta accion no se puede deshacer. $name y todos sus datos se '
            'eliminaran para todos sus miembros.',
          ),
          _ErrorText(state.deleteErrorMessage),
          if (isDeleting) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
            const _HintText('Eliminando la organizacion...'),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.canCancel ? _close : null,
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: isDeleting
              ? null
              : () => _bloc.add(const OrganizationDeletionConfirmed()),
          child: const Text('Eliminar definitivamente'),
        ),
      ],
    );
  }

  /// 204 recibido. El cierre lo hace el reinicio central de la navegacion
  /// cuando `/me/context` deja de incluir la organizacion.
  Widget _buildDeletedStep() {
    return AlertDialog(
      title: const Text('Organizacion eliminada'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.organizationName} se elimino definitivamente.'),
          const SizedBox(height: AppSpacing.md),
          const _RefreshingContextRow(),
        ],
      ),
    );
  }

  /// El flujo no puede seguir: 403 en algun paso o resultado del `DELETE` sin
  /// confirmar. La pagina ya pidio recargar `/me/context`.
  Widget _buildAbortedStep(
    OrganizationDeletionState state, {
    required bool isRefreshingContext,
  }) {
    final message = state.abortMessage.trim();

    return AlertDialog(
      scrollable: true,
      title: Text(
        state.isDeleteResultUnknown
            ? 'Resultado sin confirmar'
            : 'No se pudo continuar',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.isEmpty
                ? 'No se pudo completar la eliminacion de la organizacion.'
                : message,
          ),
          if (isRefreshingContext) ...[
            const SizedBox(height: AppSpacing.md),
            const _RefreshingContextRow(),
          ],
        ],
      ),
      actions: [TextButton(onPressed: _close, child: const Text('Cerrar'))],
    );
  }
}

class _RefreshingContextRow extends StatelessWidget {
  const _RefreshingContextRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(child: Text('Actualizando tus organizaciones...')),
      ],
    );
  }
}

class _ButtonProgress extends StatelessWidget {
  const _ButtonProgress();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Error del paso actual. No ocupa lugar si no hay mensaje.
class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final text = message.trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

/// Hora local `HH:mm` (o `HH:mm:ss`) de un instante del backend.
String _formatTime(DateTime value, {bool withSeconds = false}) {
  final local = value.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  if (!withSeconds) {
    return '$hh:$mm';
  }

  final ss = local.second.toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}
