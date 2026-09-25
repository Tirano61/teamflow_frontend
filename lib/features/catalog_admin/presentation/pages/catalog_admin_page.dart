import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../work_modules/domain/entities/work_module.dart';
import '../../../work_modules/presentation/bloc/work_module_bloc.dart';
import '../../../work_modules/presentation/bloc/work_module_event.dart';
import '../../../work_modules/presentation/bloc/work_module_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../memberships/domain/entities/membership_role.dart';
import '../../../components/domain/entities/component.dart';
import '../../../components/presentation/bloc/component_bloc.dart';
import '../../../components/presentation/bloc/component_event.dart';
import '../../../components/presentation/bloc/component_state.dart';
import '../../../tags/domain/entities/tag.dart';
import '../../../tags/presentation/bloc/tag_bloc.dart';
import '../../../tags/presentation/bloc/tag_event.dart';
import '../../../tags/presentation/bloc/tag_state.dart';

enum CatalogAdminTab { workModules, components, tags }

/// Administracion de los catalogos de la organizacion activa: Modulos de
/// trabajo, Componentes y Tags, y la relacion ManyToMany Modulo <-> Componente.
///
/// Los permisos se deciden con el rol de membresia en la organizacion activa
/// (OWNER/ADMIN), nunca con el rol global `developer`. Es control visual: el
/// backend responde 403 en cualquier escritura si el rol no alcanza. Con otro
/// rol la pantalla queda en modo consulta.
///
/// No guarda ningun `organizationId`: los datasources lo resuelven desde
/// `OrganizationContext` y los blocs son factories de la ruta, que se descarta
/// al cambiar de organizacion.
class CatalogAdminPage extends StatefulWidget {
  const CatalogAdminPage({
    this.initialTab = CatalogAdminTab.workModules,
    super.key,
  });

  final CatalogAdminTab initialTab;

  @override
  State<CatalogAdminPage> createState() => _CatalogAdminPageState();
}

