part of '../loom_communities_app_shell.dart';

/// Calendar-native projection for engine-declared Calendar bindings.
class EngineNativeCalendarSurface extends StatefulWidget {
  const EngineNativeCalendarSurface({
    super.key,
    required this.experience,
    required this.persona,
    required this.accent,
    required this.modernTheme,
    this.engine,
    this.onInstanceScopedCreate,
    this.onFocusedInstanceChanged,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final Color accent;
  final LoomCardTheme? modernTheme;

  /// A ready A.5 engine is useful to an embedding host. Normal tab routing
  /// leaves this null and resolves the installed shared engine itself.
  final WorkflowEngineApi? engine;
  final EngineNativeInstanceScopedCreate? onInstanceScopedCreate;
  final ValueChanged<WorkflowInstance?>? onFocusedInstanceChanged;

  @override
  State<EngineNativeCalendarSurface> createState() =>
      _EngineNativeCalendarSurfaceState();
}

class _EngineNativeCalendarSurfaceState
    extends State<EngineNativeCalendarSurface> {
  Future<WorkflowEngineApi>? _engineFuture;
  final _CalendarPresentationController _presentation =
      _CalendarPresentationController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EngineNativeCalendarSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.experience.extensionId != widget.experience.extensionId ||
        oldWidget.engine != widget.engine ||
        oldWidget.persona.personaId != widget.persona.personaId) {
      final hadSelection = _presentation.selectedInstance != null;
      _presentation.reset();
      if (hadSelection) _notifyFocusedInstanceChanged(null);
      _load();
    }
  }

  void _load() {
    final extensionId = widget.experience.extensionId;
    setState(() {
      // FutureBuilder ignores a completion belonging to a replaced future;
      // capture the extension ID now so the lookup itself cannot drift.
      _engineFuture = widget.engine == null
          ? workflowEngineForExtensionId(extensionId)
          : Future<WorkflowEngineApi>.value(widget.engine);
    });
  }

  void _notifyFocusedInstanceChanged(WorkflowInstance? instance) {
    final callback = widget.onFocusedInstanceChanged;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => callback(instance));
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
            key: const ValueKey('engine-native-calendar-error'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load Calendar: ${snapshot.error}'),
              TextButton(
                key: const ValueKey('engine-native-calendar-retry'),
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            key: ValueKey('engine-native-calendar-loading'),
          );
        }
        return EngineNativeBindingDispatcher(
          engine: snapshot.data!,
          definitions: definitions,
          tabId: 'calendar',
          personaId: resolveEnginePersonaId(widget.persona.personaId),
          builder: (context, bindings, changed) => _EngineNativeCalendarContent(
            key: ValueKey(
              'engine-native-calendar-content-${widget.experience.extensionId}-${widget.persona.personaId}',
            ),
            bindings: bindings,
            engine: snapshot.data!,
            communityExtensionId: widget.experience.extensionId,
            viewerPersonaId: widget.persona.personaId,
            personaId: resolveEnginePersonaId(widget.persona.personaId),
            accent: widget.accent,
            modernTheme: widget.modernTheme,
            onInstanceChanged: changed,
            onInstanceScopedCreate: widget.onInstanceScopedCreate,
            onFocusedInstanceChanged: widget.onFocusedInstanceChanged,
            presentation: _presentation,
          ),
        );
      },
    );
  }
}

class _CalendarPresentationController {
  String? selectedIdentity;
  String? selectedInstanceId;
  WorkflowInstance? selectedInstance;
  String? selectedDate;
  DateTime? month;

  void reset() {
    selectedIdentity = null;
    selectedInstanceId = null;
    selectedInstance = null;
    selectedDate = null;
    month = null;
  }
}

/// Calendar facts are opt-in through the detail context, or declaratively
/// configured with a label/icon when no contexts were specified. Shared by
/// generic Calendar details and the RSVP-specific detail surface.
bool _isCalendarDetailField(InstanceDataField field) {
  final contexts = field.displayContexts;
  final explicitDetail = contexts?.contains('detail') ?? false;
  final declarativeFact =
      (contexts == null || contexts.isEmpty) &&
      (field.labelTemplate != null || field.displayIcon != null);
  if (!explicitDetail && !declarativeFact) return false;
  // Lists are persistence structures, notably actor/persona collections.
  // Formula booleans are state guards rather than facts. Both remain
  // available to the engine, but are intentionally absent from Calendar UI.
  if (field.type.endsWith('[]') ||
      field.type == 'list' ||
      field.type == 'map' ||
      field.type == 'object' ||
      field.type == 'response-map' ||
      field.storage == 'reference') {
    return false;
  }
  if (field.type == 'bool' && field.formula != null) return false;
  return true;
}

