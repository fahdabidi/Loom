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
        final personaId = resolveEnginePersonaId(widget.persona.personaId);
        return EngineNativeBindingDispatcher(
          engine: engine,
          definitions: definitions,
          tabId: 'marketplace',
          personaId: personaId,
          rolesForInstance: (instance, viewerPersonaId) =>
              instance.createdByPersonaId == viewerPersonaId
              ? const <String>['actor']
              : const <String>[],
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
                constraints.maxWidth > 380 ? 3 : 2,
            gridChildAspectRatio: 0.66,
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

  bool get _isGiveaway => _instance.workflowType == 'equipment-giveaway';

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
      if (field.displayContexts != null &&
          field.displayContexts!.isNotEmpty &&
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
