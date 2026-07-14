part of '../loom_communities_app_shell.dart';

/// Calendar-native projection for engine-declared Calendar bindings.
class EngineNativeCalendarSurface extends StatefulWidget {
  const EngineNativeCalendarSurface({
    super.key,
    required this.experience,
    required this.persona,
    required this.accent,
    this.engine,
  });

  final LoomExperienceDefinition experience;
  final LoomPersonaDefinition persona;
  final Color accent;

  /// A ready A.5 engine is useful to an embedding host. Normal tab routing
  /// leaves this null and resolves the installed shared engine itself.
  final WorkflowEngineApi? engine;

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
      _presentation.reset();
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
          personaId: widget.persona.personaId,
          builder: (context, bindings, changed) => _EngineNativeCalendarContent(
            key: ValueKey(
              'engine-native-calendar-content-${widget.experience.extensionId}-${widget.persona.personaId}',
            ),
            bindings: bindings,
            engine: snapshot.data!,
            personaId: widget.persona.personaId,
            accent: widget.accent,
            onInstanceChanged: changed,
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
  String? selectedDate;
  DateTime? month;

  void reset() {
    selectedIdentity = null;
    selectedInstanceId = null;
    selectedDate = null;
    month = null;
  }
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
    required this.personaId,
    required this.accent,
    required this.onInstanceChanged,
    required this.presentation,
  });

  final List<EngineNativeResolvedBinding> bindings;
  final WorkflowEngineApi engine;
  final String personaId;
  final Color accent;
  final ValueChanged<WorkflowInstance> onInstanceChanged;
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
      widget.presentation.reset();
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
    widget.presentation.selectedIdentity = next.identity;
    widget.presentation.selectedInstanceId = next.instanceId;
    if (changed || dateChanged || widget.presentation.selectedDate == null) {
      widget.presentation.selectedDate = next.dateKey;
      widget.presentation.month = DateTime(next.date.year, next.date.month);
    }
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
        field.storage == 'reference')
      return false;
    if (field.type == 'bool' && field.formula != null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text('${_monthLabel(month.month)} ${month.year}'),
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
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        _EngineNativeMonthGrid(
          month: month,
          byDay: byDay,
          onSelect: _selectEntry,
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
                    label: Text(day),
                    selected: day == widget.presentation.selectedDate,
                    onSelected: (_) => setState(() {
                      final entry = byDay[day]!.first;
                      widget.presentation.selectedDate = day;
                      widget.presentation.selectedIdentity = entry.identity;
                      widget.presentation.selectedInstanceId = entry.instanceId;
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
        const Text(
          'Agenda',
          key: ValueKey('engine-native-calendar-grouped-agenda'),
        ),
        for (final day in dates)
          Container(
            key: ValueKey('engine-native-calendar-agenda-group-$day'),
            child: Column(
              children: [
                Text(
                  day,
                  key: ValueKey('engine-native-calendar-agenda-date-$day'),
                ),
                for (final entry in byDay[day]!)
                  ListTile(
                    key: ValueKey(
                      'engine-native-calendar-agenda-${entry.instanceId}-${entry.resolved.definitionBindingIndex}',
                    ),
                    selected:
                        entry.identity == widget.presentation.selectedIdentity,
                    title: Text(entry.title),
                    subtitle: Text(entry.time),
                    onTap: () => _selectEntry(entry.identity),
                  ),
              ],
            ),
          ),
        GenericWorkflowInstanceCard(
          key: ValueKey(
            'engine-native-calendar-selected-detail-${selected.instanceId}-${selected.resolved.definitionBindingIndex}',
          ),
          instance: selected.resolved.instance,
          machine: selected.resolved.machine,
          engine: widget.engine,
          personaId: widget.personaId,
          displayContext: 'detail',
          showEditors: false,
          visibleFieldKeys: _detailFieldKeys(selected),
          accent: widget.accent,
          onInstanceChanged: widget.onInstanceChanged,
        ),
      ],
    );
  }

  void _selectEntry(String identity) {
    final entry = _entries.firstWhere(
      (candidate) => candidate.identity == identity,
    );
    setState(() {
      widget.presentation.selectedIdentity = identity;
      widget.presentation.selectedInstanceId = entry.instanceId;
      widget.presentation.selectedDate = entry.dateKey;
      widget.presentation.month = DateTime(entry.date.year, entry.date.month);
    });
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
  });

  final DateTime month;
  final Map<String, List<_CalendarEntry>> byDay;
  final ValueChanged<String> onSelect;

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
                    return Expanded(
                      child: Container(
                        key: ValueKey(
                          'engine-native-calendar-date-${_calendarDay(date)}',
                        ),
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${date.day}'),
                            for (final entry in events)
                              InkWell(
                                key: ValueKey(
                                  'engine-native-calendar-entry-${entry.instanceId}-${entry.resolved.definitionBindingIndex}',
                                ),
                                onTap: () => onSelect(entry.identity),
                                child: Text(
                                  entry.title,
                                  overflow: TextOverflow.ellipsis,
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