class _CalendarEntry {
  const _CalendarEntry({
    required this.resolved,
    required this.date,
    required this.minutes,
  });

  final EngineNativeResolvedBinding resolved;
  final DateTime date;
  final int minutes;

  /// A definition binding ordinal is part of A.7's lossless identity. An
  /// instance may legitimately resolve more than one Calendar binding.
  String get identity => resolved.identity;
  String get instanceId => resolved.instance.instanceId;
  String get title =>
      '${resolved.instance.instanceData['title'] ?? instanceId}';
  String get dateKey => _calendarDay(date);
  String get time => '${resolved.instance.instanceData['eventTime'] ?? ''}';
}

class _CalendarProjectionException implements Exception {
  const _CalendarProjectionException(this.binding, this.message);

  final EngineNativeResolvedBinding binding;
  final String message;

  @override
  String toString() =>
      'Calendar data for ${binding.instance.instanceId} '
      '(binding ${binding.definitionBindingIndex}) is unsupported: $message';
}

class _EngineNativeCalendarContent extends StatefulWidget {
  const _EngineNativeCalendarContent({
    super.key,
    required this.bindings,
    required this.engine,
    required this.communityExtensionId,
    required this.viewerPersonaId,
    required this.personaId,
    required this.accent,
    required this.modernTheme,
    required this.onInstanceChanged,
    this.onInstanceScopedCreate,
    this.onFocusedInstanceChanged,
    required this.presentation,
  });

  final List<EngineNativeResolvedBinding> bindings;
  final WorkflowEngineApi engine;
  final String communityExtensionId;
  final String viewerPersonaId;
  final String personaId;
  final Color accent;
  final LoomCardTheme? modernTheme;
  final ValueChanged<WorkflowInstance> onInstanceChanged;
  final EngineNativeInstanceScopedCreate? onInstanceScopedCreate;
  final ValueChanged<WorkflowInstance?>? onFocusedInstanceChanged;
  final _CalendarPresentationController presentation;

  @override
  State<_EngineNativeCalendarContent> createState() =>
      _EngineNativeCalendarContentState();
}

