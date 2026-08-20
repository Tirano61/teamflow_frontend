import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../applications/domain/entities/application.dart';
import '../../../applications/presentation/bloc/application_bloc.dart';
import '../../../applications/presentation/bloc/application_event.dart';
import '../../../applications/presentation/bloc/application_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../indicators/domain/entities/indicator.dart';
import '../../../indicators/presentation/bloc/indicator_bloc.dart';
import '../../../indicators/presentation/bloc/indicator_event.dart';
import '../../../indicators/presentation/bloc/indicator_state.dart';
import '../../../tags/domain/entities/tag.dart';
import '../../../tags/presentation/bloc/tag_bloc.dart';
import '../../../tags/presentation/bloc/tag_event.dart';
import '../../../tags/presentation/bloc/tag_state.dart';

enum CatalogAdminTab { applications, indicators, tags }

class CatalogAdminPage extends StatefulWidget {
  const CatalogAdminPage({
    this.initialTab = CatalogAdminTab.applications,
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

  String? _selectedApplicationId;
  String? _selectedIndicatorId;
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
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isDeveloper {
    final user = context.read<AuthBloc>().state.session?.user;
    return user?.isDeveloper ?? false;
  }

  void _refreshCatalogs() {
    final includeInactive = _isDeveloper;
    context.read<ApplicationBloc>().add(
      LoadApplicationsEvent(includeInactive: includeInactive),
    );
    context.read<IndicatorBloc>().add(
      LoadIndicatorsEvent(includeInactive: includeInactive),
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
        title: const Text('Administración de catálogos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aplicaciones'),
            Tab(text: 'Indicadores'),
            Tab(text: 'Tags'),
          ],
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ApplicationBloc, ApplicationState>(
            listener: (context, state) {
              if (state.status == ApplicationStatus.error &&
                  state.errorMessage.trim().isNotEmpty) {
                _showMessage(state.errorMessage);
              }
            },
          ),
          BlocListener<IndicatorBloc, IndicatorState>(
            listener: (context, state) {
              if (state.status == IndicatorStatus.error &&
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
                    _buildApplicationsTab(compact: compact),
                    _buildIndicatorsTab(compact: compact),
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
      CatalogAdminTab.applications => 'Buscar aplicaciones...',
      CatalogAdminTab.indicators => 'Buscar indicadores...',
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
        Text('Catálogo', style: Theme.of(context).textTheme.titleSmall),
        const Spacer(),
        if (_isDeveloper)
          ElevatedButton.icon(
            onPressed: () {
              switch (tab) {
                case CatalogAdminTab.applications:
                  _openApplicationDialog();
                  break;
                case CatalogAdminTab.indicators:
                  _openIndicatorDialog();
                  break;
                case CatalogAdminTab.tags:
                  _openTagDialog();
                  break;
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(
              switch (tab) {
                CatalogAdminTab.applications => 'Nueva aplicación',
                CatalogAdminTab.indicators => 'Nuevo indicador',
                CatalogAdminTab.tags => 'Nuevo tag',
              },
            ),
          ),
      ],
    );
  }

  Widget _buildApplicationsTab({required bool compact}) {
    return BlocBuilder<ApplicationBloc, ApplicationState>(
      builder: (context, appState) {
        final query = _searchController.text.trim().toLowerCase();
        final items = appState.applications
            .where((item) => item.name.toLowerCase().contains(query))
            .toList(growable: false)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (_selectedApplicationId != null &&
            !items.any((item) => item.id == _selectedApplicationId)) {
          _selectedApplicationId = null;
        }

        final selected = items
            .where((item) => item.id == _selectedApplicationId)
            .cast<Application?>()
            .firstWhere((item) => item != null, orElse: () => null);

        if (appState.status == ApplicationStatus.loading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (items.isEmpty) {
          return _EmptyState(
            message: 'Todavia no hay aplicaciones.',
            showCreate: _isDeveloper,
            onCreate: _openApplicationDialog,
          );
        }

        return Column(
          children: [
            Expanded(
              child: _buildEntityList<Application>(
                compact: compact,
                items: items,
                titleBuilder: (item) => item.name,
                subtitleBuilder: (item) {
                  final parts = <String>[];
                  final description = item.description?.trim() ?? '';
                  if (description.isNotEmpty) {
                    parts.add(description);
                  }
                  if (!item.active) {
                    parts.add('Inactiva');
                  }
                  return parts.join(' · ');
                },
                selectedId: _selectedApplicationId,
                idBuilder: (item) => item.id,
                onTap: (item) {
                  setState(() {
                    _selectedApplicationId = item.id;
                  });
                  final id = item.id?.trim() ?? '';
                  if (id.isNotEmpty) {
                    context.read<ApplicationBloc>().add(
                      LoadApplicationIndicatorsEvent(id),
                    );
                  }
                },
                actionsBuilder: _isDeveloper
                    ? (item) => _RowActions(
                          onEdit: () => _openApplicationDialog(item),
                          onDelete: () => _confirmSetApplicationActive(
                            item,
                            false,
                          ),
                          onRestore: !item.active
                              ? () => _confirmSetApplicationActive(item, true)
                              : null,
                        )
                    : null,
              ),
            ),
            if (selected != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildApplicationRelationsCard(selected, appState),
            ],
          ],
        );
      },
    );
  }

  Widget _buildApplicationRelationsCard(
    Application selected,
    ApplicationState appState,
  ) {
    final selectedId = selected.id?.trim() ?? '';
    final related = appState.selectedApplicationIndicators;
    final allIndicators = context.read<IndicatorBloc>().state.indicators;
    final relatedIds = related
        .map((item) => item.id?.trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet();

    final availableIndicators = allIndicators
        .where((item) {
          final id = item.id?.trim() ?? '';
          return id.isNotEmpty && !relatedIds.contains(id) && item.active;
        })
        .toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return _DetailCard(
      title: 'Indicadores asociados',
      trailing: _isDeveloper
          ? TextButton.icon(
              onPressed: selectedId.isEmpty || availableIndicators.isEmpty
                  ? null
                  : () => _openAssociateIndicatorDialog(
                        applicationId: selectedId,
                        options: availableIndicators,
                      ),
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Asociar indicador'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (appState.isLoadingApplicationIndicators)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
          if (related.isEmpty)
            Text(
              'Sin indicadores asociados.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: related.map((item) {
                final name = item.name.trim();
                final label = name.isEmpty ? 'Indicador sin nombre' : name;
                final id = item.id?.trim() ?? '';
                return InputChip(
                  label: Text(label),
                  onDeleted: !_isDeveloper || id.isEmpty
                      ? null
                      : () => context.read<ApplicationBloc>().add(
                            RemoveAssociatedIndicatorEvent(
                              applicationId: selectedId,
                              indicatorId: id,
                            ),
                          ),
                );
              }).toList(growable: false),
            ),
          if (_isDeveloper && appState.isUpdatingApplicationIndicators)
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

  Widget _buildIndicatorsTab({required bool compact}) {
    return BlocBuilder<IndicatorBloc, IndicatorState>(
      builder: (context, indicatorState) {
        final query = _searchController.text.trim().toLowerCase();
        final items = indicatorState.indicators
            .where((item) => item.name.toLowerCase().contains(query))
            .toList(growable: false)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (_selectedIndicatorId != null &&
            !items.any((item) => item.id == _selectedIndicatorId)) {
          _selectedIndicatorId = null;
        }

        final selected = items
            .where((item) => item.id == _selectedIndicatorId)
            .cast<Indicator?>()
            .firstWhere((item) => item != null, orElse: () => null);

        if (indicatorState.status == IndicatorStatus.loading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (items.isEmpty) {
          return _EmptyState(
            message: 'Todavia no hay indicadores.',
            showCreate: _isDeveloper,
            onCreate: _openIndicatorDialog,
          );
        }

        return Column(
          children: [
            Expanded(
              child: _buildEntityList<Indicator>(
                compact: compact,
                items: items,
                titleBuilder: (item) => item.name,
                subtitleBuilder: (item) {
                  final parts = <String>[];
                  final description = item.description?.trim() ?? '';
                  if (description.isNotEmpty) {
                    parts.add(description);
                  }
                  if (!item.active) {
                    parts.add('Inactivo');
                  }
                  return parts.join(' · ');
                },
                selectedId: _selectedIndicatorId,
                idBuilder: (item) => item.id,
                onTap: (item) {
                  setState(() {
                    _selectedIndicatorId = item.id;
                  });
                  final id = item.id?.trim() ?? '';
                  if (id.isNotEmpty) {
                    context.read<IndicatorBloc>().add(
                      LoadIndicatorApplicationsEvent(id),
                    );
                  }
                },
                actionsBuilder: _isDeveloper
                    ? (item) => _RowActions(
                          onEdit: () => _openIndicatorDialog(item),
                          onDelete: () => _confirmSetIndicatorActive(
                            item,
                            false,
                          ),
                          onRestore: !item.active
                              ? () => _confirmSetIndicatorActive(item, true)
                              : null,
                        )
                    : null,
              ),
            ),
            if (selected != null) ...[
              const SizedBox(height: AppSpacing.md),
              _buildIndicatorRelationsCard(indicatorState),
            ],
          ],
        );
      },
    );
  }

  Widget _buildIndicatorRelationsCard(IndicatorState indicatorState) {
    final relatedApps = indicatorState.selectedIndicatorApplications;

    return _DetailCard(
      title: 'Aplicaciones asociadas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (indicatorState.isLoadingIndicatorApplications)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
          if (relatedApps.isEmpty)
            Text(
              'Sin aplicaciones asociadas.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: relatedApps.map((item) {
                final name = item.name.trim();
                return Chip(
                  label: Text(name.isEmpty ? 'Aplicación sin nombre' : name),
                );
              }).toList(growable: false),
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
            message: 'Todavia no hay tags.',
            showCreate: _isDeveloper,
            onCreate: _openTagDialog,
          );
        }

        return _buildEntityList<Tag>(
          compact: compact,
          items: items,
          titleBuilder: (item) => item.name,
          subtitleBuilder: (item) => item.active ? 'Activo' : 'Inactivo',
          selectedId: _selectedTagId,
          idBuilder: (item) => item.id,
          onTap: (item) {
            setState(() {
              _selectedTagId = item.id;
            });
          },
          actionsBuilder: _isDeveloper
              ? (item) => _RowActions(
                    onEdit: () => _openTagDialog(item),
                    onDelete: () => _confirmSetTagActive(item, false),
                    onRestore: !item.active
                        ? () => _confirmSetTagActive(item, true)
                        : null,
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
            title: Text(
              _displayName(titleBuilder(item)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Future<void> _openApplicationDialog([Application? initial]) async {
    if (!_isDeveloper) {
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
              title: Text(initial == null ? 'Nueva aplicación' : 'Editar aplicación'),
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

    final entity = Application(
      id: initial?.id,
      name: savedName,
      description: savedDescription,
      active: initial?.active ?? true,
    );

    final bloc = context.read<ApplicationBloc>();
    if (initial == null) {
      bloc.add(CreateApplicationEvent(entity));
    } else {
      bloc.add(UpdateApplicationEvent(entity));
    }
    bloc.add(LoadApplicationsEvent(includeInactive: _isDeveloper));
  }

  Future<void> _openIndicatorDialog([Indicator? initial]) async {
    if (!_isDeveloper) {
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
              title: Text(initial == null ? 'Nuevo indicador' : 'Editar indicador'),
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

    final entity = Indicator(
      id: initial?.id,
      name: savedName,
      description: savedDescription,
      active: initial?.active ?? true,
    );

    final bloc = context.read<IndicatorBloc>();
    if (initial == null) {
      bloc.add(CreateIndicatorEvent(entity));
    } else {
      bloc.add(UpdateIndicatorEvent(entity));
    }
    bloc.add(LoadIndicatorsEvent(includeInactive: _isDeveloper));
  }

  Future<void> _openTagDialog([Tag? initial]) async {
    if (!_isDeveloper) {
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
    bloc.add(LoadTagsEvent(includeInactive: _isDeveloper));
  }

  Future<void> _openAssociateIndicatorDialog({
    required String applicationId,
    required List<Indicator> options,
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
                  final name = item.name.toLowerCase();
                  return query.isEmpty || name.contains(query);
                })
                .toList(growable: false);

            return AlertDialog(
              title: const Text('Asociar indicador'),
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
                      decoration: const InputDecoration(
                        hintText: 'Buscar indicador...',
                        prefixIcon: Icon(Icons.search_rounded),
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
                                final id = item.id?.trim() ?? '';
                                final isSelected = id.isNotEmpty && id == selectedId;
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
                                  title: Text(_displayName(item.name)),
                                  subtitle: item.description?.trim().isNotEmpty == true
                                      ? Text(item.description!.trim())
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

    context.read<ApplicationBloc>().add(
      AssociateIndicatorEvent(
        applicationId: applicationId,
        indicatorId: picked,
      ),
    );
  }

  Future<void> _confirmSetApplicationActive(Application item, bool active) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) {
      return;
    }

    final accepted = await _confirm(
      active ? '¿Reactivar "${item.name}"?' : '¿Eliminar "${item.name}"?',
    );
    if (accepted != true || !mounted) {
      return;
    }

    context.read<ApplicationBloc>().add(
      SetApplicationActiveEvent(id: id, active: active),
    );
    context.read<ApplicationBloc>().add(
      LoadApplicationsEvent(includeInactive: _isDeveloper),
    );
  }

  Future<void> _confirmSetIndicatorActive(Indicator item, bool active) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) {
      return;
    }

    final accepted = await _confirm(
      active ? '¿Reactivar "${item.name}"?' : '¿Eliminar "${item.name}"?',
    );
    if (accepted != true || !mounted) {
      return;
    }

    context.read<IndicatorBloc>().add(
      SetIndicatorActiveEvent(id: id, active: active),
    );
    context.read<IndicatorBloc>().add(
      LoadIndicatorsEvent(includeInactive: _isDeveloper),
    );
  }

  Future<void> _confirmSetTagActive(Tag item, bool active) async {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) {
      return;
    }

    final accepted = await _confirm(
      active ? '¿Reactivar "${item.name}"?' : '¿Eliminar "${item.name}"?',
    );
    if (accepted != true || !mounted) {
      return;
    }

    context.read<TagBloc>().add(SetTagActiveEvent(id: id, active: active));
    context.read<TagBloc>().add(LoadTagsEvent(includeInactive: _isDeveloper));
  }

  Future<bool?> _confirm(String title) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
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

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.onEdit,
    required this.onDelete,
    this.onRestore,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
          return;
        }
        if (value == 'delete') {
          onDelete();
          return;
        }
        if (value == 'restore' && onRestore != null) {
          onRestore!();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
        const PopupMenuItem<String>(value: 'delete', child: Text('Eliminar')),
        if (onRestore != null)
          const PopupMenuItem<String>(
            value: 'restore',
            child: Text('Reactivar'),
          ),
      ],
    );
  }
}
