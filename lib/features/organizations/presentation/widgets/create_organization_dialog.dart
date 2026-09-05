import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Pide el nombre de la organizacion a crear.
///
/// Devuelve el nombre ya normalizado, o `null` si el usuario cancelo. El
/// dialogo no conoce blocs: quien lo abre decide que hacer con el nombre, asi
/// no depende del scope de providers de la pagina.
Future<String?> showCreateOrganizationDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _CreateOrganizationDialog(),
  );
}

class _CreateOrganizationDialog extends StatefulWidget {
  const _CreateOrganizationDialog();

  @override
  State<_CreateOrganizationDialog> createState() =>
      _CreateOrganizationDialogState();
}

class _CreateOrganizationDialogState extends State<_CreateOrganizationDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Crear organizacion'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seras el propietario (OWNER) de la organizacion que crees.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Hook Sistemas',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'El nombre es obligatorio.';
                }

                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Crear')),
      ],
    );
  }
}