class _CatalogAdminPageState extends State<CatalogAdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedWorkModuleId;
  String? _selectedComponentId;
  String? _selectedTagId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CatalogAdminTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    )..addListener(_onTabChanged);

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCatalogs();
    });
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    _searchController.clear();
    // La relacion se puede modificar desde cualquiera de los dos lados: al
    // volver a un tab se recarga la seleccion para no mostrar datos viejos.
    _reloadSelectedRelations();
    if (mounted) {
      setState(() {});
    }
  }

  void _reloadSelectedRelations() {
    final tab = CatalogAdminTab.values[_tabController.index];
    switch (tab) {
      case CatalogAdminTab.workModules:
        final id = _selectedWorkModuleId?.trim() ?? '';
        if (id.isNotEmpty) {
          context.read<WorkModuleBloc>().add(LoadWorkModuleComponentsEvent(id));
        }
        break;
      case CatalogAdminTab.components:
        final id = _selectedComponentId?.trim() ?? '';
        if (id.isNotEmpty) {
          context.read<ComponentBloc>().add(LoadComponentWorkModulesEvent(id));
        }
        break;
      case CatalogAdminTab.tags:
        break;
    }
  }

  /// OWNER/ADMIN de la organizacion activa administran los catalogos.
  bool get _canManageCatalogs {
    final role = context.read<AuthBloc>().state.activeOrganization?.role ?? '';
    return MembershipRole.canManageCatalogs(role);
  }

  void _refreshCatalogs() {
    // Los inactivos solo le sirven a quien puede reactivarlos.
    final includeInactive = _canManageCatalogs;
    context.read<WorkModuleBloc>().add(
      LoadWorkModulesEvent(includeInactive: includeInactive),
    );
    context.read<ComponentBloc>().add(
      LoadComponentsEvent(includeInactive: includeInactive),
    );
    context.read<TagBloc>().add(
      LoadTagsEvent(includeInactive: includeInactive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulos, componentes y tags'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Módulos'),
            Tab(text: 'Componentes'),
            Tab(text: 'Tags'),
          ],
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<WorkModuleBloc, WorkModuleState>(
            listenWhen: (previous, current) =>
                previous.status == WorkModuleStatus.loading &&
                current.status == WorkModuleStatus.success,
            listener: (context, state) {
              // Recargar el listado limpia las relaciones del bloc; si hay un
              // modulo seleccionado se vuelven a pedir.
              final id = _selectedWorkModuleId?.trim() ?? '';
              if (id.isNotEmpty) {
                context.read<WorkModuleBloc>().add(
                  LoadWorkModuleComponentsEvent(id),
                );
              }
            },
          ),
          BlocListener<ComponentBloc, ComponentState>(
            listenWhen: (previous, current) =>
                previous.status == ComponentStatus.loading &&
                current.status == ComponentStatus.success,
            listener: (context, state) {
              final id = _selectedComponentId?.trim() ?? '';
              if (id.isNotEmpty) {
                context.read<ComponentBloc>().add(
                  LoadComponentWorkModulesEvent(id),
                );
              }
            },
          ),
          BlocListener<WorkModuleBloc, WorkModuleState>(
            listener: (context, state) {
              if (state.status == WorkModuleStatus.error &&
                  state.errorMessage.trim().isNotEmpty) {
                _showMessage(state.errorMessage);
              }
            },
          ),
          BlocListener<ComponentBloc, ComponentState>(
            listener: (context, state) {
              if (state.status == ComponentStatus.error &&
                  state.errorMessage.trim().isNotEmpty) {
                _showMessage(state.errorMessage);
              }
            },
          ),
          BlocListener<TagBloc, TagState>(
            listener: (context, state) {
              if (state.status == TagStatus.error &&
                  state.errorMessage.trim().isNotEmpty) {
                _showMessage(state.errorMessage);
              }
            },
          ),
        ],
        child: Padding(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            children: [
              _buildSearchField(),
              const SizedBox(height: AppSpacing.md),
              _buildTopActions(),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWorkModulesTab(compact: compact),
                    _buildComponentsTab(compact: compact),
                    _buildTagsTab(compact: compact),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final tab = CatalogAdminTab.values[_tabController.index];
    final hint = switch (tab) {
      CatalogAdminTab.workModules => 'Buscar módulos...',
      CatalogAdminTab.components => 'Buscar componentes...',
      CatalogAdminTab.tags => 'Buscar tags...',
    };

    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.trim().isEmpty
            ? null
            : IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }

  Widget _buildTopActions() {
    final tab = CatalogAdminTab.values[_tabController.index];

    return Row(
      children: [
        Expanded(
          child: Text(
            switch (tab) {
              CatalogAdminTab.workModules =>
                'Seleccioná un módulo para ver sus componentes.',
              CatalogAdminTab.components =>
                'Seleccioná un componente para ver en qué módulos participa.',
              CatalogAdminTab.tags => 'Tags de la organización activa.',
            },
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (_canManageCatalogs)
          ElevatedButton.icon(
            onPressed: () {
              switch (tab) {
                case CatalogAdminTab.workModules:
                  _openWorkModuleDialog();
                  break;
                case CatalogAdminTab.components:
                  _openComponentDialog();
                  break;
                case CatalogAdminTab.tags:
                  _openTagDialog();
                  break;
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(
              switch (tab) {
                CatalogAdminTab.workModules => 'Nuevo módulo',
                CatalogAdminTab.components => 'Nuevo componente',
                CatalogAdminTab.tags => 'Nuevo tag',
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWorkModulesTab({required bool compact}) {
    return BlocBuilder<WorkModuleBloc, WorkModuleState>(
      builder: (context, appState) {
        final query = _searchController.text.trim().toLowerCase();
        final items = appState.workModules
            .where((item) => item.name.toLowerCase().contains(query))
            .toList(growable: false)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (_selectedWorkModuleId != null &&
            !items.any((item) => item.id == _selectedWorkModuleId)) {
          _selectedWorkModuleId = null;
        }

        final selected = items
            .where((item) => item.id == _selectedWorkModuleId)
            .cast<WorkModule?>()
            .firstWhere((item) => item != null, orElse: () => null);

        if (appState.status == WorkModuleStatus.loading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (items.isEmpty) {
          return _EmptyState(
            message: 'Todavía no hay módulos.',
            showCreate: _canManageCatalogs,
            onCreate: _openWorkModuleDialog,
          );
        }

        return Column(
          children: [
            Expanded(
              child: _buildEntityList<WorkModule>(
                compact: compact,
                items: items,
                titleBuilder: (item) => item.name,
                activeBuilder: (item) => item.active,
                subtitleBuilder: (item) {
                  final parts = <String>[];
                  final description = item.description?.trim() ?? '';
                  if (description.isNotEmpty) {
                    parts.add(description);
                  }
                  return parts.join(' · ');
                },
                selectedId: _selectedWorkModuleId,
                idBuilder: (item) => item.id,
                onTap: (item) {
                  setState(() {
                    _selectedWorkModuleId = item.id;
                  });
                  final id = item.id?.trim() ?? '';
                  if (id.isNotEmpty) {
                    context.read<WorkModuleBloc>().add(
                      LoadWorkModuleComponentsEvent(id),
                    );
                  }
                },
                actionsBuilder: _canManageCatalogs
                    ? (item) => _RowActions(
                          active: item.active,
                          onEdit: () => _openWorkModuleDialog(item),
                          onSetActive: (active) =>
                              _confirmSetWorkModuleActive(item, active),
                        )
                    : null,
              ),
            ),
            if (selected != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildWorkModuleRelationsCard(selected, appState),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWorkModuleRelationsCard(
    WorkModule selected,
    WorkModuleState appState,
  ) {
    final selectedId = selected.id?.trim() ?? '';
    final related = appState.selectedWorkModuleComponents;
    final allComponents = context.read<ComponentBloc>().state.components;
    final relatedIds = related
        .map((item) => item.id?.trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet();

    final availableComponents = allComponents
        .where((item) {
          final id = item.id?.trim() ?? '';
          return id.isNotEmpty && !relatedIds.contains(id) && item.active;
        })
        .toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return _DetailCard(
      title: 'Componentes de "${_displayName(selected.name)}"',
      trailing: _canManageCatalogs
          ? TextButton.icon(
              onPressed: selectedId.isEmpty || availableComponents.isEmpty
                  ? null
                  : () => _openAssociateDialog<Component>(
                        title: 'Asociar componente',
                        searchHint: 'Buscar componente...',
                        options: availableComponents,
                        nameOf: (item) => item.name,
                        descriptionOf: (item) => item.description,
                        idOf: (item) => item.id,
                        onPicked: (componentId) =>
                            context.read<WorkModuleBloc>().add(
                              AssociateComponentEvent(
                                workModuleId: selectedId,
                                componentId: componentId,
                              ),
                            ),
                      ),
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Asociar componente'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (appState.isLoadingWorkModuleComponents)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
          if (related.isEmpty)
            Text(
              'Este módulo no tiene componentes activos asociados.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: related.map((item) {
                final name = item.name.trim();
                final label = name.isEmpty ? 'Componente sin nombre' : name;
                final id = item.id?.trim() ?? '';
                return InputChip(
                  label: Text(label),
                  deleteButtonTooltipMessage: 'Quitar del módulo',
                  onDeleted: !_canManageCatalogs || id.isEmpty
                      ? null
                      : () => context.read<WorkModuleBloc>().add(
                            RemoveAssociatedComponentEvent(
                              workModuleId: selectedId,
                              componentId: id,
                            ),
                          ),
                );
              }).toList(growable: false),
            ),
          if (_canManageCatalogs && appState.isUpdatingWorkModuleComponents)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Actualizando asociaciones...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComponentsTab({required bool compact}) {
    return BlocBuilder<ComponentBloc, ComponentState>(
      builder: (context, componentState) {
        final query = _searchController.text.trim().toLowerCase();
        final items = componentState.components
            .where((item) => item.name.toLowerCase().contains(query))
            .toList(growable: false)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (_selectedComponentId != null &&
            !items.any((item) => item.id == _selectedComponentId)) {
          _selectedComponentId = null;
        }

        final selected = items
            .where((item) => item.id == _selectedComponentId)
            .cast<Component?>()
            .firstWhere((item) => item != null, orElse: () => null);

        if (componentState.status == ComponentStatus.loading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (items.isEmpty) {
          return _EmptyState(
            message: 'Todavía no hay componentes.',
            showCreate: _canManageCatalogs,
            onCreate: _openComponentDialog,
          );
        }

        return Column(
          children: [
            Expanded(
              child: _buildEntityList<Component>(
                compact: compact,
                items: items,
                titleBuilder: (item) => item.name,
                activeBuilder: (item) => item.active,
                subtitleBuilder: (item) {
                  final parts = <String>[];
                  final description = item.description?.trim() ?? '';
                  if (description.isNotEmpty) {
                    parts.add(description);
                  }
                  return parts.join(' · ');
                },
                selectedId: _selectedComponentId,
                idBuilder: (item) => item.id,
                onTap: (item) {
                  setState(() {
                    _selectedComponentId = item.id;
                  });
                  final id = item.id?.trim() ?? '';
                  if (id.isNotEmpty) {
                    context.read<ComponentBloc>().add(
                      LoadComponentWorkModulesEvent(id),
                    );
                  }
                },
                actionsBuilder: _canManageCatalogs
                    ? (item) => _RowActions(
                          active: item.active,
                          onEdit: () => _openComponentDialog(item),
                          onSetActive: (active) =>
                              _confirmSetComponentActive(item, active),
                        )
                    : null,
              ),
            ),
            if (selected != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildComponentRelationsCard(selected, componentState),
            ],
          ],
        );
      },
    );
  }

  Widget _buildComponentRelationsCard(
    Component selected,
    ComponentState componentState,
  ) {
    final selectedId = selected.id?.trim() ?? '';
    final related = componentState.selectedComponentWorkModules;
    final allWorkModules = context.read<WorkModuleBloc>().state.workModules;
    final relatedIds = related
        .map((item) => item.id?.trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet();

    // Mismo criterio que desde el modulo: solo candidatos activos que todavia
    // no estan asociados.
    final availableWorkModules = allWorkModules
        .where((item) {
          final id = item.id?.trim() ?? '';
          return id.isNotEmpty && !relatedIds.contains(id) && item.active;
        })
        .toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return _DetailCard(
      title: 'Módulos que usan "${_displayName(selected.name)}"',
      trailing: _canManageCatalogs
          ? TextButton.icon(
              onPressed: selectedId.isEmpty || availableWorkModules.isEmpty
                  ? null
                  : () => _openAssociateDialog<WorkModule>(
                        title: 'Asociar a un módulo',
                        searchHint: 'Buscar módulo...',
                        options: availableWorkModules,
                        nameOf: (item) => item.name,
                        descriptionOf: (item) => item.description,
                        idOf: (item) => item.id,
                        onPicked: (workModuleId) =>
                            context.read<ComponentBloc>().add(
                              AssociateWorkModuleToComponentEvent(
                                componentId: selectedId,
                                workModuleId: workModuleId,
                              ),
                            ),
                      ),
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Asociar módulo'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (componentState.isLoadingComponentWorkModules)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
          if (related.isEmpty)
            Text(
              'Este componente no participa en ningún módulo activo.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: related.map((item) {
                final name = item.name.trim();
                final label = name.isEmpty ? 'Módulo sin nombre' : name;
                final id = item.id?.trim() ?? '';
                return InputChip(
                  label: Text(label),
                  deleteButtonTooltipMessage: 'Quitar de este módulo',
                  onDeleted: !_canManageCatalogs || id.isEmpty
                      ? null
                      : () => context.read<ComponentBloc>().add(
                            RemoveWorkModuleFromComponentEvent(
                              componentId: selectedId,
                              workModuleId: id,
                            ),
                          ),
                );
              }).toList(growable: false),
            ),
          if (_canManageCatalogs &&
              componentState.isUpdatingComponentWorkModules)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Actualizando asociaciones...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagsTab({required bool compact}) {
    return BlocBuilder<TagBloc, TagState>(
      builder: (context, tagState) {
        final query = _searchController.text.trim().toLowerCase();
        final items = tagState.tags
            .where((item) => item.name.toLowerCase().contains(query))
            .toList(growable: false)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (_selectedTagId != null &&
            !items.any((item) => item.id == _selectedTagId)) {
          _selectedTagId = null;
        }

        if (tagState.status == TagStatus.loading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (items.isEmpty) {
          return _EmptyState(
            message: 'Todavía no hay tags.',
            showCreate: _canManageCatalogs,
            onCreate: _openTagDialog,
          );
        }

        return _buildEntityList<Tag>(
          compact: compact,
          items: items,
          titleBuilder: (item) => item.name,
          subtitleBuilder: (_) => '',
          activeBuilder: (item) => item.active,
          selectedId: _selectedTagId,
          idBuilder: (item) => item.id,
          onTap: (item) {
            setState(() {
              _selectedTagId = item.id;
            });
          },
          actionsBuilder: _canManageCatalogs
              ? (item) => _RowActions(
                    active: item.active,
                    onEdit: () => _openTagDialog(item),
                    onSetActive: (active) => _confirmSetTagActive(item, active),
                  )
              : null,
        );
      },
    );
  }

  Widget _buildEntityList<T>({
    required bool compact,
    required List<T> items,
    required String Function(T item) titleBuilder,
    required String Function(T item) subtitleBuilder,
    required bool Function(T item) activeBuilder,
    required String? selectedId,
    required String? Function(T item) idBuilder,
    required void Function(T item) onTap,
    required Widget Function(T item)? actionsBuilder,
  }) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idBuilder(item);
        final selected = id != null && id == selectedId;

        return Container(
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.62)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            onTap: () => onTap(item),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    _displayName(titleBuilder(item)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: activeBuilder(item)
                        ? null
                        : TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                  ),
                ),
                if (!activeBuilder(item)) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const _InactiveBadge(),
                ],
              ],
            ),
            subtitle: subtitleBuilder(item).trim().isEmpty
                ? null
                : Text(
                    subtitleBuilder(item),
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: actionsBuilder?.call(item),
          ),
        );
      },
    );
  }

  Future<void> _openWorkModuleDialog([WorkModule? initial]) async {
    if (!_canManageCatalogs) {
      return;
    }

    final nameController = TextEditingController(text: initial?.name ?? '');
    final descriptionController =
        TextEditingController(text: initial?.description ?? '');
    String? error;
    String savedName = initial?.name ?? '';
    String? savedDescription = initial?.description;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(initial == null ? 'Nuevo módulo' : 'Editar módulo'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() {
                        error = 'El nombre es obligatorio.';
                      });
                      return;
                    }

                    savedName = name;
                    savedDescription = _nullable(descriptionController.text);
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(initial == null ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (accepted != true || !mounted) {
      return;
    }

    final entity = WorkModule(
      id: initial?.id,
      name: savedName,
      description: savedDescription,
      active: initial?.active ?? true,
    );

    final bloc = context.read<WorkModuleBloc>();
    if (initial == null) {
      bloc.add(CreateWorkModuleEvent(entity));
    } else {
      bloc.add(UpdateWorkModuleEvent(entity));
    }
    bloc.add(LoadWorkModulesEvent(includeInactive: _canManageCatalogs));
  }

  Future<void> _openComponentDialog([Component? initial]) async {
    if (!_canManageCatalogs) {
      return;
    }

    final nameController = TextEditingController(text: initial?.name ?? '');
    final descriptionController =
        TextEditingController(text: initial?.description ?? '');
    String? error;
    String savedName = initial?.name ?? '';
    String? savedDescription = initial?.description;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                initial == null ? 'Nuevo componente' : 'Editar componente',
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() {
                        error = 'El nombre es obligatorio.';
                      });
                      return;
                    }

                    savedName = name;
                    savedDescription = _nullable(descriptionController.text);
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(initial == null ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (accepted != true || !mounted) {
      return;
    }

    final entity = Component(
      id: initial?.id,
      name: savedName,
      description: savedDescription,
      active: initial?.active ?? true,
    );

    final bloc = context.read<ComponentBloc>();
    if (initial == null) {
      bloc.add(CreateComponentEvent(entity));
    } else {
      bloc.add(UpdateComponentEvent(entity));
    }
    bloc.add(LoadComponentsEvent(includeInactive: _canManageCatalogs));
  }

  Future<void> _openTagDialog([Tag? initial]) async {
    if (!_canManageCatalogs) {
      return;
    }

    final nameController = TextEditingController(text: initial?.name ?? '');
    String? error;
    String savedName = initial?.name ?? '';

    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(initial == null ? 'Nuevo tag' : 'Editar tag'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setDialogState(() {
                        error = 'El nombre es obligatorio.';
                      });
                      return;
                    }

                    savedName = name;
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(initial == null ? 'Crear' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (accepted != true || !mounted) {
      return;
    }

    final tag = Tag(
      id: initial?.id,
      name: savedName,
      active: initial?.active ?? true,
    );

    final bloc = context.read<TagBloc>();
    if (initial == null) {
      bloc.add(CreateTagEvent(tag));
    } else {
      bloc.add(UpdateTagEvent(tag));
    }
    bloc.add(LoadTagsEvent(includeInactive: _canManageCatalogs));
  }

  /// Selector de un recurso a asociar. Sirve para los dos lados de la
  /// relacion Modulo <-> Componente; la operacion la decide [onPicked].
  Future<void> _openAssociateDialog<T>({
    required String title,
    required String searchHint,
    required List<T> options,
    required String Function(T item) nameOf,
    required String? Function(T item) descriptionOf,
    required String? Function(T item) idOf,
    required void Function(String id) onPicked,
  }) async {
    String query = '';
    String? selectedId;

    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final visible = options
                .where((item) {
                  final name = nameOf(item).toLowerCase();
                  return query.isEmpty || name.contains(query);
                })
                .toList(growable: false);

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          query = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 280,
                      child: visible.isEmpty
                          ? const Center(child: Text('No hay opciones disponibles.'))
                          : ListView.builder(
                              itemCount: visible.length,
                              itemBuilder: (context, index) {
                                final item = visible[index];
                                final id = idOf(item)?.trim() ?? '';
                                final isSelected = id.isNotEmpty && id == selectedId;
                                final description =
                                    descriptionOf(item)?.trim() ?? '';
                                return ListTile(
                                  dense: true,
                                  onTap: id.isEmpty
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            selectedId = id;
                                          });
                                        },
                                  leading: Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                  ),
                                  title: Text(_displayName(nameOf(item))),
                                  subtitle: description.isNotEmpty
                                      ? Text(description)
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedId == null
                      ? null
                      : () => Navigator.pop(dialogContext, selectedId),
                  child: const Text('Asociar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null || picked.trim().isEmpty || !mounted) {
      return;
    }

    onPicked(picked);
  }

  Future<void> _confirmSetWorkModuleActive(WorkModule item, bool active) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) {
      return;
    }

    final accepted = await _confirmActiveChange(
      name: item.name,
      active: active,
    );
    if (accepted != true || !mounted) {
      return;
    }

    context.read<WorkModuleBloc>().add(
      SetWorkModuleActiveEvent(id: id, active: active),
    );
    context.read<WorkModuleBloc>().add(
      LoadWorkModulesEvent(includeInactive: _canManageCatalogs),
    );
  }

  Future<void> _confirmSetComponentActive(Component item, bool active) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) {
      return;
    }

    final accepted = await _confirmActiveChange(
      name: item.name,
      active: active,
    );
    if (accepted != true || !mounted) {
      return;
    }

    context.read<ComponentBloc>().add(
      SetComponentActiveEvent(id: id, active: active),
    );
    context.read<ComponentBloc>().add(
      LoadComponentsEvent(includeInactive: _canManageCatalogs),
    );
  }

  Future<void> _confirmSetTagActive(Tag item, bool active) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) {
      return;
    }

    final accepted = await _confirmActiveChange(
      name: item.name,
      active: active,
    );
    if (accepted != true || !mounted) {
      return;
    }

    context.read<TagBloc>().add(SetTagActiveEvent(id: id, active: active));
    context.read<TagBloc>().add(LoadTagsEvent(includeInactive: _canManageCatalogs));
  }

  /// Desactivar no elimina: el recurso deja de ofrecerse en los listados
  /// activos y se puede reactivar. No existe DELETE fisico en el backend.
  Future<bool?> _confirmActiveChange({
    required String name,
    required bool active,
  }) {
    final displayName = _displayName(name);
    final title = active
        ? '¿Reactivar "$displayName"?'
        : '¿Desactivar "$displayName"?';
    final message = active
        ? 'Vuelve a estar disponible en los listados activos de la '
            'organización.'
        : 'Deja de estar disponible en los listados activos de la '
            'organización. No se elimina: podés reactivarlo cuando quieras.';

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(active ? 'Reactivar' : 'Desactivar'),
            ),
          ],
        );
      },
    );
  }

  String _displayName(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? '(Sin nombre)' : trimmed;
  }

  String? _nullable(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleSmall),
              ),
              // ignore: use_null_aware_elements
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.showCreate,
    required this.onCreate,
  });

  final String message;
  final bool showCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (showCreate) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Marca visual de un recurso desactivado.
class _InactiveBadge extends StatelessWidget {
  const _InactiveBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Text(
        'Inactivo',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

/// Acciones de una fila del catalogo. Desactivar y reactivar son excluyentes
/// segun el estado actual; no hay eliminacion fisica.
class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.active,
    required this.onEdit,
    required this.onSetActive,
  });

  final bool active;
  final VoidCallback onEdit;
  final ValueChanged<bool> onSetActive;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Acciones',
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'deactivate':
            onSetActive(false);
            break;
          case 'activate':
            onSetActive(true);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
        if (active)
          const PopupMenuItem<String>(
            value: 'deactivate',
            child: Text('Desactivar'),
          )
        else
          const PopupMenuItem<String>(
            value: 'activate',
            child: Text('Reactivar'),
          ),
      ],
    );
  }
}
