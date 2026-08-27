part of '../loom_communities_app_shell.dart';

/// The engine-native Marketplace tab.
///
/// This surface deliberately follows [EngineNativeListSurface]'s two-stage
/// shape: resolve the one installed community engine first, then let
/// [EngineNativeBindingDispatcher] load the bindings declared for the
/// Marketplace tab. Search and category filtering are only projections of
/// that binding snapshot; they never create or seed a second data source.
class EngineNativeMarketplaceSurface extends StatefulWidget {
  const EngineNativeMarketplaceSurface({
    super.key,
    required this.experience,
    required this.actorIdentity,
    this.tabId = 'marketplace',
    required this.accent,
    this.modernTheme,
    this.engine,
  });

  final LoomExperienceDefinition experience;
  final LoomActorIdentity actorIdentity;
  final String tabId;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final WorkflowEngineApi? engine;

  @override
  State<EngineNativeMarketplaceSurface> createState() =>
      _EngineNativeMarketplaceSurfaceState();
}

class _EngineNativeMarketplaceSurfaceState
    extends State<EngineNativeMarketplaceSurface> {
  Future<WorkflowEngineApi>? _engineFuture;
  String _searchQuery = '';
  String? _selectedCategory;
  late final EngineNativeRolesForInstance _stableMarketplaceRolesForInstance =
      _marketplaceRolesForInstance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EngineNativeMarketplaceSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.experience.extensionId != widget.experience.extensionId ||
        oldWidget.engine != widget.engine ||
        oldWidget.actorIdentity.roleId != widget.actorIdentity.roleId ||
        oldWidget.actorIdentity.accountId != widget.actorIdentity.accountId ||
        oldWidget.tabId != widget.tabId) {
      _selectedCategory = null;
      _searchQuery = '';
      _load();
    }
  }

  void _load() {
    final extensionId = widget.experience.extensionId;
    setState(() {
      _engineFuture = widget.engine == null
          ? workflowEngineForExtensionId(extensionId)
          : Future<WorkflowEngineApi>.value(widget.engine);
    });
  }

  Iterable<String> _marketplaceRolesForInstance(
    WorkflowInstance instance,
    String viewerFanId,
  ) {
    final definitions = widget.experience.workflowDefinitions;
    if (definitions == null) return const <String>[];
    final machine = definitions[instance.workflowType];
    if (machine == null) return const <String>[];
    return deriveInstanceRoles(
      machine,
      instance,
      viewerFanId: viewerFanId,
      viewerRoleId: widget.actorIdentity.roleId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final definitions = widget.experience.workflowDefinitions;
    if (definitions == null) return const SizedBox();
    return FutureBuilder<WorkflowEngineApi>(
      future: _engineFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            key: const ValueKey('engine-native-marketplace-error'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load marketplace: ${snapshot.error}'),
              TextButton(
                key: const ValueKey('engine-native-marketplace-retry'),
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            key: ValueKey('engine-native-marketplace-loading'),
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
          rolesForInstance: _stableMarketplaceRolesForInstance,
          builder: (context, bindings, changed) =>
              _EngineNativeMarketplaceContent(
                bindings: bindings,
                engine: engine,
                fanId: fanId,
                roleId: widget.actorIdentity.roleId,
                communityExtensionId: widget.experience.extensionId,
                accent: widget.accent,
                modernTheme: widget.modernTheme,
                searchQuery: _searchQuery,
                selectedCategory: _selectedCategory,
                onSearchChanged: (value) =>
                    setState(() => _searchQuery = value),
                onCategorySelected: (value) =>
                    setState(() => _selectedCategory = value),
                onInstanceChanged: changed,
              ),
        );
      },
    );
  }
}

class _EngineNativeMarketplaceContent extends StatelessWidget {
  const _EngineNativeMarketplaceContent({
    required this.bindings,
    required this.engine,
    required this.fanId,
    required this.roleId,
    required this.communityExtensionId,
    required this.accent,
    required this.modernTheme,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onSearchChanged,
    required this.onCategorySelected,
    required this.onInstanceChanged,
  });

  final List<EngineNativeResolvedBinding> bindings;
  final WorkflowEngineApi engine;
  final String fanId;
  final String roleId;
  final String communityExtensionId;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final String searchQuery;
  final String? selectedCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<WorkflowInstance> onInstanceChanged;

  List<EngineNativeResolvedBinding> get _filteredBindings {
    final query = searchQuery.trim().toLowerCase();
    return bindings
        .where((resolved) {
          final data = resolved.instance.instanceData;
          final matchesSearch =
              query.isEmpty ||
              '${data['title'] ?? ''}'.toLowerCase().contains(query) ||
              '${data['description'] ?? ''}'.toLowerCase().contains(query);
          final matchesCategory =
              selectedCategory == null ||
              '${data['category'] ?? ''}' == selectedCategory;
          return matchesSearch && matchesCategory;
        })
        .toList(growable: false);
  }

  List<String> get _categories {
    final categories = <String>{};
    for (final resolved in bindings) {
      final category = '${resolved.instance.instanceData['category'] ?? ''}'
          .trim();
      if (category.isNotEmpty) categories.add(category);
    }
    final result = categories.toList()..sort();
    return result;
  }

