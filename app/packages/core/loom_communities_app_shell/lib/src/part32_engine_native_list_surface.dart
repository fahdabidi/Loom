part of '../loom_communities_app_shell.dart';

/// Generic, tab-agnostic projection for engine-declared bindings that don't
/// need calendar semantics: a scrollable list of [EngineNativeArchetypeCard]s,
/// one per resolved binding, in tile display context.
class EngineNativeListSurface extends StatefulWidget {
  const EngineNativeListSurface({
    super.key,
    required this.experience,
    required this.actorIdentity,
    required this.tabId,
    required this.accent,
    required this.modernTheme,
    this.engine,
    this.onInstanceScopedCreate,
    this.rolesForInstance,
  });

  final LoomExperienceDefinition experience;
  final LoomActorIdentity actorIdentity;
  final String tabId;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final WorkflowEngineApi? engine;
  final EngineNativeInstanceScopedCreate? onInstanceScopedCreate;
  final EngineNativeRolesForInstance? rolesForInstance;

  @override
  State<EngineNativeListSurface> createState() =>
      _EngineNativeListSurfaceState();
}

class _EngineNativeListSurfaceState extends State<EngineNativeListSurface> {
  Future<WorkflowEngineApi>? _engineFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EngineNativeListSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDefinitions = oldWidget.experience.workflowDefinitions;
    final definitions = widget.experience.workflowDefinitions;
    final hadDefinitions = oldDefinitions != null && oldDefinitions.isNotEmpty;
    final hasDefinitions = definitions != null && definitions.isNotEmpty;
    if (!hasDefinitions) {
      _engineFuture = null;
      return;
    }
    if (!hadDefinitions ||
        oldWidget.experience.extensionId != widget.experience.extensionId ||
        oldWidget.engine != widget.engine ||
        oldWidget.actorIdentity.roleId != widget.actorIdentity.roleId ||
        oldWidget.tabId != widget.tabId) {
      _load();
    }
  }

  void _load() {
    final definitions = widget.experience.workflowDefinitions;
    if (definitions == null || definitions.isEmpty) {
      _engineFuture = null;
      return;
    }
    final extensionId = widget.experience.extensionId;
    setState(() {
      _engineFuture = widget.engine == null
          ? workflowEngineForExtensionId(extensionId)
          : Future<WorkflowEngineApi>.value(widget.engine);
    });
  }

  @override
  Widget build(BuildContext context) {
    final definitions = widget.experience.workflowDefinitions;
    if (definitions == null || definitions.isEmpty) {
      return SizedBox(
        key: ValueKey('engine-native-list-empty-${widget.tabId}'),
      );
    }
    return FutureBuilder<WorkflowEngineApi>(
      future: _engineFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            key: ValueKey('engine-native-list-error-${widget.tabId}'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load ${widget.tabId}: ${snapshot.error}'),
              TextButton(
                key: ValueKey('engine-native-list-retry-${widget.tabId}'),
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          );
        }
        if (!snapshot.hasData) {
          return SizedBox(
            key: ValueKey('engine-native-list-loading-${widget.tabId}'),
          );
        }
        final engine = snapshot.data!;
        final fanId = ActiveIdentityScope.of(
          context,
        ).resolveEngineFanId(widget.actorIdentity.fanId);
        return EngineNativeBindingDispatcher(
          engine: engine,
          definitions: definitions,
          tabId: widget.tabId,
          fanId: fanId,
          rolesForInstance:
              widget.rolesForInstance ??
              (instance, viewerFanId) => _deriveActorOrReceiverRolesForInstance(
                definitions,
                instance,
                viewerFanId,
                widget.actorIdentity.roleId,
              ),
          builder: (context, bindings, changed) {
            if (bindings.isEmpty) {
              return SizedBox(
                key: ValueKey('engine-native-list-empty-${widget.tabId}'),
              );
            }
            final tableBindingsByGroup =
                <_TableGroupKey, List<EngineNativeResolvedBinding>>{};
            for (final resolved in bindings) {
              if (resolved.binding.cardSurfaceFamily != 'table') continue;
              final key = _TableGroupKey(
                tabId: resolved.binding.tabId,
                workflowType: resolved.machine.workflowType,
              );
              (tableBindingsByGroup[key] ??= <EngineNativeResolvedBinding>[])
                  .add(resolved);
            }
            final renderedTableGroups = <_TableGroupKey>{};
            return Column(
              key: ValueKey('engine-native-list-root-${widget.tabId}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final resolved in bindings)
                  if (resolved.binding.cardSurfaceFamily == 'table') ...[
                    if (renderedTableGroups.add(
                      _TableGroupKey(
                        tabId: resolved.binding.tabId,
                        workflowType: resolved.machine.workflowType,
                      ),
                    ))
                      WorkflowTableArchetypeCard(
                        key: ValueKey(
                          _TableGroupKey(
                            tabId: resolved.binding.tabId,
                            workflowType: resolved.machine.workflowType,
                          ).widgetKey,
                        ),
                        bindings:
                            tableBindingsByGroup[_TableGroupKey(
                              tabId: resolved.binding.tabId,
                              workflowType: resolved.machine.workflowType,
                            )]!,
                        engine: engine,
                        communityExtensionId: widget.experience.extensionId,
                        fanId: fanId,
                        roleId: widget.actorIdentity.roleId,
                        accent: widget.accent,
                        modernTheme: widget.modernTheme,
                        onInstanceChanged: changed,
                        onInstanceScopedCreate: widget.onInstanceScopedCreate,
                      ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EngineNativeArchetypeCard(
                        contentKey: ValueKey(
                          'engine-native-list-item-${widget.tabId}-${resolved.instance.instanceId}-${resolved.definitionBindingIndex}',
                        ),
                        resolved: resolved,
                        engine: engine,
                        communityExtensionId: widget.experience.extensionId,
                        fanId: fanId,
                        roleId: widget.actorIdentity.roleId,
                        accent: widget.accent,
                        onInstanceChanged: changed,
                        onInstanceScopedCreate: widget.onInstanceScopedCreate,
                        modernTheme: widget.modernTheme,
                        // Notification summaries currently use the generic
                        // fallback. Render them in detail context so declared
                        // announcement body content is visible on Home while
                        // the future notificationInbox archetype remains
                        // untouched.
                        displayContext:
                            resolved.binding.cardSurfaceFamily ==
                                'notificationInbox'
                            ? 'detail'
                            : 'tile',
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }
}

enum _WorkflowTableSortDirection { none, ascending, descending }

class _TableGroupKey {
  const _TableGroupKey({required this.tabId, required this.workflowType});

  final String tabId;
  final String workflowType;

  String get widgetKey => 'engine-native-table-$tabId-$workflowType';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TableGroupKey &&
        tabId == other.tabId &&
        workflowType == other.workflowType;
  }

  @override
  int get hashCode => Object.hash(tabId, workflowType);
}

class _TableColumn {
  const _TableColumn({required this.field, required this.schema});

  final String field;
  final InstanceDataField schema;
}

class WorkflowTableArchetypeCard extends StatefulWidget {
  WorkflowTableArchetypeCard({
    super.key,
    required this.bindings,
    required this.engine,
    required this.communityExtensionId,
    required this.fanId,
    required this.roleId,
    required this.accent,
    required this.onInstanceChanged,
    this.modernTheme,
    this.onInstanceScopedCreate,
  }) : assert(bindings.isNotEmpty);

  final List<EngineNativeResolvedBinding> bindings;
  final WorkflowEngineApi engine;
  final String communityExtensionId;
  final String fanId;
  final String roleId;
  final Color accent;
  final ValueChanged<WorkflowInstance> onInstanceChanged;
  final LoomCardTheme? modernTheme;
  final EngineNativeInstanceScopedCreate? onInstanceScopedCreate;

  @override
  State<WorkflowTableArchetypeCard> createState() =>
      _WorkflowTableArchetypeCardState();
}

class _WorkflowTableArchetypeCardState
    extends State<WorkflowTableArchetypeCard> {
  String _search = '';
  String? _sortField;
  _WorkflowTableSortDirection _sortDirection = _WorkflowTableSortDirection.none;

  String get _tableGroupId =>
      '${widget.bindings.first.binding.tabId}-${widget.bindings.first.machine.workflowType}';

  LoomWorkflowStateMachine get _machine => widget.bindings.first.machine;

  List<_TableColumn> get _tileColumns {
    final columns = <_TableColumn>[];
    for (final entry in _machine.instanceDataSchema.entries) {
      final field = entry.key;
      final schema = entry.value;
      final isUnlabeledComputedField =
          schema.formula?.trim().isNotEmpty == true &&
          !(schema.labelTemplate?.trim().isNotEmpty == true);
      if (isUnlabeledComputedField) continue;
      if (schema.displayContexts != null &&
          !schema.displayContexts!.contains('tile')) {
        continue;
      }
      if (schema.displayContexts != null && schema.displayContexts!.isEmpty) {
        continue;
      }
      columns.add(_TableColumn(field: field, schema: schema));
    }
    return columns;
  }

  List<_TableColumn> get _searchColumns {
    final columns = <_TableColumn>[];
    for (final entry in _machine.instanceDataSchema.entries) {
      if (entry.value.searchable) {
        columns.add(_TableColumn(field: entry.key, schema: entry.value));
      }
    }
    return columns;
  }

  bool _matchesSearch(EngineNativeResolvedBinding binding, String query) {
    if (_searchColumns.isEmpty) return true;
    for (final column in _searchColumns) {
      final text = _valueText(binding.instance.instanceData[column.field]);
      if (text.toLowerCase().contains(query)) {
        return true;
      }
    }
    return false;
  }

  List<EngineNativeResolvedBinding> get _filteredBindings {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return widget.bindings;
    return [
      for (final binding in widget.bindings)
        if (_matchesSearch(binding, query)) binding,
    ];
  }

  int _compareValues(
    EngineNativeResolvedBinding left,
    EngineNativeResolvedBinding right,
    String field,
    InstanceDataField schema,
  ) {
    final leftValue = left.instance.instanceData[field];
    final rightValue = right.instance.instanceData[field];
    if (leftValue == null && rightValue == null) return 0;
    if (leftValue == null) return 1;
    if (rightValue == null) return -1;
    if (schema.type == 'number' && leftValue is num && rightValue is num) {
      final compare = leftValue.compareTo(rightValue);
      if (compare != 0) return compare;
    }
    return _valueText(
      leftValue,
    ).toLowerCase().compareTo(_valueText(rightValue).toLowerCase());
  }

  List<EngineNativeResolvedBinding> get _orderedBindings {
    final bindings = _filteredBindings.toList(growable: false);
    final sortField = _sortField;
    if (sortField == null ||
        _sortDirection == _WorkflowTableSortDirection.none) {
      return bindings;
    }
    final sortSchema = _machine.instanceDataSchema[sortField];
    if (sortSchema == null) return bindings;
    bindings.sort((left, right) {
      final compare = _compareValues(left, right, sortField, sortSchema);
      if (compare == 0) {
        return left.instance.instanceId.compareTo(right.instance.instanceId);
      }
      if (_sortDirection == _WorkflowTableSortDirection.ascending) {
        return compare;
      }
      return -compare;
    });
    return bindings;
  }

  int? get _sortColumnIndex {
    final field = _sortField;
    if (field == null || _sortDirection == _WorkflowTableSortDirection.none) {
      return null;
    }
    final columns = _tileColumns;
    for (var i = 0; i < columns.length; i++) {
      if (columns[i].field == field) return i;
    }
    return null;
  }

  bool _isNumeric(String type) =>
      type == 'number' || type == 'int' || type == 'double';

  String _columnLabel(_TableColumn column) {
    final template = column.schema.labelTemplate ?? '';
    if (template.isEmpty) return _humanizeFieldName(column.field);
    final label = template
        .replaceAll('{value.length}', '')
        .replaceAll('{value}', '')
        .replaceAll(RegExp(r'[:\-–—]+\s*$'), '')
        .trim();
    return label.isEmpty ? _humanizeFieldName(column.field) : label;
  }

  IconData _sortIcon(_TableColumn column) {
    if (_sortField != column.field) return Icons.unfold_more;
    return switch (_sortDirection) {
      _WorkflowTableSortDirection.ascending => Icons.arrow_downward,
      _WorkflowTableSortDirection.descending => Icons.arrow_upward,
      _WorkflowTableSortDirection.none => Icons.unfold_more,
    };
  }

  void _toggleSort(String field) {
    if (_sortField != field) {
      _sortField = field;
      _sortDirection = _WorkflowTableSortDirection.ascending;
    } else {
      switch (_sortDirection) {
        case _WorkflowTableSortDirection.none:
          _sortDirection = _WorkflowTableSortDirection.ascending;
        case _WorkflowTableSortDirection.ascending:
          _sortDirection = _WorkflowTableSortDirection.descending;
        case _WorkflowTableSortDirection.descending:
          _sortField = null;
          _sortDirection = _WorkflowTableSortDirection.none;
      }
    }
    setState(() {});
  }

  String _instanceTitle(EngineNativeResolvedBinding binding) {
    final titleText = _valueText(binding.instance.instanceData['title']);
    if (titleText.isNotEmpty) return titleText;
    return '${binding.machine.workflowType} • ${binding.instance.instanceId}';
  }

  void _openDetail(BuildContext context, EngineNativeResolvedBinding resolved) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: ValueKey(
          'workflow-table-detail-dialog-${resolved.instance.instanceId}',
        ),
        title: Text(_instanceTitle(resolved)),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: EngineNativeArchetypeCard(
              contentKey: ValueKey(
                'workflow-table-detail-card-${resolved.instance.instanceId}',
              ),
              resolved: resolved,
              engine: widget.engine,
              communityExtensionId: widget.communityExtensionId,
              fanId: widget.fanId,
              roleId: widget.roleId,
              accent: widget.accent,
              modernTheme: widget.modernTheme,
              displayContext: 'detail',
              showEditors: false,
              onInstanceChanged: widget.onInstanceChanged,
              onInstanceScopedCreate: widget.onInstanceScopedCreate,
            ),
          ),
        ),
        actions: [
          TextButton(
            key: ValueKey(
              'workflow-table-detail-close-${resolved.instance.instanceId}',
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _orderedBindings;
    final columns = _tileColumns;
    final searchableColumns = _searchColumns;
    return Card(
      key: ValueKey('workflow-table-grid-$_tableGroupId'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (searchableColumns.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  key: ValueKey('workflow-table-search-$_tableGroupId'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No rows in this table yet.',
                    key: ValueKey('workflow-table-empty-$_tableGroupId'),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  key: ValueKey('workflow-table-data-$_tableGroupId'),
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending:
                      _sortDirection != _WorkflowTableSortDirection.descending,
                  columns: [
                    for (final column in columns)
                      DataColumn(
                        label: Row(
                          key: ValueKey(
                            'workflow-table-header-$_tableGroupId-${column.field}',
                          ),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_columnLabel(column)),
                            const SizedBox(width: 4),
                            Icon(_sortIcon(column), size: 16),
                          ],
                        ),
                        numeric: _isNumeric(column.schema.type),
                        onSort: column.schema.sortable
                            ? (_, __) => _toggleSort(column.field)
                            : null,
                      ),
                  ],
                  rows: [
                    for (final binding in rows)
                      DataRow(
                        // DataRow.key becomes a TableRow.key internally
                        // (data_table.dart's _buildTableRows), which is
                        // consumed by Table's own row-diffing and is never
                        // attached to an actual Widget in the tree -- so it
                        // is NOT discoverable via find.byKey in tests.
                        // Confirmed by reading the Flutter SDK source. The
                        // real, locatable row identity lives on the first
                        // cell's KeyedSubtree below instead.
                        key: ValueKey(
                          'workflow-table-row-$_tableGroupId-${binding.instance.instanceId}-${binding.definitionBindingIndex}',
                        ),
                        onSelectChanged: (selected) {
                          if (selected == true) {
                            _openDetail(context, binding);
                          }
                        },
                        cells: [
                          for (var i = 0; i < columns.length; i++)
                            DataCell(
                              KeyedSubtree(
                                key: i == 0
                                    ? ValueKey(
                                        'workflow-table-row-$_tableGroupId-${binding.instance.instanceId}-${binding.definitionBindingIndex}',
                                      )
                                    : null,
                                child: Text(
                                  key: ValueKey(
                                    'workflow-table-cell-$_tableGroupId-${binding.instance.instanceId}-${columns[i].field}',
                                  ),
                                  _valueText(
                                    binding.instance.instanceData[columns[i]
                                        .field],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _humanizeFieldName(String key) {
  final spaced = key.replaceAllMapped(
    RegExp(r'(?<=[a-z0-9])([A-Z])'),
    (match) => ' ${match.group(0)}',
  );
  if (spaced.isEmpty) return spaced;
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

Iterable<String> _deriveActorOrReceiverRolesForInstance(
  Map<String, LoomWorkflowStateMachine> definitions,
  WorkflowInstance instance,
  String viewerFanId,
  String viewerRoleId,
) {
  final machine = definitions[instance.workflowType];
  if (machine == null) return const <String>{};
  return deriveInstanceRoles(
    machine,
    instance,
    viewerFanId: viewerFanId,
    viewerRoleId: viewerRoleId,
  );
}
