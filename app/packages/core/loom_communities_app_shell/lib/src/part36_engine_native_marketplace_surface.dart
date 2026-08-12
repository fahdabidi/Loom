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
    required this.persona,
    required this.accent,
    this.modernTheme,
    this.engine,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
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
        oldWidget.persona.personaId != widget.persona.personaId ||
        oldWidget.persona.accountId != widget.persona.accountId) {
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
    String viewerPersonaId,
  ) {
    final definitions = widget.experience.workflowDefinitions;
    if (definitions == null) return const <String>[];
    final machine = definitions[instance.workflowType];
    if (machine == null) return const <String>[];
    return deriveInstanceRoles(
      machine,
      instance,
      viewerPersonaId: viewerPersonaId,
      viewerPersonaTypeId: widget.persona.personaId,
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
        final personaId = ActiveIdentityScope.of(
          context,
        ).resolveEnginePersonaId(widget.persona.personaId);
        return EngineNativeBindingDispatcher(
          engine: engine,
          definitions: definitions,
          tabId: 'marketplace',
          personaId: personaId,
          rolesForInstance: _stableMarketplaceRolesForInstance,
          builder: (context, bindings, changed) =>
              _EngineNativeMarketplaceContent(
                bindings: bindings,
                engine: engine,
                personaId: personaId,
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
    required this.personaId,
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
  final String personaId;
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
              personaId: personaId,
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
                  personaId: personaId,
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
/// persona guards are authoritative.
class EquipmentLoanArchetypeCard extends StatefulWidget {
  const EquipmentLoanArchetypeCard({
    super.key,
    required this.resolved,
    required this.engine,
    required this.personaId,
    required this.accent,
    required this.onInstanceChanged,
    this.modernTheme,
    this.displayContext = 'tile',
    this.visibleFieldKeys,
  }) : assert(displayContext == 'tile' || displayContext == 'detail');

  final EngineNativeResolvedBinding resolved;
  final WorkflowEngineApi engine;
  final String personaId;
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
        oldWidget.personaId != widget.personaId ||
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
        personaId: widget.personaId,
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

  bool get _isGiveaway =>
      widget.resolved.machine.transitions.any((transition) => transition.id == 'claim');

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
        // names explicitly (title/holderPersonaId/claimedByPersonaId) --
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
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final result = await widget.engine.applyTransition(
        workflowType: _instance.workflowType,
        instanceId: _instance.instanceId,
        transitionId: transition.id,
        personaId: widget.personaId,
      );
      final next = WorkflowInstance(
        instanceId: _instance.instanceId,
        workflowType: _instance.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByPersonaId: _instance.createdByPersonaId,
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
/// Like existing marketplace archetypes, this card uses real transition
/// availability from the engine and only renders each action when both the
/// transition and the expected persona-list field are declared for this
/// workflow definition.
class DocumentLibraryArchetypeCard extends StatefulWidget {
  const DocumentLibraryArchetypeCard({
    super.key,
    required this.resolved,
    required this.engine,
    required this.personaId,
    required this.accent,
    required this.onInstanceChanged,
    this.modernTheme,
    this.displayContext = 'tile',
    this.visibleFieldKeys,
  }) : assert(displayContext == 'tile' || displayContext == 'detail');

  final EngineNativeResolvedBinding resolved;
  final WorkflowEngineApi engine;
  final String personaId;
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
  static const _actionPersonaFields = <String, String>{
    'record-resource-open': 'openedPersonaIds',
    'acknowledge-resource': 'acknowledgedPersonaIds',
    'mark-resource-unread': 'acknowledgedPersonaIds',
    'request-resource-access': 'accessRequestedPersonaIds',
    'save-resource': 'savedPersonaIds',
    'record-resource-download': 'downloadedPersonaIds',
    'request-resource-follow-up': 'followUpRequestedPersonaIds',
  };

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
        oldWidget.personaId != widget.personaId ||
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
        personaId: widget.personaId,
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

  String? _requiredPersonaField(String transitionId) =>
      _actionPersonaFields[transitionId];

  bool _isActionDeclared(LoomWorkflowTransition action) {
    final personaField = _requiredPersonaField(action.id);
    return personaField != null &&
        widget.resolved.machine.instanceDataSchema.containsKey(personaField);
  }

  List<WorkflowActionButtonTransition> get _buttonTransitions {
    final transitions = <WorkflowActionButtonTransition>[];
    for (final action in _actions) {
      if (!_isActionDeclared(action)) continue;
      transitions.add(
        WorkflowActionButtonTransition(
          id: action.id,
          label: action.label,
          iconName: action.icon,
          tone: _toneFor(action.tone),
        ),
      );
    }
    return transitions;
  }

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

  Future<void> _applyTransition(LoomWorkflowTransition transition) async {
    if (_mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final result = await widget.engine.applyTransition(
        workflowType: _instance.workflowType,
        instanceId: _instance.instanceId,
        transitionId: transition.id,
        personaId: widget.personaId,
      );
      final next = WorkflowInstance(
        instanceId: _instance.instanceId,
        workflowType: _instance.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByPersonaId: _instance.createdByPersonaId,
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

/// Bespoke rendering for the searchAiAnswer card family.
class SearchAiAnswerArchetypeCard extends StatefulWidget {
  const SearchAiAnswerArchetypeCard({
    super.key,
    required this.resolved,
    required this.engine,
    required this.personaId,
    required this.accent,
    required this.onInstanceChanged,
    this.modernTheme,
    this.displayContext = 'tile',
    this.visibleFieldKeys,
  }) : assert(displayContext == 'tile' || displayContext == 'detail');

  final EngineNativeResolvedBinding resolved;
  final WorkflowEngineApi engine;
  final String personaId;
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
        oldWidget.personaId != widget.personaId ||
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
        personaId: widget.personaId,
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
    if (normalized.endsWith('?')) return normalized.substring(0, normalized.length - 1);
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

  ({String key, InstanceDataField schema, dynamic value})? get _resolvedAnswerField {
    final schema = widget.resolved.machine.instanceDataSchema;
    ({String key, InstanceDataField schema, dynamic value})? formulaField;
    ({String key, InstanceDataField schema, dynamic value})? fallback;
    var fallbackPriority = -1;

    for (final entry in schema.entries) {
      final key = entry.key;
      final field = entry.value;
      if (!_isVisibleField(key, field)) continue;

      final value = _instance.instanceData[key];
      if (field.formula != null &&
          field.formula!.trim().isNotEmpty) {
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
      _resolvedAnswerField != null &&
      !_isEmpty(_resolvedAnswerField!.value);

  Future<void> _applyTransition(LoomWorkflowTransition transition) async {
    if (_mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final result = await widget.engine.applyTransition(
        workflowType: _instance.workflowType,
        instanceId: _instance.instanceId,
        transitionId: transition.id,
        personaId: widget.personaId,
      );
      final next = WorkflowInstance(
        instanceId: _instance.instanceId,
        workflowType: _instance.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByPersonaId: _instance.createdByPersonaId,
      );
      if (!mounted) return;
      setState(() {
        _instance = next;
        _mutating = false;
      });
      widget.onInstanceChanged(next);
      await _loadActions();
      if (!mounted) return;
      if (transition.effects.any((effect) => effect.op == 'removeFromTileGrid') &&
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
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
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