  void _showDetail(BuildContext context, EngineNativeResolvedBinding resolved) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: ValueKey(
          'marketplace-detail-dialog-${resolved.instance.instanceId}',
        ),
        title: Text('${resolved.instance.instanceData['title'] ?? 'Listing'}'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: EngineNativeArchetypeCard(
              contentKey: ValueKey(
                'marketplace-detail-card-${resolved.instance.instanceId}',
              ),
              resolved: resolved,
              engine: engine,
              communityExtensionId: communityExtensionId,
              fanId: fanId,
              roleId: roleId,
              accent: accent,
              modernTheme: modernTheme,
              displayContext: 'detail',
              showEditors: false,
              onInstanceChanged: onInstanceChanged,
            ),
          ),
        ),
        actions: [
          TextButton(
            key: ValueKey(
              'marketplace-detail-close-${resolved.instance.instanceId}',
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
    final foreground = modernTheme?.resolvedHeading ?? _foregroundFor(accent);
    final border =
        modernTheme?.resolvedBorder ?? foreground.withValues(alpha: 0.18);
    final filtered = _filteredBindings;
    final categories = _categories;

    if (bindings.isEmpty) {
      return const Center(
        key: ValueKey('engine-native-marketplace-empty'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No shared items are listed yet.'),
        ),
      );
    }

    return Column(
      key: const ValueKey('engine-native-marketplace-root'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('marketplace-search-field'),
          style: TextStyle(color: foreground),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: foreground),
            hintText: 'Search available items',
            hintStyle: TextStyle(color: foreground.withValues(alpha: 0.60)),
            filled: true,
            fillColor: foreground.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: modernTheme?.accent ?? accent),
            ),
          ),
          onChanged: onSearchChanged,
        ),
        if (categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  ChoiceChip(
                    key: ValueKey('marketplace-filter-$category'),
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (selected) =>
                        onCategorySelected(selected ? category : null),
                    selectedColor: modernTheme?.accent ?? accent,
                    labelStyle: TextStyle(
                      color: selectedCategory == category
                          ? Colors.white
                          : foreground,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: selectedCategory == category
                          ? modernTheme?.accent ?? accent
                          : border,
                    ),
                  ),
              ],
            ),
          ),
        if (filtered.isEmpty)
          Center(
            key: const ValueKey('engine-native-marketplace-no-results'),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No listings match your search',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: foreground.withValues(alpha: 0.80),
                ),
              ),
            ),
          )
        else
          RepeaterSurface.static(
            items: filtered,
            layout: RepeaterLayout.grid,
            gridCrossAxisCountBuilder: (context, constraints) =>
                constraints.maxWidth > 600 ? 3 : 2,
            // A Marketplace tile contains schema facts plus one or more real
            // guarded actions. Keep phone-sized tiles at two columns and give
            // every cell enough height for the widest seeded loan state.
            gridChildAspectRatio: 0.62,
            gridCrossAxisSpacing: 10,
            gridMainAxisSpacing: 10,
            gridShrinkWrap: true,
            gridScrollable: false,
            itemBuilder: (context, item) {
              final resolved = item as EngineNativeResolvedBinding;
              return InkWell(
                key: ValueKey(
                  'marketplace-listing-tap-${resolved.instance.instanceId}',
                ),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showDetail(context, resolved),
                child: EngineNativeArchetypeCard(
                  contentKey: ValueKey(
                    'marketplace-listing-${resolved.instance.instanceId}',
                  ),
                  resolved: resolved,
                  engine: engine,
                  communityExtensionId: communityExtensionId,
                  fanId: fanId,
                  roleId: roleId,
                  accent: accent,
                  modernTheme: modernTheme,
                  displayContext: 'tile',
                  onInstanceChanged: onInstanceChanged,
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Bespoke rendering for the equipment-loan card family.
///
/// The facts are projected from the workflow definition's complete
/// [InstanceDataField] schema. The only specialized behavior here is the
/// domain action grouping: the declared borrow action is contextual, queue
/// membership is a single toggle, and giveaways expose claim. Every button
/// still comes from [availableTransitionsAsync], so cross-workflow and
/// role guards are authoritative.
class EquipmentLoanArchetypeCard extends StatefulWidget {
  const EquipmentLoanArchetypeCard({
    super.key,
    required this.resolved,
    required this.engine,
    required this.fanId,
    required this.accent,
    required this.onInstanceChanged,
    this.modernTheme,
    this.displayContext = 'tile',
    this.visibleFieldKeys,
  }) : assert(displayContext == 'tile' || displayContext == 'detail');

  final EngineNativeResolvedBinding resolved;
  final WorkflowEngineApi engine;
  final String fanId;
  final Color accent;
  final ValueChanged<WorkflowInstance> onInstanceChanged;
  final LoomCardTheme? modernTheme;
  final String displayContext;
  final Set<String>? visibleFieldKeys;

  @override
  State<EquipmentLoanArchetypeCard> createState() =>
      _EquipmentLoanArchetypeCardState();
}

class _EquipmentLoanArchetypeCardState
    extends State<EquipmentLoanArchetypeCard> {
  late WorkflowInstance _instance;
  List<LoomWorkflowTransition> _actions = const [];
  bool _loadingActions = true;
  bool _mutating = false;
  String? _error;
  int _actionRequest = 0;

  @override
  void initState() {
    super.initState();
    _instance = widget.resolved.instance;
    _loadActions();
  }

  @override
  void didUpdateWidget(covariant EquipmentLoanArchetypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldInstance = oldWidget.resolved.instance;
    final newInstance = widget.resolved.instance;
    if (oldInstance.instanceId != newInstance.instanceId ||
        oldInstance.currentState != newInstance.currentState ||
        oldInstance.instanceData != newInstance.instanceData ||
        oldWidget.fanId != widget.fanId ||
        oldWidget.engine != widget.engine) {
      _instance = newInstance;
      _loadActions();
    }
  }

  @override
  void dispose() {
    _actionRequest++;
    super.dispose();
  }

  Future<void> _loadActions() async {
    final request = ++_actionRequest;
    if (mounted) {
      setState(() {
        _loadingActions = true;
        _error = null;
      });
    }
    try {
      final instance = _instance;
      final actions = await widget.engine.availableTransitionsAsync(
        workflowType: instance.workflowType,
        instanceId: instance.instanceId,
        currentState: instance.currentState,
        instanceData: instance.instanceData,
        fanId: widget.fanId,
      );
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = actions;
        _loadingActions = false;
      });
    } catch (_) {
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = const [];
        _loadingActions = false;
        _error = 'Could not load listing actions.';
      });
    }
  }

  LoomWorkflowTransition? _action(String id) {
    for (final action in _actions) {
      if (action.id == id) return action;
    }
    return null;
  }

  bool get _isGiveaway => widget.resolved.machine.transitions.any(
    (transition) => transition.id == 'claim',
  );

  LoomWorkflowTransition? get _contextualBorrow =>
      _isGiveaway ? null : _action('borrow');

  LoomWorkflowTransition? get _queueToggle =>
      _action('join-queue') ?? _action('leave-queue');

  LoomWorkflowTransition? get _returnAction =>
      _action('return') ?? _action('return-game');

  List<LoomWorkflowTransition> get _additionalActions {
    if (_isGiveaway) {
      final claim = _action('claim');
      return claim == null ? const [] : [claim];
    }
    if (_instance.workflowType == 'equipment-loan') {
      final used = {
        for (final action in [_contextualBorrow, _queueToggle, _returnAction])
          if (action != null) action.id,
      };
      return [
        for (final action in _actions)
          if (!used.contains(action.id)) action,
      ];
    }
    final used = {
      for (final action in [_contextualBorrow, _queueToggle, _returnAction])
        if (action != null) action.id,
    };
    return [
      for (final action in _actions)
        if (!used.contains(action.id)) action,
    ];
  }

  Map<String, WorkflowFactPillFieldSchema> _factSchema() {
    final schema = <String, WorkflowFactPillFieldSchema>{};
    for (final entry in widget.resolved.machine.instanceDataSchema.entries) {
      final key = entry.key;
      final field = entry.value;
      if (widget.visibleFieldKeys != null &&
          !widget.visibleFieldKeys!.contains(key)) {
        continue;
      }
      // Formula-backed fields are derived engine helpers unless the schema
      // explicitly gives them a user-facing label.
      final isUnlabeledComputedField =
          field.formula?.trim().isNotEmpty == true &&
          !(field.labelTemplate?.trim().isNotEmpty ?? false);
      if (isUnlabeledComputedField) continue;
      // An empty list means "never render this field anywhere" (used for
      // internal/formula-only fields); only an omitted/null list means "no
      // restriction, show in every context" -- the two must not be conflated.
      if (field.displayContexts != null &&
          !field.displayContexts!.contains(widget.displayContext)) {
        continue;
      }
      final value = _instance.instanceData[key];
      if (field.hideWhenEmpty && _isEmpty(value)) continue;
      if (_renderLabel(field.labelTemplate ?? key, value).trim().isEmpty) {
        continue;
      }
      schema[key] = WorkflowFactPillFieldSchema(
        type: field.type == 'textarea' ? 'text' : field.type,
        maxLength: field.maxLength,
        // Any community's own field names may carry the same long-text/
        // owner-attribution role the hardcoded equipment-loan archetype
        // names explicitly (title/holderFanId/claimedByFanId) --
        // apply the same non-truncating default to every fact pill here
        // rather than keying off a fixed allowlist of field names (CJM.11).
        maxLines: 2,
        displayIcon: field.displayIcon,
        // The frozen Marketplace schema intentionally leaves simple scalar
        // fields such as category and availabilityState without a label
        // template. Keep their real values visible rather than allowing the
        // generic fact renderer to reduce a missing template to only the
        // field name.
        labelTemplate: field.labelTemplate ?? '{value}',
        hideWhenEmpty: field.hideWhenEmpty,
        displayContexts: field.displayContexts,
      );
    }
    return schema;
  }

  /// A detail-only list with a declared count label is safe to summarize on a
  /// marketplace tile after it becomes non-empty. The count confirms a
  /// completed action without exposing the detail-only list entries themselves.
  Map<String, WorkflowFactPillFieldSchema> _tileOutcomeFactSchema() {
    if (widget.displayContext != 'tile') return const {};
    final schema = <String, WorkflowFactPillFieldSchema>{};
    for (final entry in widget.resolved.machine.instanceDataSchema.entries) {
      final key = entry.key;
      final field = entry.value;
      final contexts = field.displayContexts;
      if (widget.visibleFieldKeys != null &&
          !widget.visibleFieldKeys!.contains(key)) {
        continue;
      }
      if (field.type != 'list' ||
          !field.hideWhenEmpty ||
          contexts == null ||
          !contexts.contains('detail') ||
          contexts.contains('tile') ||
          !(field.labelTemplate?.contains('{value.length}') ?? false)) {
        continue;
      }
      final value = _instance.instanceData[key];
      if (_isEmpty(value)) continue;
      schema[key] = WorkflowFactPillFieldSchema(
        type: field.type,
        maxLength: field.maxLength,
        maxLines: 2,
        displayIcon: field.displayIcon,
        labelTemplate: field.labelTemplate,
        hideWhenEmpty: true,
        displayContexts: const ['tile'],
      );
    }
    return schema;
  }

  WorkflowActionTone _toneFor(String? tone) => switch (tone) {
    'secondary' => WorkflowActionTone.secondary,
    'destructive' => WorkflowActionTone.destructive,
    _ => WorkflowActionTone.primary,
  };

  List<WorkflowActionButtonTransition> _buttonTransitions() => [
    for (final action in [_queueToggle, _returnAction, ..._additionalActions])
      if (action != null)
        WorkflowActionButtonTransition(
          id: action.id,
          label: action.label,
          iconName: action.icon,
          tone: _toneFor(action.tone),
        ),
  ];

  Future<void> _applyTransition(LoomWorkflowTransition transition) async {
    if (_mutating) return;
    final inputs = await _collectTransitionInputs(
      context: context,
      transition: transition,
      instanceData: _instance.instanceData,
    );
    if (inputs == null || !mounted || _mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final result = await widget.engine.applyTransition(
        workflowType: _instance.workflowType,
        instanceId: _instance.instanceId,
        transitionId: transition.id,
        fanId: widget.fanId,
        inputs: inputs,
      );
      final next = WorkflowInstance(
        instanceId: _instance.instanceId,
        workflowType: _instance.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByFanId: _instance.createdByFanId,
      );
      if (!mounted) return;
      setState(() {
        _instance = next;
        _mutating = false;
      });
      widget.onInstanceChanged(next);
      await _loadActions();
      if (!mounted) return;
      if (transition.effects.any(
            (effect) => effect.op == 'removeFromTileGrid',
          ) &&
          widget.displayContext == 'detail') {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mutating = false;
        _error = 'Could not update this listing.';
      });
    }
  }

  Widget _borrowButton(BuildContext context, LoomWorkflowTransition action) {
    final color = widget.modernTheme?.accent ?? widget.accent;
    final key = widget.displayContext == 'detail'
        ? const ValueKey('marketplace-transition-fab-borrow')
        : ValueKey('equipment-loan-action-borrow-${_instance.instanceId}');
    return FilledButton.icon(
      key: key,
      onPressed: _mutating ? null : () => unawaited(_applyTransition(action)),
      icon: const Icon(Icons.arrow_forward, color: Colors.white),
      label: Text(action.label, style: const TextStyle(color: Colors.white)),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    final facts = _factSchema();
    final tileOutcomeFacts = _tileOutcomeFactSchema();
    final contextualBorrow = _contextualBorrow;
    final buttons = _buttonTransitions();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkflowFactPillRow(
                key: ValueKey(
                  'equipment-loan-facts-${_instance.instanceId}-${widget.displayContext}',
                ),
                instanceData: _instance.instanceData,
                instanceDataSchema: facts,
                displayContext: widget.displayContext,
                foreground: foreground,
                accent: widget.accent,
              ),
              if (tileOutcomeFacts.isNotEmpty) ...[
                const SizedBox(height: 8),
                WorkflowFactPillRow(
                  key: ValueKey(
                    'equipment-loan-tile-outcome-${_instance.instanceId}-${tileOutcomeFacts.keys.join('-')}',
                  ),
                  instanceData: _instance.instanceData,
                  instanceDataSchema: tileOutcomeFacts,
                  displayContext: 'tile',
                  foreground: foreground,
                  accent: widget.accent,
                ),
              ],
              if (_loadingActions || _mutating)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(
                    key: ValueKey(
                      'equipment-loan-progress-${_instance.instanceId}',
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  key: ValueKey('equipment-loan-error-${_instance.instanceId}'),
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!),
                ),
              if (!_loadingActions && contextualBorrow != null) ...[
                const SizedBox(height: 8),
                _borrowButton(context, contextualBorrow),
              ],
              if (!_loadingActions && buttons.isNotEmpty)
                WorkflowActionButtonRow(
                  surface: widget.displayContext == 'detail'
                      ? 'marketplace'
                      : 'equipment-loan-${_instance.instanceId}',
                  availableTransitions: buttons,
                  onTransitionPressed: _mutating
                      ? null
                      : (transitionId) {
                          final transition = _actions.firstWhere(
                            (candidate) => candidate.id == transitionId,
                          );
                          unawaited(_applyTransition(transition));
                        },
                  foreground: foreground,
                  accent: widget.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bespoke rendering for the document-library card family.
///
/// Like existing marketplace archetypes, this card renders the transitions
/// authorized by the workflow engine for the current instance and actor identity.
class DocumentLibraryArchetypeCard extends StatefulWidget {
  const DocumentLibraryArchetypeCard({
    super.key,
    required this.resolved,
    required this.engine,
    required this.fanId,
    required this.accent,
    required this.onInstanceChanged,
    this.modernTheme,
    this.displayContext = 'tile',
    this.visibleFieldKeys,
  }) : assert(displayContext == 'tile' || displayContext == 'detail');

  final EngineNativeResolvedBinding resolved;
  final WorkflowEngineApi engine;
  final String fanId;
  final Color accent;
  final ValueChanged<WorkflowInstance> onInstanceChanged;
  final LoomCardTheme? modernTheme;
  final String displayContext;
  final Set<String>? visibleFieldKeys;

  @override
  State<DocumentLibraryArchetypeCard> createState() =>
      _DocumentLibraryArchetypeCardState();
}

class _DocumentLibraryArchetypeCardState
    extends State<DocumentLibraryArchetypeCard> {
  late WorkflowInstance _instance;
  List<LoomWorkflowTransition> _actions = const [];
  bool _loadingActions = true;
  bool _mutating = false;
  String? _error;
  int _actionRequest = 0;

  @override
  void initState() {
    super.initState();
    _instance = widget.resolved.instance;
    _loadActions();
  }

  @override
  void didUpdateWidget(covariant DocumentLibraryArchetypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldInstance = oldWidget.resolved.instance;
    final newInstance = widget.resolved.instance;
    if (oldInstance.instanceId != newInstance.instanceId ||
        oldInstance.currentState != newInstance.currentState ||
        oldInstance.instanceData != newInstance.instanceData ||
        oldWidget.fanId != widget.fanId ||
        oldWidget.engine != widget.engine) {
      _instance = newInstance;
      _loadActions();
    }
  }

  @override
  void dispose() {
    _actionRequest++;
    super.dispose();
  }

  Future<void> _loadActions() async {
    final request = ++_actionRequest;
    if (mounted) {
      setState(() {
        _loadingActions = true;
        _error = null;
      });
    }
    try {
      final instance = _instance;
      final actions = await widget.engine.availableTransitionsAsync(
        workflowType: instance.workflowType,
        instanceId: instance.instanceId,
        currentState: instance.currentState,
        instanceData: instance.instanceData,
        fanId: widget.fanId,
      );
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = actions;
        _loadingActions = false;
      });
    } catch (_) {
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = const [];
        _loadingActions = false;
        _error = 'Could not load listing actions.';
      });
    }
  }

  List<WorkflowActionButtonTransition> get _buttonTransitions => _actions
      .map(
        (action) => WorkflowActionButtonTransition(
          id: action.id,
          label: action.label,
          iconName: action.icon,
          tone: _toneFor(action.tone),
        ),
      )
      .toList(growable: false);

  WorkflowActionTone _toneFor(String? tone) => switch (tone) {
    'secondary' => WorkflowActionTone.secondary,
    'destructive' => WorkflowActionTone.destructive,
    _ => WorkflowActionTone.primary,
  };

  Map<String, WorkflowFactPillFieldSchema> _factSchema() {
    final schema = <String, WorkflowFactPillFieldSchema>{};
    for (final entry in widget.resolved.machine.instanceDataSchema.entries) {
      final key = entry.key;
      final field = entry.value;
      if (widget.visibleFieldKeys != null &&
          !widget.visibleFieldKeys!.contains(key)) {
        continue;
      }
      final isUnlabeledComputedField =
          field.formula?.trim().isNotEmpty == true &&
          !(field.labelTemplate?.trim().isNotEmpty ?? false);
      if (isUnlabeledComputedField) continue;
      if (field.displayContexts != null &&
          !field.displayContexts!.contains(widget.displayContext)) {
        continue;
      }
      final value = _instance.instanceData[key];
      if (field.hideWhenEmpty && _isEmpty(value)) continue;
      if (_renderLabel(field.labelTemplate ?? key, value).trim().isEmpty) {
        continue;
      }
      final itemSchema = field.itemSchema == null
          ? null
          : field.itemSchema!.map(
              (itemKey, itemField) => MapEntry(
                itemKey,
                WorkflowFactPillFieldSchema(
                  type: itemField.type == 'textarea' ? 'text' : itemField.type,
                  maxLength: itemField.maxLength,
                  maxLines: 2,
                  displayIcon: itemField.displayIcon,
                  labelTemplate: itemField.labelTemplate,
                  hideWhenEmpty: itemField.hideWhenEmpty,
                  displayContexts: itemField.displayContexts,
                  openMode: itemField.openMode,
                ),
              ),
            );
      schema[key] = WorkflowFactPillFieldSchema(
        type: field.type == 'textarea' ? 'text' : field.type,
        maxLength: field.maxLength,
        maxLines: 2,
        displayIcon: field.displayIcon,
        labelTemplate: field.labelTemplate ?? '{value}',
        hideWhenEmpty: field.hideWhenEmpty,
        displayContexts: field.displayContexts,
        openMode: field.openMode,
        itemSchema: itemSchema,
      );
    }
    return schema;
  }

  /// Picks a file and stores it against this document.
  ///
  /// The engine is never asked to apply the `upload` transition. The service
  /// checks the same guard when it authorises the upload, so the permission is
  /// enforced once, in the place that also holds the bytes.
  Future<void> _uploadDocument() async {
    final blocker = loomDocumentUploadBlocker(
      engine: widget.engine,
      machine: widget.resolved.machine,
    );
    if (blocker != null) {
      setState(() => _error = blocker);
      return;
    }

    final engine = widget.engine as RemoteWorkflowEngineApi;
    final client = resolveLoomDocumentClient()!;
    final fieldName = storedDocumentFieldName(widget.resolved.machine)!;

    final LoomPickedDocument? picked;
    try {
      picked = await loomDocumentPicker();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'The file could not be read.');
      return;
    }
    // Backing out of the picker is not an error, and must not leave the card
    // stuck in its mutating state.
    if (picked == null || !mounted || _mutating) return;

    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final document = await client.upload(
        communityId: engine.communityId,
        instanceId: _instance.instanceId,
        fieldName: fieldName,
        filename: picked.filename,
        bytes: picked.bytes,
        contentType: picked.contentType,
        title: _instance.instanceData['title'] as String?,
      );

      // The service already wrote this exact value into the instance. Mirroring
      // it locally rather than refetching keeps the card in step without a
      // second round trip, and the two agree by construction: both are the
      // document's own contentUrl.
      final next = WorkflowInstance(
        instanceId: _instance.instanceId,
        workflowType: _instance.workflowType,
        currentState: _instance.currentState,
        instanceData: <String, dynamic>{
          ..._instance.instanceData,
          fieldName: document.contentUrl,
        },
        createdByFanId: _instance.createdByFanId,
      );
      if (!mounted) return;
      setState(() {
        _instance = next;
        _mutating = false;
      });
      widget.onInstanceChanged(next);
      await _loadActions();
    } on LoomDocumentException catch (error) {
      if (!mounted) return;
      setState(() {
        _mutating = false;
        _error = error.isNotFoundOrForbidden
            ? 'You do not have permission to upload to this document.'
            : 'The document could not be uploaded.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mutating = false;
        _error = 'The document could not be uploaded.';
      });
    }
  }

  Future<void> _applyTransition(LoomWorkflowTransition transition) async {
    if (_mutating) return;
    // `upload` is not an ordinary transition. Its whole effect is the file, and
    // the file does not travel through the engine: the Document Library API
    // stores the bytes and writes the content reference into the instance
    // itself. Applying the transition here would run a transition that declares
    // no effects, and leave the member looking at a button that did nothing.
    if (transition.action == 'upload') {
      await _uploadDocument();
      return;
    }

    final inputs = await _collectTransitionInputs(
      context: context,
      transition: transition,
      instanceData: _instance.instanceData,
    );
    if (inputs == null || !mounted || _mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final result = await widget.engine.applyTransition(
        workflowType: _instance.workflowType,
        instanceId: _instance.instanceId,
        transitionId: transition.id,
        fanId: widget.fanId,
        inputs: inputs,
      );
      final next = WorkflowInstance(
        instanceId: _instance.instanceId,
        workflowType: _instance.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByFanId: _instance.createdByFanId,
      );
      if (!mounted) return;
      setState(() {
        _instance = next;
        _mutating = false;
      });
      widget.onInstanceChanged(next);
      await _loadActions();
      if (!mounted) return;
      if (transition.effects.any(
            (effect) => effect.op == 'removeFromTileGrid',
          ) &&
          widget.displayContext == 'detail') {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mutating = false;
        _error = 'Could not update this document.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    final facts = _factSchema();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkflowFactPillRow(
                key: ValueKey(
                  'document-library-facts-${_instance.instanceId}-${widget.displayContext}',
                ),
                instanceData: _instance.instanceData,
                instanceDataSchema: facts,
                displayContext: widget.displayContext,
                foreground: foreground,
                accent: widget.accent,
              ),
              if (_loadingActions || _mutating)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(
                    key: ValueKey(
                      'document-library-progress-${_instance.instanceId}',
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  key: ValueKey(
                    'document-library-error-${_instance.instanceId}',
                  ),
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!),
                ),
              if (!_loadingActions)
                WorkflowActionButtonRow(
                  surface: widget.displayContext == 'detail'
                      ? 'document-library'
                      : 'document-library-${_instance.instanceId}',
                  availableTransitions: _buttonTransitions,
                  onTransitionPressed: _mutating
                      ? null
                      : (transitionId) {
                          final transition = _actions.firstWhere(
                            (candidate) => candidate.id == transitionId,
                          );
                          unawaited(_applyTransition(transition));
                        },
                  foreground: foreground,
                  accent: widget.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bespoke rendering for the exportWizard card family.
class ExportWizardArchetypeCard extends StatefulWidget {
  const ExportWizardArchetypeCard({
    super.key,
    required this.resolved,
    required this.engine,
    required this.fanId,
    required this.accent,
    required this.onInstanceChanged,
    this.modernTheme,
    this.displayContext = 'tile',
    this.visibleFieldKeys,
  }) : assert(displayContext == 'tile' || displayContext == 'detail');

  final EngineNativeResolvedBinding resolved;
  final WorkflowEngineApi engine;
  final String fanId;
  final Color accent;
  final ValueChanged<WorkflowInstance> onInstanceChanged;
  final LoomCardTheme? modernTheme;
  final String displayContext;
  final Set<String>? visibleFieldKeys;

  @override
  State<ExportWizardArchetypeCard> createState() =>
      _ExportWizardArchetypeCardState();
}

class _ExportWizardArchetypeCardState extends State<ExportWizardArchetypeCard> {
  static const _historyFieldHints = <String>[
    'exportHistory',
    'statusHistory',
    'auditHistory',
  ];

  late WorkflowInstance _instance;
  List<LoomWorkflowTransition> _actions = const [];
  bool _loadingActions = true;
  bool _mutating = false;
  String? _error;
  int _actionRequest = 0;

  @override
  void initState() {
    super.initState();
    _instance = widget.resolved.instance;
    _loadActions();
  }

  @override
  void didUpdateWidget(covariant ExportWizardArchetypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldInstance = oldWidget.resolved.instance;
    final newInstance = widget.resolved.instance;
    if (oldInstance.instanceId != newInstance.instanceId ||
        oldInstance.currentState != newInstance.currentState ||
        oldInstance.instanceData != newInstance.instanceData ||
        oldWidget.fanId != widget.fanId ||
        oldWidget.engine != widget.engine) {
      _instance = newInstance;
      _loadActions();
    }
  }

  @override
  void dispose() {
    _actionRequest++;
    super.dispose();
  }

  Future<void> _loadActions() async {
    final request = ++_actionRequest;
    if (mounted) {
      setState(() {
        _loadingActions = true;
        _error = null;
      });
    }
    try {
      final instance = _instance;
      final actions = await widget.engine.availableTransitionsAsync(
        workflowType: instance.workflowType,
        instanceId: instance.instanceId,
        currentState: instance.currentState,
        instanceData: instance.instanceData,
        fanId: widget.fanId,
      );
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = actions;
        _loadingActions = false;
      });
    } catch (_) {
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = const [];
        _loadingActions = false;
        _error = 'Could not load listing actions.';
      });
    }
  }

  Future<void> _applyTransition(LoomWorkflowTransition transition) async {
    if (_mutating) return;
    final inputs = await _collectTransitionInputs(
      context: context,
      transition: transition,
      instanceData: _instance.instanceData,
    );
    if (inputs == null || !mounted || _mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final result = await widget.engine.applyTransition(
        workflowType: _instance.workflowType,
        instanceId: _instance.instanceId,
        transitionId: transition.id,
        fanId: widget.fanId,
        inputs: inputs,
      );
      final next = WorkflowInstance(
        instanceId: _instance.instanceId,
        workflowType: _instance.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByFanId: _instance.createdByFanId,
      );
      if (!mounted) return;
      setState(() {
        _instance = next;
        _mutating = false;
      });
      widget.onInstanceChanged(next);
      await _loadActions();
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mutating = false;
        _error = 'Could not update this listing.';
      });
    }
  }

  Map<String, WorkflowFactPillFieldSchema> _supplementalFacts() {
    final schema = <String, WorkflowFactPillFieldSchema>{};
    final historyKey = _historyFieldKey();
    for (final entry in widget.resolved.machine.instanceDataSchema.entries) {
      final key = entry.key;
      final field = entry.value;
      if (key == historyKey) continue;
      if (widget.visibleFieldKeys != null &&
          !widget.visibleFieldKeys!.contains(key)) {
        continue;
      }
      final isUnlabeledComputedField =
          field.formula?.trim().isNotEmpty == true &&
          !(field.labelTemplate?.trim().isNotEmpty ?? false);
      if (isUnlabeledComputedField) continue;
      if (field.displayContexts != null &&
          !field.displayContexts!.contains(widget.displayContext)) {
        continue;
      }
      final value = _instance.instanceData[key];
      if (field.hideWhenEmpty && _isEmpty(value)) continue;
      if (_renderLabel(field.labelTemplate ?? key, value).trim().isEmpty) {
        continue;
      }
      final itemSchema = field.itemSchema == null
          ? null
          : field.itemSchema!.map(
              (itemKey, itemField) => MapEntry(
                itemKey,
                WorkflowFactPillFieldSchema(
                  type: itemField.type == 'textarea' ? 'text' : itemField.type,
                  maxLength: itemField.maxLength,
                  maxLines: 2,
                  displayIcon: itemField.displayIcon,
                  labelTemplate: itemField.labelTemplate,
                  hideWhenEmpty: itemField.hideWhenEmpty,
                  displayContexts: itemField.displayContexts,
                  openMode: itemField.openMode,
                ),
              ),
            );
      schema[key] = WorkflowFactPillFieldSchema(
        type: field.type == 'textarea' ? 'text' : field.type,
        maxLength: field.maxLength,
        maxLines: 2,
        displayIcon: field.displayIcon,
        labelTemplate: field.labelTemplate ?? '{value}',
        hideWhenEmpty: field.hideWhenEmpty,
        displayContexts: field.displayContexts,
        openMode: field.openMode,
        itemSchema: itemSchema,
      );
    }
    return schema;
  }

  List<WorkflowActionButtonTransition> get _buttonTransitions => [
    for (final action in _actions)
      WorkflowActionButtonTransition(
        id: action.id,
        label: action.label,
        iconName: action.icon,
        tone: _toneFor(action.tone),
      ),
  ];

  WorkflowActionTone _toneFor(String? tone) => switch (tone) {
    'secondary' => WorkflowActionTone.secondary,
    'destructive' => WorkflowActionTone.destructive,
    _ => WorkflowActionTone.primary,
  };

  Color _stateTint(LoomWorkflowState? state) {
    final tone = (state?.tone ?? '').toLowerCase();
    if (_isOffPathState(state)) {
      return Colors.orange;
    }
    return switch (tone) {
      'positive' => Colors.green,
      'warning' => Colors.orange,
      'negative' => Colors.red,
      'info' => Colors.blue,
      _ => widget.accent,
    };
  }

  IconData _stateIcon(LoomWorkflowState? state) {
    if (_isOffPathState(state)) {
      return Icons.warning_amber_outlined;
    }
    return switch ((state?.tone ?? '').toLowerCase()) {
      'positive' => Icons.check_circle_outline,
      'warning' => Icons.hourglass_top,
      'negative' => Icons.error_outline,
      'info' => Icons.info_outline,
      _ => Icons.auto_awesome,
    };
  }

  bool _isOffPathState(LoomWorkflowState? state) {
    final stateId = _instance.currentState.toLowerCase();
    if (state?.isTerminal == true) {
      return true;
    }
    if (stateId == 'failed' ||
        stateId == 'rolled-back' ||
        stateId == 'error' ||
        stateId == 'cancelled') {
      return true;
    }
    return false;
  }

  LoomWorkflowState? get _currentState =>
      widget.resolved.machine.states[_instance.currentState];

  String get _currentStateLabel =>
      _currentState?.label ?? _instance.currentState;

  String? _historyFieldKey() {
    final schema = widget.resolved.machine.instanceDataSchema;
    for (final key in _historyFieldHints) {
      if (schema.containsKey(key)) return key;
    }
    for (final key in schema.keys) {
      if (key.toLowerCase().endsWith('history') &&
          schema[key]!.type.toLowerCase() == 'list') {
        return key;
      }
    }
    return null;
  }

  List<dynamic> _historyEntries() {
    final historyKey = _historyFieldKey();
    if (historyKey == null) return const [];
    final raw = _instance.instanceData[historyKey];
    return raw is List<dynamic> ? raw : const [];
  }

  String _historyLabel(dynamic entry) {
    if (entry == null) return '';
    if (entry is String) return entry;
    if (entry is Map) {
      final status = entry['status']?.toString();
      final event = entry['event']?.toString();
      final actor =
          entry['actorFanId']?.toString() ??
          entry['byFanId']?.toString() ??
          entry['by']?.toString();
      final at = entry['at']?.toString();
      final note = entry['note']?.toString();
      final detail = status ?? event;
      final noteText = note == null || note.isEmpty ? '' : ' · $note';
      final actorText = actor == null || actor.isEmpty ? '' : ' · $actor';
      final atText = at == null || at.isEmpty ? '' : ' · $at';
      if (detail != null && detail.isNotEmpty) {
        return '$detail$noteText$actorText$atText';
      }
    }
    return entry.toString();
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    final facts = _supplementalFacts();
    final historyKey = _historyFieldKey();
    final historyEntries = _historyEntries();
    final state = _currentState;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StateBadge(
                key: ValueKey(
                  'export-wizard-state-badge-${_instance.instanceId}-${widget.displayContext}',
                ),
                icon: _stateIcon(state),
                label: _currentStateLabel,
                foreground: _stateTint(state),
                accent: _isOffPathState(state)
                    ? _stateTint(state).withValues(alpha: 0.20)
                    : null,
              ),
              if (_isOffPathState(state))
                Padding(
                  key: ValueKey(
                    'export-wizard-off-path-${_instance.instanceId}-${widget.displayContext}',
                  ),
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'This is an off-path export state',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _stateTint(state),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (facts.isNotEmpty) ...[
                const SizedBox(height: 10),
                WorkflowFactPillRow(
                  key: ValueKey(
                    'export-wizard-facts-${_instance.instanceId}-${widget.displayContext}',
                  ),
                  instanceData: _instance.instanceData,
                  instanceDataSchema: facts,
                  displayContext: widget.displayContext,
                  foreground: foreground,
                  accent: widget.accent,
                ),
              ],
              if (historyKey != null && historyEntries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'History',
                  key: ValueKey(
                    'export-wizard-history-heading-${_instance.instanceId}-${widget.displayContext}',
                  ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                for (var index = 0; index < historyEntries.length; index += 1)
                  Padding(
                    key: ValueKey(
                      'export-wizard-history-${_instance.instanceId}-${widget.displayContext}-$index',
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.history,
                          size: 16,
                          color: foreground.withValues(alpha: 0.68),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _historyLabel(historyEntries[index]),
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(color: foreground),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (_loadingActions || _mutating)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(
                    key: ValueKey(
                      'export-wizard-progress-${_instance.instanceId}',
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  key: Key('export-wizard-error-${_instance.instanceId}'),
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!),
                ),
              if (!_loadingActions)
                WorkflowActionButtonRow(
                  surface: widget.displayContext == 'detail'
                      ? 'export-wizard'
                      : 'export-wizard-${_instance.instanceId}',
                  availableTransitions: _buttonTransitions,
                  onTransitionPressed: _mutating
                      ? null
                      : (transitionId) {
                          final transition = _actions.firstWhere(
                            (candidate) => candidate.id == transitionId,
                          );
                          unawaited(_applyTransition(transition));
                        },
                  foreground: foreground,
                  accent: widget.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bespoke rendering for the searchAiAnswer card family.
class SearchAiAnswerArchetypeCard extends StatefulWidget {
  const SearchAiAnswerArchetypeCard({
    super.key,
    required this.resolved,
    required this.engine,
    required this.fanId,
    required this.accent,
    required this.onInstanceChanged,
    this.modernTheme,
    this.displayContext = 'tile',
    this.visibleFieldKeys,
  }) : assert(displayContext == 'tile' || displayContext == 'detail');

  final EngineNativeResolvedBinding resolved;
  final WorkflowEngineApi engine;
  final String fanId;
  final Color accent;
  final ValueChanged<WorkflowInstance> onInstanceChanged;
  final LoomCardTheme? modernTheme;
  final String displayContext;
  final Set<String>? visibleFieldKeys;

  @override
  State<SearchAiAnswerArchetypeCard> createState() =>
      _SearchAiAnswerArchetypeCardState();
}

class _SearchAiAnswerArchetypeCardState
    extends State<SearchAiAnswerArchetypeCard> {
  late WorkflowInstance _instance;
  List<LoomWorkflowTransition> _actions = const [];
  bool _loadingActions = true;
  bool _mutating = false;
  String? _error;
  int _actionRequest = 0;

  @override
  void initState() {
    super.initState();
    _instance = widget.resolved.instance;
    _loadActions();
  }

  @override
  void didUpdateWidget(covariant SearchAiAnswerArchetypeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldInstance = oldWidget.resolved.instance;
    final newInstance = widget.resolved.instance;
    if (oldInstance.instanceId != newInstance.instanceId ||
        oldInstance.currentState != newInstance.currentState ||
        oldInstance.instanceData != newInstance.instanceData ||
        oldWidget.fanId != widget.fanId ||
        oldWidget.engine != widget.engine) {
      _instance = newInstance;
      _loadActions();
    }
  }

  @override
  void dispose() {
    _actionRequest++;
    super.dispose();
  }

  Future<void> _loadActions() async {
    final request = ++_actionRequest;
    if (mounted) {
      setState(() {
        _loadingActions = true;
        _error = null;
      });
    }
    try {
      final instance = _instance;
      final actions = await widget.engine.availableTransitionsAsync(
        workflowType: instance.workflowType,
        instanceId: instance.instanceId,
        currentState: instance.currentState,
        instanceData: instance.instanceData,
        fanId: widget.fanId,
      );
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = actions;
        _loadingActions = false;
      });
    } catch (_) {
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = const [];
        _loadingActions = false;
        _error = 'Could not load search answer actions.';
      });
    }
  }

  static String _baseType(String raw) {
    final normalized = raw.toLowerCase();
    if (normalized.endsWith('?'))
      return normalized.substring(0, normalized.length - 1);
    return normalized;
  }

  bool _isAnswerTextField(String rawType) {
    final type = _baseType(rawType);
    return type == 'text' || type == 'textarea';
  }

  bool _isVisibleField(String key, InstanceDataField field) {
    // query and citations each have their own dedicated rendering path
    // (_resolvedQuery / _citationsFacts) -- they must never be candidates
    // for the generic answer-field selection below, or a set-but-irrelevant
    // query can get mislabeled as the answer once every real answer-shaped
    // field is empty (confirmed: this exact bug made the "waiting for an
    // answer" empty state unreachable whenever query was non-empty).
    if (key == 'query' || key == 'citations') return false;
    if (!_isAnswerTextField(field.type)) return false;
    if (widget.visibleFieldKeys != null &&
        !widget.visibleFieldKeys!.contains(key)) {
      return false;
    }
    if (field.displayContexts != null &&
        !field.displayContexts!.contains(widget.displayContext)) {
      return false;
    }
    return true;
  }

  int _writablePriority(InstanceDataField field) {
    switch (field.writableBy) {
      case 'effect':
        return 2;
      case 'formEntry':
        return 1;
      default:
        return 0;
    }
  }

  String? _queryText;
  String? get _resolvedQuery {
    if (_queryText != null) return _queryText;
    final queryField = widget.resolved.machine.instanceDataSchema['query'];
    if (queryField == null) return null;
    final value = _instance.instanceData['query'];
    if (queryField.displayContexts != null &&
        !queryField.displayContexts!.contains(widget.displayContext)) {
      return null;
    }
    if (widget.visibleFieldKeys != null &&
        !widget.visibleFieldKeys!.contains('query')) {
      return null;
    }
    final label = _renderLabel(queryField.labelTemplate ?? '{value}', value);
    _queryText = label;
    return _queryText;
  }

  ({String key, InstanceDataField schema, dynamic value})?
  get _resolvedAnswerField {
    final schema = widget.resolved.machine.instanceDataSchema;
    ({String key, InstanceDataField schema, dynamic value})? formulaField;
    ({String key, InstanceDataField schema, dynamic value})? fallback;
    var fallbackPriority = -1;

    for (final entry in schema.entries) {
      final key = entry.key;
      final field = entry.value;
      if (!_isVisibleField(key, field)) continue;

      final value = _instance.instanceData[key];
      if (field.formula != null && field.formula!.trim().isNotEmpty) {
        if (formulaField == null) {
          formulaField = (key: key, schema: field, value: value);
        }
        continue;
      }

      if (_isEmpty(value)) {
        continue;
      }
      final priority = _writablePriority(field);
      if (fallback == null || priority > fallbackPriority) {
        fallback = (key: key, schema: field, value: value);
        fallbackPriority = priority;
      }
    }

    return formulaField ?? fallback;
  }

  Map<String, WorkflowFactPillFieldSchema> _answerFacts() {
    final selected = _resolvedAnswerField;
    if (selected == null) return const {};
    return {
      selected.key: WorkflowFactPillFieldSchema(
        type: 'text',
        maxLength: selected.schema.maxLength,
        maxLines: 2,
        displayIcon: selected.schema.displayIcon,
        labelTemplate: 'Answer: {value}',
        hideWhenEmpty: selected.schema.hideWhenEmpty,
        displayContexts: selected.schema.displayContexts,
        openMode: selected.schema.openMode,
      ),
    };
  }

  Map<String, WorkflowFactPillFieldSchema> _citationsFacts() {
    final schema = widget.resolved.machine.instanceDataSchema['citations'];
    if (schema == null) return const {};
    if (widget.visibleFieldKeys != null &&
        !widget.visibleFieldKeys!.contains('citations')) {
      return const {};
    }
    if (schema.displayContexts != null &&
        !schema.displayContexts!.contains(widget.displayContext)) {
      return const {};
    }
    final value = _instance.instanceData['citations'];
    if (schema.hideWhenEmpty && _isEmpty(value)) {
      return const {};
    }
    if (_isEmpty(value) && !_loadingActions) {
      return const {};
    }
    final itemSchema = schema.itemSchema == null
        ? null
        : schema.itemSchema!.map(
            (itemKey, itemField) => MapEntry(
              itemKey,
              WorkflowFactPillFieldSchema(
                type: _baseType(itemField.type),
                maxLength: itemField.maxLength,
                maxLines: 2,
                displayIcon: itemField.displayIcon,
                labelTemplate: itemField.labelTemplate,
                hideWhenEmpty: itemField.hideWhenEmpty,
                displayContexts: itemField.displayContexts,
                openMode: itemField.openMode,
              ),
            ),
          );

    return {
      'citations': WorkflowFactPillFieldSchema(
        type: _baseType(schema.type),
        maxLength: schema.maxLength,
        maxLines: 2,
        displayIcon: schema.displayIcon,
        labelTemplate: schema.labelTemplate ?? '{value.length} sources',
        hideWhenEmpty: schema.hideWhenEmpty,
        displayContexts: schema.displayContexts,
        openMode: schema.openMode,
        itemSchema: itemSchema,
      ),
    };
  }

  WorkflowActionTone _toneFor(String? tone) => switch (tone) {
    'secondary' => WorkflowActionTone.secondary,
    'destructive' => WorkflowActionTone.destructive,
    _ => WorkflowActionTone.primary,
  };

  List<WorkflowActionButtonTransition> get _buttonTransitions => [
    for (final action in _actions)
      WorkflowActionButtonTransition(
        id: action.id,
        label: action.label,
        iconName: action.icon,
        tone: _toneFor(action.tone),
      ),
  ];

  bool get _hasAnswer =>
      _resolvedAnswerField != null && !_isEmpty(_resolvedAnswerField!.value);

  Future<void> _applyTransition(LoomWorkflowTransition transition) async {
    if (_mutating) return;
    final inputs = await _collectTransitionInputs(
      context: context,
      transition: transition,
      instanceData: _instance.instanceData,
    );
    if (inputs == null || !mounted || _mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final result = await widget.engine.applyTransition(
        workflowType: _instance.workflowType,
        instanceId: _instance.instanceId,
        transitionId: transition.id,
        fanId: widget.fanId,
        inputs: inputs,
      );
      final next = WorkflowInstance(
        instanceId: _instance.instanceId,
        workflowType: _instance.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByFanId: _instance.createdByFanId,
      );
      if (!mounted) return;
      setState(() {
        _instance = next;
        _mutating = false;
      });
      widget.onInstanceChanged(next);
      await _loadActions();
      if (!mounted) return;
      if (transition.effects.any(
            (effect) => effect.op == 'removeFromTileGrid',
          ) &&
          widget.displayContext == 'detail') {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mutating = false;
        _error = 'Could not update this answer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    final answerFacts = _answerFacts();
    final citationFacts = _citationsFacts();
    final query = _resolvedQuery;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (query != null && query.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Query',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: foreground.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        query,
                        key: ValueKey(
                          'search-ai-answer-query-${_instance.instanceId}-${widget.displayContext}',
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              if (_hasAnswer)
                WorkflowFactPillRow(
                  key: ValueKey(
                    'search-ai-answer-answer-${_instance.instanceId}-${widget.displayContext}',
                  ),
                  instanceData: _instance.instanceData,
                  instanceDataSchema: answerFacts,
                  displayContext: widget.displayContext,
                  foreground: foreground,
                  accent: widget.accent,
                )
              else
                Text(
                  'Waiting for an answer',
                  key: ValueKey(
                    'search-ai-answer-waiting-${_instance.instanceId}-${widget.displayContext}',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (citationFacts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Sources',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                WorkflowFactPillRow(
                  key: ValueKey(
                    'search-ai-answer-sources-${_instance.instanceId}-${widget.displayContext}',
                  ),
                  instanceData: _instance.instanceData,
                  instanceDataSchema: citationFacts,
                  displayContext: widget.displayContext,
                  foreground: foreground,
                  accent: widget.accent,
                ),
              ],
              if (_loadingActions || _mutating)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(
                    key: ValueKey(
                      'search-ai-answer-progress-${_instance.instanceId}',
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  key: ValueKey(
                    'search-ai-answer-error-${_instance.instanceId}',
                  ),
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!),
                ),
              if (!_loadingActions)
                WorkflowActionButtonRow(
                  surface: widget.displayContext == 'detail'
                      ? 'searchAiAnswer'
                      : 'searchAiAnswer-${_instance.instanceId}',
                  availableTransitions: _buttonTransitions,
                  onTransitionPressed: _mutating
                      ? null
                      : (transitionId) {
                          final transition = _actions.firstWhere(
                            (candidate) => candidate.id == transitionId,
                          );
                          unawaited(_applyTransition(transition));
                        },
                  foreground: foreground,
                  accent: widget.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