class _EngineNativeCalendarContentState
    extends State<_EngineNativeCalendarContent> {
  @override
  void didUpdateWidget(covariant _EngineNativeCalendarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reconcileSelection(_tryEntries());
  }

  List<_CalendarEntry>? _tryEntries() {
    try {
      return _entries;
    } on _CalendarProjectionException {
      return null;
    }
  }

  void _reconcileSelection(List<_CalendarEntry>? entries) {
    if (entries == null || entries.isEmpty) {
      final hadSelection = widget.presentation.selectedInstance != null;
      widget.presentation.reset();
      if (hadSelection) _notifyFocusedInstanceChanged(null);
      return;
    }
    final exact = entries.where(
      (entry) => entry.identity == widget.presentation.selectedIdentity,
    );
    final sameInstance = entries.where(
      (entry) => entry.instanceId == widget.presentation.selectedInstanceId,
    );
    final next = exact.isNotEmpty
        ? exact.first
        : sameInstance.isNotEmpty
        ? sameInstance.first
        : entries.first;
    final changed = widget.presentation.selectedIdentity != next.identity;
    final dateChanged = widget.presentation.selectedDate != next.dateKey;
    _setSelectedEntry(next);
    if (changed || dateChanged || widget.presentation.selectedDate == null) {
      widget.presentation.selectedDate = next.dateKey;
      widget.presentation.month = DateTime(next.date.year, next.date.month);
    }
  }

  void _setSelectedEntry(_CalendarEntry entry) {
    final selectionChanged =
        widget.presentation.selectedIdentity != entry.identity;
    widget.presentation.selectedIdentity = entry.identity;
    widget.presentation.selectedInstanceId = entry.instanceId;
    widget.presentation.selectedInstance = entry.resolved.instance;
    if (selectionChanged) {
      _notifyFocusedInstanceChanged(entry.resolved.instance);
    }
  }

  void _notifyFocusedInstanceChanged(WorkflowInstance? instance) {
    final callback = widget.onFocusedInstanceChanged;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => callback(instance));
  }

  List<_CalendarEntry> get _entries {
    final value = <_CalendarEntry>[];
    for (final resolved in widget.bindings) {
      final data = resolved.instance.instanceData;
      final parsedDate = DateTime.tryParse('${data['eventDate'] ?? ''}');
      if (parsedDate == null) {
        throw _CalendarProjectionException(
          resolved,
          'event date is missing or invalid',
        );
      }
      final parts = '${data['eventTime'] ?? ''}'.split(':');
      final hour = int.tryParse(parts.first);
      final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
      if (hour == null || minute == null || hour > 23 || minute > 59) {
        throw _CalendarProjectionException(
          resolved,
          'event time is missing or invalid',
        );
      }
      value.add(
        _CalendarEntry(
          resolved: resolved,
          date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
          minutes: hour * 60 + minute,
        ),
      );
    }
    value.sort((a, b) {
      final date = a.date.compareTo(b.date);
      if (date != 0) return date;
      final time = a.minutes.compareTo(b.minutes);
      if (time != 0) return time;
      final instance = a.instanceId.compareTo(b.instanceId);
      return instance != 0
          ? instance
          : a.resolved.definitionBindingIndex.compareTo(
              b.resolved.definitionBindingIndex,
            );
    });
    return value;
  }

  Set<String> _detailFieldKeys(_CalendarEntry entry) => {
    for (final schema in entry.resolved.machine.instanceDataSchema.entries)
      if (_isCalendarDetailField(schema.value)) schema.key,
  };

  @override
  Widget build(BuildContext context) {
    final theme =
        widget.modernTheme ?? LoomCardTheme.deriveFromAccent(widget.accent);
    late final List<_CalendarEntry> entries;
    try {
      entries = _entries;
    } on _CalendarProjectionException catch (error) {
      return _CalendarProjectionError(
        error: error,
        onRetry: () => widget.onInstanceChanged(error.binding.instance),
      );
    }
    _reconcileSelection(entries);
    if (entries.isEmpty) return const _CalendarEmptyState();

    final selected = entries.firstWhere(
      (entry) => entry.identity == widget.presentation.selectedIdentity,
    );
    final month =
        widget.presentation.month ??
        DateTime(selected.date.year, selected.date.month);
    final byDay = <String, List<_CalendarEntry>>{};
    for (final entry in entries) {
      byDay.putIfAbsent(entry.dateKey, () => []).add(entry);
    }
    final dates = byDay.keys.toList()..sort();

    return Column(
      key: const ValueKey('engine-native-calendar-root'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          key: const ValueKey('engine-native-calendar-month-navigation'),
          children: [
            IconButton(
              key: const ValueKey('engine-native-calendar-previous-month'),
              onPressed: () => setState(
                () => widget.presentation.month = DateTime(
                  month.year,
                  month.month - 1,
                ),
              ),
              icon: Icon(Icons.chevron_left, color: theme.resolvedHeading),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_monthLabel(month.month)} ${month.year}',
                  style: TextStyle(color: theme.resolvedHeading),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('engine-native-calendar-next-month'),
              onPressed: () => setState(
                () => widget.presentation.month = DateTime(
                  month.year,
                  month.month + 1,
                ),
              ),
              icon: Icon(Icons.chevron_right, color: theme.resolvedHeading),
            ),
          ],
        ),
        _EngineNativeMonthGrid(
          month: month,
          byDay: byDay,
          onSelect: _selectEntry,
          modernTheme: theme,
          selectedDate: widget.presentation.selectedDate,
        ),
        const SizedBox(height: 12),
        SizedBox(
          key: const ValueKey('engine-native-calendar-date-strip'),
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final day in dates)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: ValueKey('engine-native-calendar-date-strip-$day'),
                    label: Text(
                      day,
                      style: TextStyle(color: theme.resolvedBody),
                    ),
                    backgroundColor: theme.resolvedFill,
                    selectedColor: (theme.accent ?? widget.accent).withValues(
                      alpha: 0.30,
                    ),
                    selected: day == widget.presentation.selectedDate,
                    onSelected: (_) => setState(() {
                      final entry = byDay[day]!.first;
                      widget.presentation.selectedDate = day;
                      _setSelectedEntry(entry);
                      widget.presentation.month = DateTime(
                        entry.date.year,
                        entry.date.month,
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Agenda',
          key: const ValueKey('engine-native-calendar-grouped-agenda'),
          style: TextStyle(color: theme.resolvedHeading),
        ),
        for (final day in dates)
          Container(
            key: ValueKey('engine-native-calendar-agenda-group-$day'),
            decoration: BoxDecoration(
              color: theme.resolvedFill,
              border: Border.all(color: theme.resolvedBorder),
            ),
            child: Column(
              children: [
                Text(
                  day,
                  key: ValueKey('engine-native-calendar-agenda-date-$day'),
                  style: TextStyle(color: theme.resolvedHeading),
                ),
                for (final entry in byDay[day]!)
                  ListTile(
                    key: ValueKey(
                      'engine-native-calendar-agenda-${entry.instanceId}-${entry.resolved.definitionBindingIndex}',
                    ),
                    selected:
                        entry.identity == widget.presentation.selectedIdentity,
                    title: Text(
                      entry.title,
                      style: TextStyle(color: theme.resolvedBody),
                    ),
                    subtitle: Text(
                      entry.time,
                      style: TextStyle(color: theme.resolvedBody),
                    ),
                    onTap: () => _selectEntry(entry.identity),
                  ),
              ],
            ),
          ),
        EngineNativeArchetypeCard(
          contentKey: ValueKey(
            'engine-native-calendar-selected-detail-${selected.instanceId}-${selected.resolved.definitionBindingIndex}',
          ),
          resolved: selected.resolved,
          engine: widget.engine,
          personaId: widget.personaId,
          accent: widget.accent,
          onInstanceChanged: widget.onInstanceChanged,
          onInstanceScopedCreate: widget.onInstanceScopedCreate,
          modernTheme: widget.modernTheme,
          displayContext: 'detail',
          showEditors: false,
          visibleFieldKeys: _detailFieldKeys(selected),
        ),
      ],
    );
  }

  void _selectEntry(String identity) {
    final entry = _entries.firstWhere(
      (candidate) => candidate.identity == identity,
    );
    setState(() {
      _setSelectedEntry(entry);
      widget.presentation.selectedDate = entry.dateKey;
      widget.presentation.month = DateTime(entry.date.year, entry.date.month);
    });
  }

}

class _EventRsvpDetailCard extends StatefulWidget {
  const _EventRsvpDetailCard({
    super.key,
    required this.instance,
    required this.machine,
    required this.engine,
    required this.personaId,
    required this.accent,
    required this.onInstanceChanged,
    this.instanceScopedCreateActions = const [],
    this.onInstanceScopedCreate,
  });

  final WorkflowInstance instance;
  final LoomWorkflowStateMachine machine;
  final WorkflowEngineApi engine;
  final String personaId;
  final Color accent;
  final ValueChanged<WorkflowInstance>? onInstanceChanged;
  final List<WorkflowAction> instanceScopedCreateActions;
  final Future<void> Function(WorkflowAction action)? onInstanceScopedCreate;

  @override
  State<_EventRsvpDetailCard> createState() => _EventRsvpDetailCardState();
}

class _EventRsvpDetailCardState extends State<_EventRsvpDetailCard> {
  static const _bespokeFieldKeys = <String>{
    'goingCount',
    'accepted',
    'capacity',
    'minimumAttendance',
    'seatsRemaining',
    'quorumMet',
    'isFull',
    'responses',
    'responseCounts',
    'maybeCount',
    'declinedCount',
    'waitlistedCount',
  };

  late WorkflowInstance _instance;
  List<LoomWorkflowTransition> _actions = const [];
  Set<String> _eventActionIds = const {};
  bool _loadingActions = true;
  bool _mutating = false;
  String? _error;
  Future<void> Function()? _retry;
  int _actionRequest = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _instance = widget.instance;
    _loadActions();
  }

  @override
  void didUpdateWidget(covariant _EventRsvpDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instance != widget.instance ||
        oldWidget.personaId != widget.personaId ||
        oldWidget.machine != widget.machine ||
        oldWidget.engine != widget.engine) {
      _actionRequest++;
      _generation++;
      _instance = widget.instance;
      _error = null;
      _retry = null;
      _actions = const [];
      _eventActionIds = const {};
      _loadingActions = true;
      _mutating = false;
      _loadActions();
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  bool _isCurrent(
    int generation,
    WorkflowInstance instance,
    LoomWorkflowStateMachine machine,
    WorkflowEngineApi engine,
    String personaId,
  ) =>
      mounted &&
      generation == _generation &&
      identical(_instance, instance) &&
      identical(widget.machine, machine) &&
      identical(widget.engine, engine) &&
      widget.personaId == personaId;

  /// `event-rsvp` stores a member's selection on that member's response row.
  /// Other workflow types can share this detail-card surface while retaining
  /// their own event-level action model.
  bool get _usesResponseRows => _instance.workflowType == 'event-rsvp';

  Map<String, dynamic>? get _viewerResponse {
    if (!_usesResponseRows) return null;
    final responses = _instance.instanceData['responses'];
    if (responses is! List) return null;
    for (final response in responses) {
      if (response is Map && response['personaId'] == widget.personaId) {
        return Map<String, dynamic>.from(response);
      }
    }
    return null;
  }

  Future<void> _loadActions() async {
    final generation = _generation;
    final instance = _instance;
    final machine = widget.machine;
    final engine = widget.engine;
    final personaId = widget.personaId;
    final response = _viewerResponse;
    final request = ++_actionRequest;
    if (_isCurrent(generation, instance, machine, engine, personaId)) {
      setState(() {
        _loadingActions = true;
        _actions = const [];
        _eventActionIds = const {};
        _error = null;
        _retry = null;
      });
    }
    if (_usesResponseRows && response == null) {
      if (_isCurrent(generation, instance, machine, engine, personaId) &&
          request == _actionRequest) {
        setState(() => _loadingActions = false);
      }
      return;
    }
    try {
      final eventActions = await engine.availableTransitionsAsync(
        workflowType: instance.workflowType,
        instanceId: instance.instanceId,
        currentState: instance.currentState,
        instanceData: instance.instanceData,
        personaId: personaId,
      );
      final responseActions = response == null
          ? const <LoomWorkflowTransition>[]
          : await engine.availableTransitionsAsync(
              workflowType: 'event-rsvp-response',
              instanceId: response['\$id'] as String,
              currentState: response['\$state'] as String,
              instanceData: response,
              personaId: personaId,
            );
      final result = response == null
          ? eventActions
          : <LoomWorkflowTransition>[...eventActions, ...responseActions];
      if (!_isCurrent(generation, instance, machine, engine, personaId) ||
          request != _actionRequest) {
        return;
      }
      setState(() {
        _actions = result;
        _eventActionIds = eventActions.map((action) => action.id).toSet();
        _loadingActions = false;
      });
    } catch (_) {
      if (!_isCurrent(generation, instance, machine, engine, personaId) ||
          request != _actionRequest) {
        return;
      }
      setState(() {
        _loadingActions = false;
        _error = 'Could not load available actions.';
        _retry = () => _loadActions();
      });
    }
  }

  Future<void> _applyTransition(String transitionId) {
    final generation = _generation;
    final instance = _instance;
    final machine = widget.machine;
    final engine = widget.engine;
    final personaId = widget.personaId;
    final response = _viewerResponse;
    final appliesToEvent = _eventActionIds.contains(transitionId);
    if (_usesResponseRows && response == null && !appliesToEvent) {
      return Future.value();
    }
    return _runMutation(
      generation: generation,
      instance: instance,
      machine: machine,
      engine: engine,
      personaId: personaId,
      operation: () async {
        final result = await engine.applyTransition(
          workflowType: response == null || appliesToEvent
              ? instance.workflowType
              : 'event-rsvp-response',
          instanceId: response == null || appliesToEvent
              ? instance.instanceId
              : response['\$id'] as String,
          transitionId: transitionId,
          personaId: personaId,
        );
        if (response != null && !appliesToEvent) {
          final page = await engine.queryInstances(
            tabId: 'calendar',
            personaId: personaId,
            limit: 100,
          );
          return page.items.singleWhere(
            (candidate) => candidate.instanceId == instance.instanceId,
          );
        }
        return WorkflowInstance(
          instanceId: instance.instanceId,
          workflowType: instance.workflowType,
          currentState: result.newState,
          instanceData: result.newInstanceData,
          createdByPersonaId: instance.createdByPersonaId,
        );
      },
      retry: () => _applyTransition(transitionId),
    );
  }

  Future<void> _runMutation({
    required int generation,
    required WorkflowInstance instance,
    required LoomWorkflowStateMachine machine,
    required WorkflowEngineApi engine,
    required String personaId,
    required Future<WorkflowInstance> Function() operation,
    required Future<void> Function() retry,
  }) async {
    if (_mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
      _retry = null;
    });
    try {
      final next = await operation();
      if (!_isCurrent(generation, instance, machine, engine, personaId)) return;
      _instance = next;
      widget.onInstanceChanged?.call(next);
      if (!_isCurrent(generation, next, machine, engine, personaId)) return;
      setState(() => _mutating = false);
      await _loadActions();
    } catch (_) {
      if (!_isCurrent(generation, instance, machine, engine, personaId)) return;
      setState(() {
        _mutating = false;
        _error = 'Could not save this change. Please try again.';
        _retry = retry;
      });
    }
  }

  WorkflowActionTone _toneFor(String? tone) => switch (tone) {
    'secondary' => WorkflowActionTone.secondary,
    'destructive' => WorkflowActionTone.destructive,
    _ => WorkflowActionTone.primary,
  };

  bool _isSelected(LoomWorkflowTransition action) {
    final response = _viewerResponse;
    if (response != null) {
      return switch (action.id) {
        'respond-going' => response['\$state'] == 'going',
        'respond-maybe' => response['\$state'] == 'maybe',
        'respond-declined' => response['\$state'] == 'declined',
        'respond-waitlist' => response['\$state'] == 'waitlisted',
        _ => false,
      };
    }
    final data = _instance.instanceData;
    final pid = widget.personaId;
    switch (action.id) {
      case 'rsvp-going':
        return (data['goingPersonaIds'] as List?)?.contains(pid) ?? false;
      case 'rsvp-maybe':
        return (data['maybePersonaIds'] as List?)?.contains(pid) ?? false;
      case 'rsvp-not-going':
        return (data['notGoingPersonaIds'] as List?)?.contains(pid) ?? false;
      case 'join-waitlist':
        return (data['waitlistPersonaIds'] as List?)?.contains(pid) ?? false;
      default:
        return false;
    }
  }

  List<LoomWorkflowTransition> get _displayActions {
    final response = _viewerResponse;
    if (response == null) return _actions;
    final selected = switch (response['\$state']) {
      'going' => const LoomWorkflowTransition(
        id: 'respond-going',
        label: 'Going',
        icon: 'event_available',
        tone: 'primary',
        from: <String>[],
      ),
      'maybe' => const LoomWorkflowTransition(
        id: 'respond-maybe',
        label: 'Maybe',
        icon: 'help_outline',
        tone: 'secondary',
        from: <String>[],
      ),
      'declined' => const LoomWorkflowTransition(
        id: 'respond-declined',
        label: "Can't go",
        icon: 'event_busy',
        tone: 'destructive',
        from: <String>[],
      ),
      'waitlisted' => const LoomWorkflowTransition(
        id: 'respond-waitlist',
        label: 'Join waitlist',
        icon: 'groups',
        tone: 'secondary',
        from: <String>[],
      ),
      _ => null,
    };
    if (selected == null ||
        (selected.id == 'respond-waitlist' &&
            _actions.any((action) => action.id == 'respond-going')) ||
        _actions.any((action) => action.id == selected.id)) {
      return _actions;
    }
    return <LoomWorkflowTransition>[selected, ..._actions];
  }

  Map<String, WorkflowFactPillFieldSchema> get _fallbackFactSchema => {
    for (final entry in widget.machine.instanceDataSchema.entries)
      if (!_bespokeFieldKeys.contains(entry.key) &&
          _isCalendarDetailField(entry.value))
        entry.key: WorkflowFactPillFieldSchema(
          displayIcon: entry.value.displayIcon,
          labelTemplate: entry.value.labelTemplate,
          hideWhenEmpty: entry.value.hideWhenEmpty,
          displayContexts: entry.value.displayContexts,
        ),
  };

  @override
  Widget build(BuildContext context) {
    final data = _instance.instanceData;
    final goingCount = (data['goingCount'] ?? data['accepted'] ?? 0) as num;
    final capacity =
        (data['capacity'] ?? data['minimumAttendance'] ?? 1) as num;
    final seatsRemaining = data['seatsRemaining'];
    final isFull = data['isFull'] as bool? ?? false;
    final quorumMet = data['quorumMet'];
    final response = _viewerResponse;
    final waitlistIds =
        (data['waitlistPersonaIds'] as List?)?.cast<String>() ??
        const <String>[];
    final onWaitlist = response == null
        ? waitlistIds.contains(widget.personaId)
        : response['\$state'] == 'waitlisted';

    final hasCapacityInfo =
        data.containsKey('capacity') || data.containsKey('minimumAttendance');
    final fallbackFactSchema = _fallbackFactSchema;
    final ratio = capacity == 0
        ? 0.0
        : (goingCount.toDouble() / capacity.toDouble()).clamp(0.0, 1.0);

    return Card(
      key: ValueKey('event-rsvp-card-${_instance.instanceId}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasCapacityInfo) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${goingCount.toInt()} / ${capacity.toInt()} going',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (seatsRemaining != null)
                          Text(
                            '${(seatsRemaining as num).toInt()} seats left',
                            style: TextStyle(
                              color: isFull
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (quorumMet != null)
                    Icon(
                      quorumMet == true
                          ? Icons.check_circle
                          : Icons.warning_amber,
                      color: quorumMet == true
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                  if (isFull && quorumMet == null)
                    const Icon(Icons.event_busy, color: Colors.red),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  key: ValueKey(
                    'event-rsvp-capacity-bar-${_instance.instanceId}',
                  ),
                  value: ratio,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  color: isFull
                      ? Theme.of(context).colorScheme.error
                      : widget.accent,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (onWaitlist)
              Container(
                key: ValueKey('event-rsvp-waitlist-${_instance.instanceId}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_empty,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You are on the waitlist',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            if (onWaitlist) const SizedBox(height: 12),
            if (fallbackFactSchema.isNotEmpty) ...[
              KeyedSubtree(
                key: ValueKey(
                  'event-rsvp-fallback-facts-${_instance.instanceId}',
                ),
                child: WorkflowFactPillRow(
                  instanceData: data,
                  instanceDataSchema: fallbackFactSchema,
                  displayContext: 'detail',
                  accent: widget.accent,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_loadingActions || _mutating)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  key: ValueKey('event-rsvp-progress-${_instance.instanceId}'),
                ),
              ),
            if (_error != null)
              Padding(
                key: ValueKey('event-rsvp-error-${_instance.instanceId}'),
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(_error!)),
                    TextButton(
                      key: ValueKey('event-rsvp-retry-${_instance.instanceId}'),
                      onPressed: _mutating ? null : () => _retry?.call(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (_usesResponseRows && response == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No response record is available for you for this event.',
                ),
              ),
            if (!_loadingActions) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in _displayActions)
                    _RsvpActionChip(
                      key: ValueKey(
                        'event-rsvp-${_instance.instanceId}-action-${action.id}',
                      ),
                      label: action.label,
                      iconName: action.icon,
                      tone: _toneFor(action.tone),
                      selected: _isSelected(action),
                      onPressed:
                          _mutating ||
                              (_usesResponseRows && _isSelected(action))
                          ? null
                          : () => _applyTransition(action.id),
                    ),
                ],
              ),
              if (widget.instanceScopedCreateActions.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final action in widget.instanceScopedCreateActions)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton(
                      key: ValueKey(
                        'instance-create-action-${_instance.instanceId}-${action.workflowType}',
                      ),
                      onPressed: _mutating ||
                              widget.onInstanceScopedCreate == null
                          ? null
                          : () => widget.onInstanceScopedCreate!(action),
                      child: Text(action.label ?? 'Create ${action.workflowType}'),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _RsvpActionChip extends StatelessWidget {
  const _RsvpActionChip({
    super.key,
    required this.label,
    required this.iconName,
    required this.tone,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String? iconName;
  final WorkflowActionTone tone;
  final bool selected;
  final VoidCallback? onPressed;

  static IconData _iconFor(String name) => switch (name) {
    'event_available' => Icons.event_available,
    'event_busy' => Icons.event_busy,
    'help_outline' => Icons.help_outline,
    'groups' => Icons.groups,
    'cancel' => Icons.cancel,
    _ => Icons.touch_app,
  };

  @override
  Widget build(BuildContext context) {
    final Color toneColor = switch (tone) {
      WorkflowActionTone.primary => Theme.of(context).colorScheme.primary,
      WorkflowActionTone.secondary => Theme.of(context).colorScheme.outline,
      WorkflowActionTone.destructive => Theme.of(context).colorScheme.error,
    };
    return InputChip(
      avatar: iconName != null
          ? Icon(_iconFor(iconName!), size: 18, color: toneColor)
          : null,
      label: Text(label),
      selected: selected,
      onPressed: onPressed,
      selectedColor: toneColor.withValues(alpha: 0.2),
      backgroundColor: toneColor.withValues(alpha: 0.08),
      side: BorderSide(
        color: selected ? toneColor : toneColor.withValues(alpha: 0.4),
      ),
      checkmarkColor: toneColor,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CalendarEmptyState extends StatelessWidget {
  const _CalendarEmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    key: ValueKey('engine-native-calendar-empty'),
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Text('No events are scheduled yet.'),
    ),
  );
}

class _CalendarProjectionError extends StatelessWidget {
  const _CalendarProjectionError({required this.error, required this.onRetry});
  final _CalendarProjectionException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    key: ValueKey(
      'engine-native-calendar-projection-error-${error.binding.identity}',
    ),
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Could not show ${error.binding.instance.instanceId}: ${error.message}',
      ),
      TextButton(
        key: const ValueKey('engine-native-calendar-projection-retry'),
        onPressed: onRetry,
        child: const Text('Retry'),
      ),
    ],
  );
}

class _EngineNativeMonthGrid extends StatelessWidget {
  const _EngineNativeMonthGrid({
    required this.month,
    required this.byDay,
    required this.onSelect,
    required this.modernTheme,
    required this.selectedDate,
  });

  final DateTime month;
  final Map<String, List<_CalendarEntry>> byDay;
  final ValueChanged<String> onSelect;
  final LoomCardTheme modernTheme;
  final String? selectedDate;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final start = first.subtract(Duration(days: first.weekday - 1));
    return Column(
      key: const ValueKey('engine-native-calendar-month-grid'),
      children: [
        for (var week = 0; week < 6; week++)
          Row(
            children: [
              for (var weekday = 0; weekday < 7; weekday++)
                Builder(
                  builder: (context) {
                    final date = start.add(Duration(days: week * 7 + weekday));
                    final events =
                        byDay[_calendarDay(date)] ?? const <_CalendarEntry>[];
                    final dateKey = _calendarDay(date);
                    final selected = dateKey == selectedDate;
                    return Expanded(
                      child: Container(
                        key: ValueKey('engine-native-calendar-date-$dateKey'),
                        constraints: const BoxConstraints(minHeight: 52),
                        decoration: BoxDecoration(
                          color: selected
                              ? Color.alphaBlend(
                                  (modernTheme.accent ?? Colors.transparent)
                                      .withValues(alpha: 0.24),
                                  modernTheme.resolvedFill,
                                )
                              : modernTheme.resolvedFill,
                          border: Border.all(color: modernTheme.resolvedBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: modernTheme.resolvedHeading,
                              ),
                            ),
                            for (final entry in events)
                              InkWell(
                                key: ValueKey(
                                  'engine-native-calendar-entry-${entry.instanceId}-${entry.resolved.definitionBindingIndex}',
                                ),
                                onTap: () => onSelect(entry.identity),
                                child: Text(
                                  entry.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: modernTheme.resolvedBody,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}

String _calendarDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
