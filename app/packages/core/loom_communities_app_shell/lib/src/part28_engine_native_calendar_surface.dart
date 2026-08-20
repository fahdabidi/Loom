part of '../loom_communities_app_shell.dart';

/// Serializes Calendar writes that share one engine connection. The local
/// engine uses one SQLite connection, so overlapping transactions can fail
/// even when they target different workflow rows.
class _EngineNativeMutationQueue {
  final List<Future<void> Function()> _foregroundJobs =
      <Future<void> Function()>[];
  final List<Future<void> Function()> _reminderJobs =
      <Future<void> Function()>[];
  bool _running = false;
  int _foregroundDemand = 0;
  final Set<String> _reminderInFlight = <String>{};
  final Set<String> _reminderSent = <String>{};

  /// Enqueues a user-visible mutation and registers its demand synchronously.
  ///
  /// Registering before [operation] waits is what lets an active reminder
  /// yield after its freshness read, instead of reserving a FIFO slot that
  /// blocks the foreground action.
  Future<T> runForeground<T>(Future<T> Function() operation) {
    _foregroundDemand++;
    final result = Completer<T>();
    _foregroundJobs.add(() async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      } finally {
        _foregroundDemand--;
      }
    });
    _drain();
    return result.future;
  }

  Future<bool> runReminder(
    String responseId,
    Future<bool> Function(bool Function() shouldYieldToForeground) operation,
  ) {
    if (!_reminderInFlight.add(responseId)) return Future<bool>.value(false);
    final result = Completer<bool>();
    _reminderJobs.add(() async {
      try {
        if (_reminderSent.contains(responseId)) {
          result.complete(false);
          return;
        }
        final sent = await operation(() => _foregroundDemand > 0);
        if (sent) _reminderSent.add(responseId);
        result.complete(sent);
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      } finally {
        _reminderInFlight.remove(responseId);
      }
    });
    _drain();
    return result.future;
  }

  void _drain() {
    if (_running) return;
    final jobs = _foregroundJobs.isNotEmpty ? _foregroundJobs : _reminderJobs;
    if (jobs.isEmpty) return;
    final job = jobs.removeAt(0);
    _running = true;
    unawaited(_runJob(job));
  }

  Future<void> _runJob(Future<void> Function() job) async {
    try {
      await job();
    } finally {
      _running = false;
      _drain();
    }
  }
}

final Expando<_EngineNativeMutationQueue> _engineNativeMutationQueues =
    Expando<_EngineNativeMutationQueue>();

_EngineNativeMutationQueue _engineNativeMutationQueueFor(
  WorkflowEngineApi engine,
) => _engineNativeMutationQueues[engine] ??= _EngineNativeMutationQueue();

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
    this.currentDate = DateTime.now,
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

  /// Kept injectable so the agenda's today bezel can be exercised without
  /// coupling widget tests to the host clock.
  final DateTime Function() currentDate;

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
        final identity = ActiveIdentityScope.of(context);
        final personaId = identity.resolveEnginePersonaId(
          widget.persona.personaId,
        );
        return EngineNativeBindingDispatcher(
          engine: snapshot.data!,
          definitions: definitions,
          tabId: 'calendar',
          personaId: personaId,
          rolesForInstance: (instance, viewerPersonaId) {
            final machine = definitions[instance.workflowType];
            if (machine == null) return const <String>{};
            return deriveInstanceRoles(
              machine,
              instance,
              viewerPersonaId: viewerPersonaId,
              viewerPersonaTypeId: widget.persona.personaId,
            );
          },
          builder: (context, bindings, changed) => _EngineNativeCalendarContent(
            key: ValueKey(
              'engine-native-calendar-content-${widget.experience.extensionId}-${widget.persona.personaId}',
            ),
            bindings: bindings,
            engine: snapshot.data!,
            communityExtensionId: widget.experience.extensionId,
            viewerPersonaId: widget.persona.personaId,
            personaId: personaId,
            accent: widget.accent,
            calendarDateRailEntries: widget.experience.calendarDateRailEntries,
            currentDate: widget.currentDate,
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
  String scope = 'month';
  final Set<String> activeFacets = <String>{};
  final Map<String, String?> activeTextFacetValues = <String, String?>{};

  void reset() {
    selectedIdentity = null;
    selectedInstanceId = null;
    selectedInstance = null;
    selectedDate = null;
    month = null;
    scope = 'month';
    activeFacets.clear();
    activeTextFacetValues.clear();
  }
}

enum _CalendarFacetKind { boolean, textValue, numericStat }

class _CalendarFacet {
  const _CalendarFacet({
    required this.field,
    required this.label,
    required this.kind,
  });

  final String field;
  final String label;
  final _CalendarFacetKind kind;
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

/// Compact agenda facts are explicitly opt-in. Unlike detail facts, an
/// unspecified display context must not make the already-dense agenda noisy.
bool _isCalendarTileField(InstanceDataField field) =>
    field.displayContexts?.contains('tile') ?? false;

/// Editing visibility uses the engine's formula language, evaluated against
/// the in-progress values supplied by the editor rather than persisted data.
bool _isEditingFieldVisible(
  InstanceDataField field,
  Map<String, dynamic> values,
) {
  final formula = field.visibleWhenEditing;
  if (formula == null) return true;
  return evaluateFormula(formula, instanceData: values) == true;
}

/// Fields owned by the Calendar's specialized event presentation rather than
/// either its generic fallback facts or compact agenda pills.
const _calendarBespokeFieldKeys = <String>{
  'title',
  'eventDate',
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

/// The compact row also owns event time in its ListTile subtitle.
const _calendarTileBespokeFieldKeys = <String>{
  ..._calendarBespokeFieldKeys,
  'eventTime',
};

class _CalendarEntry {
  const _CalendarEntry({
    required this.resolved,
    required this.date,
    required this.minutes,
  });

  final EngineNativeResolvedBinding resolved;
  final DateTime date;
  final int minutes;

  /// Bindings are losslessly identified by A.7, while Calendar projections
  /// also need to distinguish each date an individual binding spans.
  String get identity => '${resolved.identity}#${dateKey}';
  String get instanceId => resolved.instance.instanceId;
  String get title =>
      '${resolved.instance.instanceData['title'] ?? instanceId}';
  String get dateKey => _calendarDay(date);
  String get time => '${resolved.instance.instanceData['eventTime'] ?? ''}';
}

const Set<String> _hiddenAutomaticActionIds = {'send-reminder'};

class _ViewerResponseLookup {
  const _ViewerResponseLookup.invalid() : isValid = false, response = null;
  const _ViewerResponseLookup.noResponse() : isValid = true, response = null;
  const _ViewerResponseLookup.found(this.response) : isValid = true;

  final bool isValid;
  final Map<String, dynamic>? response;
}

/// Resolves a calendar entry's optional declarative style slot. Bindings that
/// do not opt in keep their exact flat community accent.
Color _calendarEntryStyleColor(_CalendarEntry entry, Color accent) {
  final styleField = entry.resolved.binding.styleField;
  if (styleField == null) return accent;
  final styleId =
      (entry.resolved.instance.instanceData[styleField] as num?)?.toInt() ?? 0;
  final palette = stylePaletteFrom(accent);
  return palette[styleId % palette.length];
}

const _defaultCalendarDateRailEntries = <CalendarDateRailEntry>[
  CalendarDateRailEntry(
    kind: 'dateToken',
    token: 'weekdayAbbrev',
    style: 'label',
  ),
  CalendarDateRailEntry(
    kind: 'dateToken',
    token: 'dayOfMonth',
    style: 'circleHighlight',
    colorSource: 'accent',
  ),
];

const _calendarWeekdayAbbreviations = <String>[
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
  'SUN',
];

const _calendarMonthAbbreviations = <String>[
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

String _calendarDateRailValue(
  CalendarDateRailEntry entry,
  DateTime date,
  List<_CalendarEntry> dayEntries,
) {
  if (entry.kind == 'dateToken') {
    switch (entry.token) {
      case 'weekdayAbbrev':
        return _calendarWeekdayAbbreviations[date.weekday - 1];
      case 'dayOfMonth':
        return '${date.day}';
      case 'monthAbbrev':
        return _calendarMonthAbbreviations[date.month - 1];
      case 'year':
        return '${date.year}';
    }
  }
  if (entry.kind == 'formula' && entry.formula != null) {
    try {
      final value = evaluateFormula(
        entry.formula!,
        instanceData: <String, dynamic>{
          'dayInstances': <Map<String, dynamic>>[
            for (final calendarEntry in dayEntries)
              calendarEntry.resolved.instance.instanceData,
          ],
        },
      );
      return '$value';
    } catch (_) {
      return '';
    }
  }
  return '';
}

Color _calendarDateRailColor(
  CalendarDateRailEntry entry,
  List<_CalendarEntry> dayEntries,
  Color accent,
) => entry.colorSource == 'styleField' && dayEntries.isNotEmpty
    ? _calendarEntryStyleColor(dayEntries.first, accent)
    : accent;

Widget _calendarDateRailWidget({
  required CalendarDateRailEntry entry,
  required String value,
  required Color color,
  required bool isToday,
  required LoomCardTheme theme,
  required Key key,
  Key? legacyTodayKey,
}) {
  switch (entry.style) {
    case 'circleHighlight':
      return Container(
        key: legacyTodayKey ?? key,
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: isToday
            ? BoxDecoration(color: color, shape: BoxShape.circle)
            : null,
        child: Text(
          value,
          style: TextStyle(
            color: theme.resolvedHeading,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    case 'badge':
      return Container(
        key: key,
        constraints: const BoxConstraints(minHeight: 20),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          border: Border.all(color: color.withValues(alpha: 0.75)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    case 'label':
    default:
      return Text(
        value,
        key: key,
        style: TextStyle(
          color: theme.resolvedBody,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
  }
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
    this.calendarDateRailEntries,
    required this.currentDate,
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
  final List<CalendarDateRailEntry>? calendarDateRailEntries;
  final DateTime Function() currentDate;
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
  final Set<String> _reminderCheckInFlight = <String>{};

  @override
  void initState() {
    super.initState();
    _scheduleDueReminders();
  }

  @override
  void didUpdateWidget(covariant _EngineNativeCalendarContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bindingsChanged = !identical(widget.bindings, oldWidget.bindings);
    _reconcileSelection(_tryEntries());
    if (bindingsChanged) _scheduleDueReminders();
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
    _setSelectedEntry(next);
    if (changed || widget.presentation.selectedDate == null) {
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
      final allDay = data['allDay'] == true;
      if (!allDay &&
          (hour == null || minute == null || hour > 23 || minute > 59)) {
        throw _CalendarProjectionException(
          resolved,
          'event time is missing or invalid',
        );
      }
      final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      final parsedEndDate = DateTime.tryParse('${data['eventEndDate'] ?? ''}');
      final end = parsedEndDate != null && parsedEndDate.isAfter(start)
          ? DateTime(parsedEndDate.year, parsedEndDate.month, parsedEndDate.day)
          : start;
      for (
        var date = start;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))
      ) {
        value.add(
          _CalendarEntry(
            resolved: resolved,
            date: date,
            minutes: allDay ? 0 : hour! * 60 + minute!,
          ),
        );
      }
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

  Map<String, WorkflowFactPillFieldSchema> _tileFactSchema(
    _CalendarEntry entry,
  ) => {
    for (final schema in entry.resolved.machine.instanceDataSchema.entries)
      if (!_calendarTileBespokeFieldKeys.contains(schema.key) &&
          _isCalendarTileField(schema.value))
        schema.key: WorkflowFactPillFieldSchema(
          type: schema.value.type,
          maxLength: schema.value.maxLength,
          displayIcon: schema.value.displayIcon,
          labelTemplate: schema.value.labelTemplate,
          hideWhenEmpty: schema.value.hideWhenEmpty,
          displayContexts: schema.value.displayContexts,
        ),
  };

  List<_CalendarEntry> _entriesForScope(List<_CalendarEntry> entries) {
    switch (widget.presentation.scope) {
      case 'day':
        return entries
            .where((entry) => entry.dateKey == widget.presentation.selectedDate)
            .toList();
      case 'week':
        final selectedDate = DateTime.tryParse(
          widget.presentation.selectedDate ?? '',
        );
        if (selectedDate == null) return const [];
        final start = selectedDate.subtract(
          Duration(days: selectedDate.weekday % DateTime.daysPerWeek),
        );
        final end = start.add(const Duration(days: 6));
        return entries
            .where(
              (entry) =>
                  !entry.date.isBefore(start) && !entry.date.isAfter(end),
            )
            .toList();
      case 'pending':
        return entries.where(_isPendingForViewer).toList();
      case 'month':
      default:
        return entries;
    }
  }

  List<_CalendarFacet> _facetsForEntries(List<_CalendarEntry> entries) {
    final facets = <String, _CalendarFacet>{};
    for (final entry in entries) {
      for (final facet
          in entry.resolved.binding.filterableFacets ??
              const <FilterableFacetSpec>[]) {
        facets.putIfAbsent(
          facet.field,
          () => _CalendarFacet(
            field: facet.field,
            label: facet.label,
            kind: switch (entry
                .resolved
                .machine
                .instanceDataSchema[facet.field]
                ?.type) {
              'bool' => _CalendarFacetKind.boolean,
              'text' => _CalendarFacetKind.textValue,
              _ => _CalendarFacetKind.numericStat,
            },
          ),
        );
      }
    }
    return facets.values.toList();
  }

  bool _bindingDeclaresFacet(_CalendarEntry entry, String field) =>
      entry.resolved.binding.filterableFacets?.any(
        (facet) => facet.field == field,
      ) ??
      false;

  List<_CalendarEntry> _entriesForActiveFacets(List<_CalendarEntry> entries) =>
      entries.where((entry) {
        for (final field in widget.presentation.activeFacets) {
          if (_bindingDeclaresFacet(entry, field) &&
              entry.resolved.instance.instanceData[field] != true) {
            return false;
          }
        }
        for (final selection
            in widget.presentation.activeTextFacetValues.entries) {
          if (selection.value != null &&
              _bindingDeclaresFacet(entry, selection.key) &&
              entry.resolved.instance.instanceData[selection.key] !=
                  selection.value) {
            return false;
          }
        }
        return true;
      }).toList();

  num _facetTotal(List<_CalendarEntry> entries, String field) => entries
      .where((entry) => _bindingDeclaresFacet(entry, field))
      .fold<num>(
        0,
        (total, entry) =>
            total +
            (num.tryParse('${entry.resolved.instance.instanceData[field]}') ??
                0),
      );

  List<String> _textFacetValues(List<_CalendarEntry> entries, String field) =>
      entries
          .where((entry) => _bindingDeclaresFacet(entry, field))
          .map((entry) => entry.resolved.instance.instanceData[field])
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();

  _ViewerResponseLookup _viewerResponseLookupFor(_CalendarEntry entry) {
    final responseTable = entry.resolved.binding.responseTable;
    if (responseTable == null) return const _ViewerResponseLookup.invalid();
    final expectedSource =
        'query(${responseTable.workflowType} where ${responseTable.eventField} == id)';
    final responseField = entry.resolved.machine.instanceDataSchema.entries
        .where((field) => field.value.source == expectedSource);
    if (responseField.isEmpty) {
      assert(() {
        debugPrint(
          'Calendar responseTable for ${entry.identity} has no schema field '
          'with source $expectedSource.',
        );
        return true;
      }());
      return const _ViewerResponseLookup.invalid();
    }
    final responses =
        entry.resolved.instance.instanceData[responseField.first.key];
    if (responses != null && responses is! List) {
      return const _ViewerResponseLookup.invalid();
    }
    for (final response in (responses as List<dynamic>? ?? const <dynamic>[])) {
      if (response is Map && response['fanId'] == widget.personaId) {
        return _ViewerResponseLookup.found(Map<String, dynamic>.from(response));
      }
    }
    return const _ViewerResponseLookup.noResponse();
  }

  Map<String, dynamic>? _viewerResponseRowFor(_CalendarEntry entry) =>
      _viewerResponseLookupFor(entry).response;

  bool _isPendingForViewer(_CalendarEntry entry) {
    final responseTable = entry.resolved.binding.responseTable;
    final lookup = _viewerResponseLookupFor(entry);
    if (responseTable == null || !lookup.isValid) return false;
    final response = lookup.response;
    if (response == null) return true;
    return responseTable.pendingStates.contains(response['\$state']);
  }

  bool _isReminderDueFor(_CalendarEntry entry, Map<String, dynamic> response) {
    if (response['reminderSentAt'] != null) return false;
    if (response['\$state'] == 'declined') return false;
    final reminderAtValue = entry.resolved.instance.instanceData['reminderAt'];
    final reminderAt = reminderAtValue is DateTime
        ? reminderAtValue
        : reminderAtValue is String
        ? DateTime.tryParse(reminderAtValue)
        : null;
    if (reminderAt == null) return false;
    return !widget.currentDate().isBefore(reminderAt);
  }

  Future<_CalendarEntry?> _freshReminderEntry(_CalendarEntry entry) async {
    final seenCursors = <String>{};
    String? cursor;
    while (true) {
      final page = await widget.engine.queryInstances(
        tabId: 'calendar',
        personaId: widget.personaId,
        limit: 100,
        cursor: cursor,
      );
      WorkflowInstance? current;
      for (final candidate in page.items) {
        if (candidate.instanceId == entry.instanceId) {
          current = candidate;
          break;
        }
      }
      if (current != null) {
        return _CalendarEntry(
          resolved: EngineNativeResolvedBinding(
            instance: current,
            machine: entry.resolved.machine,
            binding: entry.resolved.binding,
            definitionBindingIndex: entry.resolved.definitionBindingIndex,
            // Rebuilt field-by-field, so anything added to
            // EngineNativeResolvedBinding has to be carried here too or it is
            // silently dropped on refresh -- which is exactly what happened to
            // responseMachine the first time.
            responseMachine: entry.resolved.responseMachine,
          ),
          date: entry.date,
          minutes: entry.minutes,
        );
      }
      if (!page.hasMore) return null;
      final nextCursor = page.nextCursor;
      if (nextCursor == null ||
          nextCursor.trim().isEmpty ||
          !seenCursors.add(nextCursor)) {
        return null;
      }
      cursor = nextCursor;
    }
  }

  Future<void> _checkDueReminders(List<_CalendarEntry> entries) async {
    if (!mounted) return;
    final mutationQueue = _engineNativeMutationQueueFor(widget.engine);
    for (final entry in entries) {
      final response = _viewerResponseRowFor(entry);
      final responseTable = entry.resolved.binding.responseTable;
      if (response == null || !_isReminderDueFor(entry, response)) continue;
      if (responseTable == null) continue;
      final responseId = response['\$id'];
      if (responseId is! String ||
          responseId.isEmpty ||
          _reminderCheckInFlight.contains(responseId)) {
        continue;
      }
      _reminderCheckInFlight.add(responseId);
      try {
        await mutationQueue.runReminder(responseId, (
          shouldYieldToForeground,
        ) async {
          final freshEntry = await _freshReminderEntry(entry);
          if (shouldYieldToForeground()) return false;
          if (freshEntry == null) return false;
          final freshResponse = _viewerResponseRowFor(freshEntry);
          if (freshResponse == null ||
              freshResponse['\$id'] != responseId ||
              !_isReminderDueFor(freshEntry, freshResponse)) {
            return false;
          }
          final eventTitle =
              freshEntry.resolved.instance.instanceData['title'] ?? 'Event';
          await widget.engine.applyTransition(
            workflowType: responseTable.workflowType,
            instanceId: responseId,
            transitionId: 'send-reminder',
            personaId: widget.personaId,
            inputs: {
              'notificationTitle': 'Reminder: $eventTitle',
              'notificationBody': 'Starts soon — check Calendar for details.',
              'notificationCreatedAt': widget.currentDate().toIso8601String(),
            },
          );
          return true;
        });
      } catch (error) {
        debugPrint('Calendar reminder check failed for $responseId: $error');
      } finally {
        _reminderCheckInFlight.remove(responseId);
      }
    }
  }

  void _scheduleDueReminders() {
    final entries = _tryEntries();
    if (entries == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_checkDueReminders(entries));
    });
  }

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
    final selectedDate =
        DateTime.tryParse(widget.presentation.selectedDate ?? '') ??
        DateTime.now();
    final scopedEntries = _entriesForScope(entries);
    final facets = _facetsForEntries(scopedEntries);
    final agendaEntries = _entriesForActiveFacets(scopedEntries);
    final byDay = <String, List<_CalendarEntry>>{};
    for (final entry in agendaEntries) {
      byDay.putIfAbsent(entry.dateKey, () => []).add(entry);
    }
    final dates = byDay.keys.toList()..sort();

    return Column(
      key: const ValueKey('engine-native-calendar-root'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final scope in const <(String, String)>[
              ('day', 'Day'),
              ('week', 'Week'),
              ('month', 'Month'),
              ('pending', 'Pending'),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: ValueKey('calendar-scope-${scope.$1}'),
                  label: Text(scope.$2),
                  selected: widget.presentation.scope == scope.$1,
                  onSelected: (_) =>
                      setState(() => widget.presentation.scope = scope.$1),
                ),
              ),
          ],
        ),
        if (widget.presentation.scope == 'month') ...[
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
            onSelectDate: _selectDate,
            onSelectEntry: _selectMonthGridEntry,
            modernTheme: theme,
            accent: theme.accent ?? widget.accent,
            selectedDate: widget.presentation.selectedDate,
            today: widget.currentDate(),
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
        ] else if (widget.presentation.scope == 'week') ...[
          _EngineNativeWeekHeader(
            date: selectedDate,
            modernTheme: theme,
            onPrevious: () => _moveSelectedWeek(-1),
            onNext: () => _moveSelectedWeek(1),
          ),
          _EngineNativeWeekStrip(
            selectedDate: selectedDate,
            byDay: byDay,
            onSelectDate: _selectDate,
            onSelectEntry: _selectMonthGridEntry,
            modernTheme: theme,
            accent: theme.accent ?? widget.accent,
          ),
          const SizedBox(height: 8),
        ] else if (widget.presentation.scope == 'day') ...[
          _EngineNativeDayHeader(
            date: selectedDate,
            modernTheme: theme,
            onPrevious: () => _moveSelectedDay(-1),
            onNext: () => _moveSelectedDay(1),
          ),
          const SizedBox(height: 8),
        ],
        if (facets.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final facet in facets)
                if (facet.kind == _CalendarFacetKind.boolean)
                  FilterChip(
                    key: ValueKey('calendar-facet-${facet.field}'),
                    label: Text(facet.label),
                    selected: widget.presentation.activeFacets.contains(
                      facet.field,
                    ),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        widget.presentation.activeFacets.add(facet.field);
                      } else {
                        widget.presentation.activeFacets.remove(facet.field);
                      }
                    }),
                  )
                else if (facet.kind == _CalendarFacetKind.textValue)
                  for (final value in _textFacetValues(
                    scopedEntries,
                    facet.field,
                  ))
                    FilterChip(
                      key: ValueKey(
                        'calendar-facet-value-${facet.field}-$value',
                      ),
                      label: Text(value),
                      selected:
                          widget.presentation.activeTextFacetValues[facet
                              .field] ==
                          value,
                      onSelected: (selected) => setState(() {
                        widget.presentation.activeTextFacetValues[facet.field] =
                            selected ? value : null;
                      }),
                    )
                else
                  Text(
                    '${facet.label}: ${_facetTotal(scopedEntries, facet.field)}',
                    key: ValueKey('calendar-facet-stat-${facet.field}'),
                  ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          'Agenda',
          key: const ValueKey('engine-native-calendar-grouped-agenda'),
          style: TextStyle(color: theme.resolvedHeading),
        ),
        for (final day in dates)
          Builder(
            builder: (context) {
              final agendaDate = DateTime.parse(day);
              final now = widget.currentDate();
              final isToday =
                  agendaDate.year == now.year &&
                  agendaDate.month == now.month &&
                  agendaDate.day == now.day;
              final accent = theme.accent ?? widget.accent;
              final dayEntries = byDay[day] ?? const <_CalendarEntry>[];
              final dateRailEntries =
                  widget.calendarDateRailEntries?.isNotEmpty == true
                  ? widget.calendarDateRailEntries!
                  : _defaultCalendarDateRailEntries;
              return Container(
                key: ValueKey('engine-native-calendar-agenda-group-$day'),
                decoration: BoxDecoration(
                  color: theme.resolvedFill,
                  border: Border.all(color: theme.resolvedBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        child: Column(
                          key: ValueKey(
                            'engine-native-calendar-agenda-date-$day',
                          ),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (
                              var index = 0;
                              index < dateRailEntries.length;
                              index++
                            ) ...[
                              if (index > 0) const SizedBox(height: 2),
                              _calendarDateRailWidget(
                                entry: dateRailEntries[index],
                                value: _calendarDateRailValue(
                                  dateRailEntries[index],
                                  agendaDate,
                                  dayEntries,
                                ),
                                color: _calendarDateRailColor(
                                  dateRailEntries[index],
                                  dayEntries,
                                  accent,
                                ),
                                isToday: isToday,
                                theme: theme,
                                key: ValueKey(
                                  'engine-native-calendar-agenda-date-entry-$day-$index',
                                ),
                                legacyTodayKey:
                                    dateRailEntries[index].style ==
                                            'circleHighlight' &&
                                        index == 1
                                    ? ValueKey(
                                        'engine-native-calendar-agenda-today-$day',
                                      )
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          for (final entry in byDay[day]!) ...[
                            Container(
                              margin: const EdgeInsets.fromLTRB(0, 2, 8, 2),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: _calendarEntryStyleColor(
                                  entry,
                                  accent,
                                ).withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: ListTile(
                                key: ValueKey(
                                  'engine-native-calendar-agenda-${entry.instanceId}-${entry.resolved.definitionBindingIndex}',
                                ),
                                selected:
                                    entry.identity ==
                                    widget.presentation.selectedIdentity,
                                title: Text(
                                  entry.title,
                                  style: TextStyle(
                                    color: theme.resolvedHeading,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.time,
                                      style: TextStyle(
                                        color: theme.resolvedBody,
                                      ),
                                    ),
                                    if (entry.identity !=
                                            widget
                                                .presentation
                                                .selectedIdentity &&
                                        _tileFactSchema(entry).isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      KeyedSubtree(
                                        key: ValueKey(
                                          'engine-native-calendar-agenda-facts-${entry.instanceId}-${entry.resolved.definitionBindingIndex}',
                                        ),
                                        child: WorkflowFactPillRow(
                                          instanceData: entry
                                              .resolved
                                              .instance
                                              .instanceData,
                                          instanceDataSchema: _tileFactSchema(
                                            entry,
                                          ),
                                          displayContext: 'tile',
                                          accent: widget.accent,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                dense: true,
                                visualDensity: const VisualDensity(
                                  vertical: -3,
                                ),
                                minVerticalPadding: 2,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 2,
                                ),
                                onTap: () => _selectEntry(entry.identity),
                              ),
                            ),
                            if (entry.identity ==
                                widget.presentation.selectedIdentity)
                              EngineNativeArchetypeCard(
                                contentKey: ValueKey(
                                  'engine-native-calendar-selected-detail-${entry.instanceId}-${entry.resolved.definitionBindingIndex}',
                                ),
                                resolved: entry.resolved,
                                engine: widget.engine,
                                communityExtensionId:
                                    widget.communityExtensionId,
                                personaId: widget.personaId,
                                accent: widget.accent,
                                onInstanceChanged: widget.onInstanceChanged,
                                onInstanceScopedCreate:
                                    widget.onInstanceScopedCreate,
                                modernTheme: widget.modernTheme,
                                displayContext: 'detail',
                                showEditors: false,
                                visibleFieldKeys: _detailFieldKeys(entry),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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

  void _selectMonthGridEntry(String identity) {
    final entry = _entries.firstWhere(
      (candidate) => candidate.identity == identity,
    );
    setState(() {
      _setSelectedEntry(entry);
      widget.presentation.selectedDate = entry.dateKey;
      widget.presentation.month = DateTime(entry.date.year, entry.date.month);
      widget.presentation.scope = 'day';
    });
  }

  void _selectDate(String dateKey) {
    setState(() {
      widget.presentation.selectedDate = dateKey;
      widget.presentation.scope = 'day';
    });
  }

  void _moveSelectedDay(int offset) {
    final selectedDate =
        DateTime.tryParse(widget.presentation.selectedDate ?? '') ??
        DateTime.now();
    final nextDate = selectedDate.add(Duration(days: offset));
    setState(() {
      widget.presentation.selectedDate = _calendarDay(nextDate);
      widget.presentation.month = DateTime(nextDate.year, nextDate.month);
    });
  }

  void _moveSelectedWeek(int offset) {
    final selectedDate =
        DateTime.tryParse(widget.presentation.selectedDate ?? '') ??
        DateTime.now();
    final nextDate = selectedDate.add(Duration(days: offset * 7));
    setState(() {
      widget.presentation.selectedDate = _calendarDay(nextDate);
      widget.presentation.month = DateTime(nextDate.year, nextDate.month);
    });
  }
}

class _EventAttendeeEntry {
  const _EventAttendeeEntry({
    required this.personaId,
    required this.name,
    this.dietaryNotes,
    this.comments,
  });

  final String personaId;
  final String name;
  final String? dietaryNotes;
  final String? comments;
}

class _EventAttendeeGroup {
  const _EventAttendeeGroup({required this.label, required this.entries});

  final String label;
  final List<_EventAttendeeEntry> entries;
}

class _EventRsvpDetailCard extends StatefulWidget {
  const _EventRsvpDetailCard({
    super.key,
    required this.instance,
    required this.machine,
    required this.binding,
    required this.engine,
    required this.communityExtensionId,
    required this.personaId,
    required this.accent,
    required this.onInstanceChanged,
    this.responseMachine,
    this.instanceScopedCreateActions = const [],
    this.onInstanceScopedCreate,
  });

  final WorkflowInstance instance;
  final LoomWorkflowStateMachine machine;
  final RenderBinding binding;

  /// Definition of the response table, when this binding has one. Supplies the
  /// `initialState` used to offer response actions to a member with no row.
  final LoomWorkflowStateMachine? responseMachine;
  final WorkflowEngineApi engine;
  final String communityExtensionId;
  final String personaId;
  final Color accent;
  final ValueChanged<WorkflowInstance>? onInstanceChanged;
  final List<WorkflowAction> instanceScopedCreateActions;
  final Future<void> Function(WorkflowAction action)? onInstanceScopedCreate;

  @override
  State<_EventRsvpDetailCard> createState() => _EventRsvpDetailCardState();
}

enum _EditScope { thisEvent, thisAndFollowing, all }

class _EventRsvpDetailCardState extends State<_EventRsvpDetailCard> {
  late WorkflowInstance _instance;
  WorkflowInstance? _lastAuthoredInstance;
  final _controllers = <String, TextEditingController>{};
  final _edits = <String, dynamic>{};
  List<LoomWorkflowTransition> _actions = const [];
  Set<String> _eventActionIds = const {};
  Set<String> _responseActionIds = const {};
  bool _loadingActions = true;
  bool _mutating = false;
  String? _error;
  Future<void> Function()? _retry;
  int _actionRequest = 0;
  int _accountRequest = 0;
  int _generation = 0;
  Map<String, String>? _accountNames;

  @override
  void initState() {
    super.initState();
    _instance = widget.instance;
    _loadActions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ActiveIdentityScope is an inherited dependency. Looking it up from
    // initState is rejected by Flutter before the State has completed its
    // initialization, and the swallowed lookup error leaves attendee names
    // permanently rendered as their raw ids. Resolve it after initState and
    // again whenever the active identity scope changes.
    _loadAccountNames();
  }

  @override
  void didUpdateWidget(covariant _EventRsvpDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // AS.2 deliberately retains this State while its dispatcher refreshes the
    // bindings.  Do not make the rendered event data depend on
    // WorkflowInstance identity: an engine implementation may reuse an
    // instance object while replacing its data. A refresh triggered by this
    // card's own successful mutation can briefly return a stale row, though.
    // Keep the locally authored value until the parent catches up with every
    // field it wrote, then resume treating the parent as authoritative.
    final authored = _lastAuthoredInstance;
    final isStalePostMutationRefresh =
        authored != null &&
        widget.instance.instanceId == authored.instanceId &&
        (widget.instance.workflowType != authored.workflowType ||
            widget.instance.currentState != authored.currentState ||
            !_containsData(
              widget.instance.instanceData,
              authored.instanceData,
            ));
    if (!isStalePostMutationRefresh) {
      _instance = widget.instance;
      if (authored != null) _lastAuthoredInstance = null;
    }

    // Available transitions depend on the response data held by the instance,
    // so reload after a dispatcher refresh as well as a context change.
    if (oldWidget.instance != widget.instance ||
        oldWidget.personaId != widget.personaId ||
        oldWidget.machine != widget.machine ||
        oldWidget.engine != widget.engine ||
        oldWidget.binding != widget.binding) {
      _actionRequest++;
      _generation++;
      _edits.clear();
      _disposeControllers();
      _error = null;
      _retry = null;
      _actions = const [];
      _eventActionIds = const {};
      _loadingActions = true;
      _mutating = false;
      _loadActions();
    }
    if (oldWidget.communityExtensionId != widget.communityExtensionId) {
      _loadAccountNames();
    }
  }

  @override
  void dispose() {
    _generation++;
    _accountRequest++;
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  /// Whether [data] contains every value from [expected], allowing queried
  /// rows to include additional computed map fields.
  bool _containsData(dynamic data, dynamic expected) {
    if (expected is Map) {
      if (data is! Map) return false;
      return expected.entries.every(
        (entry) =>
            data.containsKey(entry.key) &&
            _containsData(data[entry.key], entry.value),
      );
    }
    if (expected is List) {
      if (data is! List || data.length != expected.length) return false;
      for (var index = 0; index < expected.length; index++) {
        if (!_containsData(data[index], expected[index])) return false;
      }
      return true;
    }
    return data == expected;
  }

  List<String> get _editableKeys {
    final state = widget.machine.states[_instance.currentState];
    final guard = state?.editGuard;
    final canEdit =
        guard != null &&
        evaluateGuard(guard, widget.personaId, _instance.instanceData);
    return canEdit
        ? [
            for (final key in state?.editableFields ?? const <String>[])
              if (widget.machine.instanceDataSchema[key] case final schema?)
                if (schema.formula == null && schema.writableBy != 'effect')
                  if (_isEditingFieldVisible(schema, {
                    ..._instance.instanceData,
                    ..._edits,
                  }))
                    key,
          ]
        : const <String>[];
  }

  dynamic _valueFor(String key) =>
      _edits.containsKey(key) ? _edits[key] : _instance.instanceData[key];

  TextEditingController _controllerFor(String key) => _controllers.putIfAbsent(
    key,
    () => TextEditingController(text: '${_valueFor(key) ?? ''}'),
  );

  void _resyncControllers() {
    _disposeControllers();
    for (final key in _editableKeys) {
      final schema = widget.machine.instanceDataSchema[key]!;
      if (schema.type != 'bool' &&
          schema.type != 'date' &&
          schema.type != 'time') {
        _controllerFor(key);
      }
    }
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
  bool get _usesResponseRows => widget.binding.responseTable != null;

  String? get _responseRowsField {
    final responseTable = widget.binding.responseTable;
    if (responseTable == null) return null;
    final expectedSource =
        'query(${responseTable.workflowType} where ${responseTable.eventField} == id)';
    final responseField = widget.machine.instanceDataSchema.entries
        .where((field) => field.value.source == expectedSource)
        .firstOrNull;
    if (responseField == null) {
      assert(() {
        debugPrint(
          'Event-rsvp detail card for ${widget.instance.instanceId} has '
          'responseTable ${responseTable.workflowType}/${responseTable.eventField} '
          'but no schema field with source $expectedSource.',
        );
        return true;
      }());
      return null;
    }
    return responseField.key;
  }

  List<dynamic>? get _viewerResponseRows {
    final responseRowsField = _responseRowsField;
    if (responseRowsField == null) return null;
    final rows = _instance.instanceData[responseRowsField];
    if (rows is! List) return null;
    return rows;
  }

  Map<String, dynamic>? get _viewerResponse {
    if (!_usesResponseRows) return null;
    final responses = _viewerResponseRows;
    if (responses is! List) return null;
    for (final response in responses) {
      if (response is Map && response['fanId'] == widget.personaId) {
        return Map<String, dynamic>.from(response);
      }
    }
    return null;
  }

  Future<void> _loadAccountNames() async {
    final communityExtensionId = widget.communityExtensionId;
    final request = ++_accountRequest;
    try {
      final authApi = ActiveIdentityScope.of(context).authApi;
      final accounts = await authApi.listAccounts(
        communityExtensionId: communityExtensionId,
      );
      if (!mounted ||
          request != _accountRequest ||
          widget.communityExtensionId != communityExtensionId) {
        return;
      }
      setState(() {
        _accountNames = {
          for (final account in accounts)
            account.accountId: account.displayName,
        };
      });
    } catch (_) {
      if (!mounted ||
          request != _accountRequest ||
          widget.communityExtensionId != communityExtensionId) {
        return;
      }
      setState(() => _accountNames = const {});
    }
  }

  String _displayNameFor(String personaId) =>
      _accountNames?[personaId] ?? personaId;

  List<_EventAttendeeGroup> get _attendeeGroups {
    final groups = <String, List<_EventAttendeeEntry>>{};
    if (_usesResponseRows) {
      final responses = _viewerResponseRows;
      if (responses is! List) return const [];
      for (final response in responses) {
        if (response is! Map) continue;
        final personaId = response['fanId']?.toString();
        if (personaId == null || personaId.isEmpty) continue;
        final state = response['\$state']?.toString() ?? 'pending';
        (groups[_attendeeStateLabel(state)] ??= []).add(
          _EventAttendeeEntry(
            personaId: personaId,
            name: _displayNameFor(personaId),
            dietaryNotes: _nonEmptyValue(response['dietaryNotes']),
            comments: _nonEmptyValue(response['comments']),
          ),
        );
      }
    } else {
      for (final entry in const [
        ('Going', 'goingFanIds'),
        ('Waitlisted', 'waitlistFanIds'),
      ]) {
        final personaIds = _instance.instanceData[entry.$2];
        if (personaIds is! List) continue;
        for (final personaId in personaIds) {
          final id = personaId?.toString();
          if (id == null || id.isEmpty) continue;
          (groups[entry.$1] ??= []).add(
            _EventAttendeeEntry(personaId: id, name: _displayNameFor(id)),
          );
        }
      }
    }
    return [
      for (final entry in groups.entries)
        if (entry.value.isNotEmpty)
          _EventAttendeeGroup(label: entry.key, entries: entry.value),
    ];
  }

  String? _nonEmptyValue(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _attendeeStateLabel(String state) => switch (state) {
    'going' => 'Going',
    'maybe' => 'Maybe',
    'waitlisted' => 'Waitlisted',
    'declined' => 'Declined',
    'pending' => 'Pending',
    _ => state,
  };

  Future<void> _loadActions() async {
    final generation = _generation;
    final instance = _instance;
    final machine = widget.machine;
    final engine = widget.engine;
    final personaId = widget.personaId;
    final responseTable = widget.binding.responseTable;
    final response = _viewerResponse;
    final request = ++_actionRequest;
    if (_isCurrent(generation, instance, machine, engine, personaId)) {
      setState(() {
        _loadingActions = true;
        _actions = const [];
        _eventActionIds = const {};
        _responseActionIds = const {};
        _error = null;
        _retry = null;
      });
    }
    try {
      final eventActions = await engine.availableTransitionsAsync(
        workflowType: instance.workflowType,
        instanceId: instance.instanceId,
        currentState: instance.currentState,
        instanceData: instance.instanceData,
        personaId: personaId,
      );
      // A member with no row still gets offered response actions, computed
      // against a synthetic row in the response workflow's declared
      // `initialState`. Previously this short-circuited to an empty list, so
      // anyone who joined after the event was created saw no RSVP controls at
      // all -- and `_applyTransition`'s create-or-get could never fire, because
      // there was no control to tap. The row is materialized on that tap, not
      // here; this stays a pure read.
      final responseMachine = widget.responseMachine;
      final syntheticResponse = response == null && responseMachine != null
          ? <String, dynamic>{
              responseTable!.eventField: instance.instanceId,
              'fanId': personaId,
            }
          : null;
      final responseActions = responseTable == null
          ? const <LoomWorkflowTransition>[]
          : response != null
          ? await engine.availableTransitionsAsync(
              workflowType: responseTable.workflowType,
              instanceId: response['\$id'] as String,
              currentState: response['\$state'] as String,
              instanceData: response,
              personaId: personaId,
            )
          : syntheticResponse == null
          ? const <LoomWorkflowTransition>[]
          : await engine.availableTransitionsAsync(
              workflowType: responseTable.workflowType,
              // No row exists yet, so there is no id to name. Guards that
              // resolve per-instance data still see the synthetic row's own
              // fields (notably `fanId`, which `actorEqualsField` reads).
              instanceId: '',
              currentState: responseMachine!.initialState,
              instanceData: syntheticResponse,
              personaId: personaId,
            );
      if (!_isCurrent(generation, instance, machine, engine, personaId) ||
          request != _actionRequest) {
        return;
      }
      setState(() {
        _actions = <LoomWorkflowTransition>[
          ...eventActions,
          ...responseActions,
        ];
        _eventActionIds = eventActions.map((action) => action.id).toSet();
        _responseActionIds = responseActions.map((action) => action.id).toSet();
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

  Future<void> _applyTransition(String transitionId) async {
    final transition = _actions
        .where((candidate) => candidate.id == transitionId)
        .firstOrNull;
    if (transition == null) return;
    final declaredInputs = transition.inputs;
    final inputs = declaredInputs == null || declaredInputs.isEmpty
        ? null
        : await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => GenericTransitionInputDialog(
              transition: transition,
              instanceData: _instance.instanceData,
            ),
          );
    if (declaredInputs != null && declaredInputs.isNotEmpty && inputs == null) {
      return;
    }
    // Keep recurrence inputs for mutation retries instead of reopening the
    // input dialog after a failed attempt.
    if (transitionId == 'make-recurring') {
      return _applyMakeRecurring(inputs!);
    }
    final generation = _generation;
    final instance = _instance;
    final machine = widget.machine;
    final engine = widget.engine;
    final personaId = widget.personaId;
    final response = _viewerResponse;
    final responseTable = widget.binding.responseTable;
    final appliesToEvent = _eventActionIds.contains(transitionId);
    final appliesToResponse =
        !appliesToEvent && _responseActionIds.contains(transitionId);
    // A response action with no response table is a malformed package, not a
    // user error -- but it must still say so rather than swallow the tap.
    if (appliesToResponse && _usesResponseRows && responseTable == null) {
      setState(() {
        _error = 'This event cannot record responses. Please report this.';
        _retry = null;
      });
      return;
    }
    final responseWorkflowType = responseTable?.workflowType;
    final targetWorkflowType = appliesToResponse
        ? responseWorkflowType!
        : instance.workflowType;
    return _runMutation(
      generation: generation,
      instance: instance,
      machine: machine,
      engine: engine,
      personaId: personaId,
      operation: () async {
        // Create-or-get (D7a). A member with no response row previously fell
        // through to `return Future.value()`: the tap did nothing, silently,
        // with no error and no state change -- a dead button. A missing row is
        // not exceptional, because the archetype's fan-out only covers members
        // who existed when the event was created; anyone joining later has no
        // row for any earlier event. Materializing on demand is self-healing
        // for every cause of a missing row (late joiner, a fan-out that failed
        // part-way, data repair), not just that one.
        //
        // Deliberately inside `operation` so a failure to create raises through
        // _runMutation's existing catch, surfacing the standard error banner
        // and Retry rather than a second bespoke error path.
        var targetInstanceId = response?['\$id'] as String?;
        if (appliesToResponse && _usesResponseRows) {
          if (targetInstanceId == null) {
            final created = await engine.createInstances(
              workflowType: responseTable!.workflowType,
              initialInstanceDataList: [
                {
                  responseTable.eventField: instance.instanceId,
                  // All response tables in the specVersion 4 corpus declare
                  // the individual identity field as `fanId`.
                  'fanId': personaId,
                },
              ],
              personaId: personaId,
            );
            if (created.isEmpty) {
              throw StateError(
                'Creating a ${responseTable.workflowType} row for $personaId '
                'returned no instance id.',
              );
            }
            targetInstanceId = created.first;
          }
        } else {
          targetInstanceId = instance.instanceId;
        }
        final result = await engine.applyTransition(
          workflowType: targetWorkflowType,
          instanceId: targetInstanceId,
          transitionId: transitionId,
          personaId: personaId,
          inputs: inputs,
        );
        // Was gated on `response != null` back when a missing row aborted the
        // whole call. With create-or-get that is no longer true, and a row we
        // just created needs the re-read exactly as much as a pre-existing one
        // -- otherwise the freshly recorded response would not appear until
        // some later refresh.
        if (appliesToResponse) {
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

  Future<void> _applyMakeRecurring(Map<String, dynamic> inputs) {
    final generation = _generation;
    final instance = _instance;
    final machine = widget.machine;
    final engine = widget.engine;
    final personaId = widget.personaId;
    return _runMutation(
      generation: generation,
      instance: instance,
      machine: machine,
      engine: engine,
      personaId: personaId,
      operation: () async {
        final result = await engine.applyTransition(
          workflowType: instance.workflowType,
          instanceId: instance.instanceId,
          transitionId: 'make-recurring',
          personaId: personaId,
          inputs: inputs,
        );
        return WorkflowInstance(
          instanceId: instance.instanceId,
          workflowType: instance.workflowType,
          currentState: result.newState,
          instanceData: result.newInstanceData,
          createdByPersonaId: instance.createdByPersonaId,
        );
      },
      retry: () => _applyMakeRecurring(inputs),
    );
  }

  Future<void> _deleteSeries() async {
    final generation = _generation;
    final instance = _instance;
    final machine = widget.machine;
    final engine = widget.engine;
    final personaId = widget.personaId;
    final seriesId = instance.instanceData['seriesId'];
    if (seriesId == null) return;
    final scope = await showDialog<_EditScope>(
      context: context,
      builder: (context) => const _EditScopePickerDialog(
        keyPrefix: 'delete-scope-picker',
        title: 'Delete:',
        confirmLabel: 'Delete',
      ),
    );
    if (scope == null ||
        !_isCurrent(generation, instance, machine, engine, personaId)) {
      return;
    }
    if (scope == _EditScope.thisEvent) {
      return _applyTransition('cancel-event');
    }
    final anchorDate = instance.instanceData['eventDate']?.toString();
    return _runMutation(
      generation: generation,
      instance: instance,
      machine: machine,
      engine: engine,
      personaId: personaId,
      operation: () async {
        final members = <WorkflowInstance>[];
        final seenCursors = <String>{};
        String? cursor;
        while (true) {
          final page = await engine.queryInstances(
            tabId: 'calendar',
            personaId: personaId,
            limit: 100,
            cursor: cursor,
          );
          members.addAll(
            page.items.where(
              (candidate) =>
                  candidate.workflowType == instance.workflowType &&
                  candidate.instanceData['seriesId'] == seriesId,
            ),
          );
          if (!page.hasMore) break;
          final nextCursor = page.nextCursor;
          if (nextCursor == null ||
              nextCursor.trim().isEmpty ||
              !seenCursors.add(nextCursor)) {
            throw StateError(
              'Invalid pagination cursor while loading calendar for $personaId',
            );
          }
          cursor = nextCursor;
        }
        WorkflowInstance? updatedSelf;
        for (final member in members) {
          if (scope == _EditScope.thisAndFollowing &&
              member.instanceId != instance.instanceId &&
              (anchorDate == null ||
                  (member.instanceData['eventDate']?.toString() ?? '')
                          .compareTo(anchorDate) <
                      0)) {
            continue;
          }
          final result = await engine.applyTransition(
            workflowType: instance.workflowType,
            instanceId: member.instanceId,
            transitionId: 'cancel-event',
            personaId: personaId,
          );
          if (member.instanceId == instance.instanceId) {
            updatedSelf = WorkflowInstance(
              instanceId: instance.instanceId,
              workflowType: instance.workflowType,
              currentState: result.newState,
              instanceData: result.newInstanceData,
              createdByPersonaId: instance.createdByPersonaId,
            );
          }
        }
        return updatedSelf ??
            WorkflowInstance(
              instanceId: instance.instanceId,
              workflowType: instance.workflowType,
              currentState: 'cancelled',
              instanceData: instance.instanceData,
              createdByPersonaId: instance.createdByPersonaId,
            );
      },
      retry: _deleteSeries,
    );
  }

  Future<void> _save() async {
    if (_mutating || _edits.isEmpty) return;
    final generation = _generation;
    final instance = _instance;
    final machine = widget.machine;
    final engine = widget.engine;
    final personaId = widget.personaId;
    final updates = <String, dynamic>{};
    for (final key in _editableKeys) {
      if (!_edits.containsKey(key)) continue;
      final field = widget.machine.instanceDataSchema[key]!;
      final value = _edits[key];
      if (field.type == 'number' && value is String) {
        final parsed = num.tryParse(value.trim());
        if (parsed == null) {
          if (!_isCurrent(generation, instance, machine, engine, personaId))
            return;
          setState(() {
            _error = 'Enter a valid number.';
            _retry = _save;
          });
          return;
        }
        updates[key] = parsed;
      } else {
        updates[key] = value;
      }
    }
    if (updates.isEmpty) return;
    final seriesId = instance.instanceData['seriesId'];
    final scope = seriesId == null
        ? _EditScope.thisEvent
        : await showDialog<_EditScope>(
            context: context,
            builder: (context) => const _EditScopePickerDialog(
              keyPrefix: 'edit-scope-picker',
              title: 'Save changes to:',
              confirmLabel: 'Save',
            ),
          );
    if (scope == null ||
        !_isCurrent(generation, instance, machine, engine, personaId)) {
      return;
    }
    final optimistic = WorkflowInstance(
      instanceId: instance.instanceId,
      workflowType: instance.workflowType,
      currentState: instance.currentState,
      instanceData: {...instance.instanceData, ...updates},
      createdByPersonaId: instance.createdByPersonaId,
    );
    String? partialFailureMessage;
    await _runMutation(
      generation: generation,
      instance: instance,
      machine: machine,
      engine: engine,
      personaId: personaId,
      optimistic: optimistic,
      operation: () async {
        if (scope == _EditScope.thisEvent) {
          await engine.updateInstanceFields(
            workflowType: instance.workflowType,
            instanceId: instance.instanceId,
            fieldUpdates: updates,
            personaId: personaId,
          );
        } else {
          final members = <WorkflowInstance>[];
          final seenCursors = <String>{};
          String? cursor;
          while (true) {
            final page = await engine.queryInstances(
              tabId: 'calendar',
              personaId: personaId,
              limit: 100,
              cursor: cursor,
            );
            members.addAll(
              page.items.where(
                (candidate) =>
                    candidate.workflowType == instance.workflowType &&
                    candidate.instanceData['seriesId'] == seriesId,
              ),
            );
            if (!page.hasMore) break;
            final nextCursor = page.nextCursor;
            if (nextCursor == null ||
                nextCursor.trim().isEmpty ||
                !seenCursors.add(nextCursor)) {
              throw StateError(
                'Invalid pagination cursor while loading calendar for $personaId',
              );
            }
            cursor = nextCursor;
          }
          final anchorDate = instance.instanceData['eventDate']?.toString();
          final failures = <String>[];
          for (final member in members) {
            if (scope == _EditScope.thisAndFollowing &&
                member.instanceId != instance.instanceId &&
                (anchorDate == null ||
                    (member.instanceData['eventDate']?.toString() ?? '')
                            .compareTo(anchorDate) <
                        0)) {
              continue;
            }
            if (member.instanceId == instance.instanceId) {
              await engine.updateInstanceFields(
                workflowType: member.workflowType,
                instanceId: member.instanceId,
                fieldUpdates: updates,
                personaId: personaId,
              );
              continue;
            }
            try {
              await engine.updateInstanceFields(
                workflowType: member.workflowType,
                instanceId: member.instanceId,
                fieldUpdates: updates,
                personaId: personaId,
              );
            } catch (_) {
              // A malformed sibling may not permit every field in [updates].
              // Continue so valid series members still receive the edit.
              failures.add(member.instanceId);
            }
          }
          if (failures.isNotEmpty) {
            partialFailureMessage =
                'Saved this event, but could not update ${failures.length} '
                'other event${failures.length == 1 ? '' : 's'} in the series.';
          }
        }
        return WorkflowInstance(
          instanceId: instance.instanceId,
          workflowType: instance.workflowType,
          currentState: instance.currentState,
          instanceData: optimistic.instanceData,
          createdByPersonaId: instance.createdByPersonaId,
        );
      },
      retry: _save,
      successWarning: () => partialFailureMessage,
    );
  }

  Future<void> _runMutation({
    required int generation,
    required WorkflowInstance instance,
    required LoomWorkflowStateMachine machine,
    required WorkflowEngineApi engine,
    required String personaId,
    WorkflowInstance? optimistic,
    required Future<WorkflowInstance> Function() operation,
    required Future<void> Function() retry,
    String? Function()? successWarning,
  }) {
    if (_mutating) return Future<void>.value();
    final mutationQueue = _engineNativeMutationQueueFor(engine);
    return mutationQueue.runForeground(() async {
      if (!mounted || _mutating) return;
      setState(() {
        _mutating = true;
        _error = null;
        _retry = null;
        if (optimistic != null) _instance = optimistic;
      });
      if (optimistic != null) {
        _resyncControllers();
      }
      final activeInstance = optimistic ?? instance;
      try {
        final next = await operation();
        if (!_isCurrent(
          generation,
          activeInstance,
          machine,
          engine,
          personaId,
        )) {
          return;
        }
        _instance = next;
        if (optimistic != null) _lastAuthoredInstance = next;
        _edits.clear();
        _resyncControllers();
        widget.onInstanceChanged?.call(next);
        if (!_isCurrent(generation, next, machine, engine, personaId)) return;
        setState(() => _mutating = false);
        await _loadActions();
        final warning = successWarning?.call();
        if (warning != null &&
            _isCurrent(generation, next, machine, engine, personaId)) {
          setState(() => _error = warning);
        }
      } catch (_) {
        if (!_isCurrent(
          generation,
          activeInstance,
          machine,
          engine,
          personaId,
        )) {
          return;
        }
        setState(() {
          if (optimistic != null) _instance = instance;
          _lastAuthoredInstance = null;
          _mutating = false;
          _error = 'Could not save this change. Please try again.';
          _retry = retry;
        });
      }
    });
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
        return (data['goingFanIds'] as List?)?.contains(pid) ?? false;
      case 'rsvp-maybe':
        return (data['maybeFanIds'] as List?)?.contains(pid) ?? false;
      case 'rsvp-not-going':
        return (data['notGoingFanIds'] as List?)?.contains(pid) ?? false;
      case 'join-waitlist':
        return (data['waitlistFanIds'] as List?)?.contains(pid) ?? false;
      default:
        return false;
    }
  }

  List<LoomWorkflowTransition> get _displayActions {
    final visibleActions = _actions
        .where((action) => !_hiddenAutomaticActionIds.contains(action.id))
        .toList(growable: false);
    final response = _viewerResponse;
    if (response == null) return visibleActions;
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
            visibleActions.any((action) => action.id == 'respond-going')) ||
        visibleActions.any((action) => action.id == selected.id)) {
      return visibleActions;
    }
    return <LoomWorkflowTransition>[selected, ...visibleActions];
  }

  Map<String, WorkflowFactPillFieldSchema> get _fallbackFactSchema => {
    for (final entry in widget.machine.instanceDataSchema.entries)
      if (!_calendarBespokeFieldKeys.contains(entry.key) &&
          _isCalendarDetailField(entry.value))
        entry.key: WorkflowFactPillFieldSchema(
          type: entry.value.type,
          maxLength: entry.value.maxLength,
          displayIcon: entry.value.displayIcon,
          labelTemplate: entry.value.labelTemplate,
          hideWhenEmpty: entry.value.hideWhenEmpty,
          displayContexts: entry.value.displayContexts,
        ),
  };

  String _fieldLabel(String key, InstanceDataField schema) {
    final label = (schema.labelTemplate ?? '')
        .replaceAll('{value.length}', '')
        .replaceAll('{value}', '')
        .replaceAll(RegExp(r'[:\-–—]+\s*$'), '')
        .trim();
    if (label.isNotEmpty) return label;
    final spaced = key.replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return spaced.isEmpty
        ? spaced
        : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  Widget _editor(String key, InstanceDataField schema) {
    final disabled = _mutating;
    final editorKey = ValueKey(
      'event-rsvp-editor-${_instance.instanceId}-$key',
    );
    final label = _fieldLabel(key, schema);
    switch (schema.type) {
      case 'bool':
        return SwitchListTile(
          key: editorKey,
          title: Text(label),
          value: _valueFor(key) == true,
          onChanged: disabled
              ? null
              : (value) => setState(() => _edits[key] = value),
        );
      case 'date':
        return _pickerField(
          key: key,
          label: label,
          editorKey: editorKey,
          disabled: disabled,
          onPick: () async {
            final generation = _generation;
            final instance = _instance;
            final machine = widget.machine;
            final engine = widget.engine;
            final personaId = widget.personaId;
            final initial =
                DateTime.tryParse('${_valueFor(key) ?? ''}') ?? DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null &&
                _isCurrent(generation, instance, machine, engine, personaId)) {
              setState(
                () => _edits[key] =
                    '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
              );
            }
          },
        );
      case 'time':
        return _pickerField(
          key: key,
          label: label,
          editorKey: editorKey,
          disabled: disabled,
          onPick: () async {
            final generation = _generation;
            final instance = _instance;
            final machine = widget.machine;
            final engine = widget.engine;
            final personaId = widget.personaId;
            final parts = '${_valueFor(key) ?? ''}'.split(':');
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.tryParse(parts.first) ?? TimeOfDay.now().hour,
                minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
              ),
            );
            if (picked != null &&
                _isCurrent(generation, instance, machine, engine, personaId)) {
              setState(
                () => _edits[key] =
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
              );
            }
          },
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            key: editorKey,
            controller: _controllerFor(key),
            enabled: !disabled,
            maxLines: schema.type == 'textarea' ? null : 1,
            keyboardType: schema.type == 'number'
                ? const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  )
                : TextInputType.text,
            decoration: InputDecoration(labelText: label),
            onChanged: (value) => setState(() => _edits[key] = value),
          ),
        );
    }
  }

  Widget _pickerField({
    required String key,
    required String label,
    required Key editorKey,
    required bool disabled,
    required Future<void> Function() onPick,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      key: editorKey,
      onTap: disabled ? null : onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: !disabled,
          border: const OutlineInputBorder(),
        ),
        child: Text('${_valueFor(key) ?? ''}'),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final data = _instance.instanceData;
    final title = data['title']?.toString().trim();
    final goingCount = (data['goingCount'] ?? data['accepted'] ?? 0) as num;
    final capacity =
        (data['capacity'] ?? data['minimumAttendance'] ?? 1) as num;
    final seatsRemaining = data['seatsRemaining'];
    final isFull = data['isFull'] as bool? ?? false;
    final quorumMet = data['quorumMet'];
    final response = _viewerResponse;
    final waitlistIds =
        (data['waitlistFanIds'] as List?)?.cast<String>() ?? const <String>[];
    final onWaitlist = response == null
        ? waitlistIds.contains(widget.personaId)
        : response['\$state'] == 'waitlisted';

    final hasCapacityInfo =
        data.containsKey('capacity') || data.containsKey('minimumAttendance');
    final fallbackFactSchema = _fallbackFactSchema;
    final editable = _editableKeys;
    final attendeeGroups = _attendeeGroups;
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
            if (title != null && title.isNotEmpty) ...[
              Text(
                title,
                key: ValueKey('event-rsvp-title-${_instance.instanceId}'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
            ],
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
            if (attendeeGroups.isNotEmpty) ...[
              KeyedSubtree(
                key: ValueKey('event-rsvp-attendees-${_instance.instanceId}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendees',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final group in attendeeGroups) ...[
                      Text(
                        group.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      for (final attendee in group.entries)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ${attendee.name}'),
                              if (attendee.dietaryNotes != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    attendee.dietaryNotes!,
                                    key: ValueKey(
                                      'event-rsvp-attendee-dietary-${attendee.personaId}',
                                    ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.65),
                                        ),
                                  ),
                                ),
                              if (attendee.comments != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    attendee.comments!,
                                    key: ValueKey(
                                      'event-rsvp-attendee-comments-${attendee.personaId}',
                                    ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.65),
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
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
            if (editable.isNotEmpty) ...[
              for (final key in editable)
                _editor(key, widget.machine.instanceDataSchema[key]!),
              const SizedBox(height: 8),
              FilledButton(
                key: ValueKey('event-rsvp-save-${_instance.instanceId}'),
                onPressed: _mutating || _edits.isEmpty ? null : _save,
                child: const Text('Save changes'),
              ),
              const SizedBox(height: 4),
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
                    if (_retry != null)
                      TextButton(
                        key: ValueKey(
                          'event-rsvp-retry-${_instance.instanceId}',
                        ),
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
                  if (_instance.instanceData['seriesId'] != null &&
                      _eventActionIds.contains('cancel-event'))
                    _RsvpActionChip(
                      key: ValueKey(
                        'event-rsvp-delete-series-${_instance.instanceId}',
                      ),
                      label: 'Delete series',
                      iconName: 'cancel',
                      tone: WorkflowActionTone.destructive,
                      selected: false,
                      onPressed: _mutating ? null : _deleteSeries,
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
                      onPressed:
                          _mutating || widget.onInstanceScopedCreate == null
                          ? null
                          : () => widget.onInstanceScopedCreate!(action),
                      child: Text(
                        action.label ?? 'Create ${action.workflowType}',
                      ),
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
    required this.onSelectDate,
    required this.onSelectEntry,
    required this.modernTheme,
    required this.accent,
    required this.selectedDate,
    required this.today,
  });

  final DateTime month;
  final Map<String, List<_CalendarEntry>> byDay;
  final ValueChanged<String> onSelectDate;
  final ValueChanged<String> onSelectEntry;
  final LoomCardTheme modernTheme;
  final Color accent;
  final String? selectedDate;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final start = first.subtract(Duration(days: first.weekday - 1));
    final todayKey = _calendarDay(today);
    return Column(
      key: const ValueKey('engine-native-calendar-month-grid'),
      children: [
        Row(
          key: const ValueKey('engine-native-calendar-weekday-header'),
          children: [
            for (var weekday = 0; weekday < 7; weekday++)
              Expanded(
                child: Center(
                  child: Text(
                    _calendarWeekdayAbbreviations[weekday],
                    style: TextStyle(
                      color: modernTheme.resolvedHeading,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
                    final isToday = dateKey == todayKey;
                    final todayAccent = (modernTheme.accent ?? accent)
                        .withValues(alpha: 0.12);
                    return Expanded(
                      child: InkWell(
                        onTap: () => onSelectDate(dateKey),
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
                                : isToday
                                ? Color.alphaBlend(
                                    todayAccent,
                                    modernTheme.resolvedFill,
                                  )
                                : modernTheme.resolvedFill,
                            border: Border.all(
                              color: isToday
                                  ? todayAccent
                                  : modernTheme.resolvedBorder,
                              width: isToday ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
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
                                        onTap: () =>
                                            onSelectEntry(entry.identity),
                                        child:
                                            entry.resolved.binding.styleField ==
                                                null
                                            ? Text(
                                                entry.title,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color:
                                                      modernTheme.resolvedBody,
                                                ),
                                              )
                                            : Row(
                                                children: [
                                                  Container(
                                                    width: 5,
                                                    height: 5,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          _calendarEntryStyleColor(
                                                            entry,
                                                            accent,
                                                          ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      entry.title,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: modernTheme
                                                            .resolvedBody,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isToday)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    key: ValueKey(
                                      'engine-native-calendar-today-$dateKey',
                                    ),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: todayAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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

class _EditScopePickerDialog extends StatefulWidget {
  const _EditScopePickerDialog({
    required this.keyPrefix,
    required this.title,
    required this.confirmLabel,
  });

  final String keyPrefix;
  final String title;
  final String confirmLabel;

  @override
  State<_EditScopePickerDialog> createState() => _EditScopePickerDialogState();
}

class _EditScopePickerDialogState extends State<_EditScopePickerDialog> {
  _EditScope _scope = _EditScope.thisEvent;

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: ValueKey('${widget.keyPrefix}-dialog'),
    title: Text(widget.title),
    content: RadioGroup<_EditScope>(
      groupValue: _scope,
      onChanged: (value) => setState(() => _scope = value!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in const [
            (_EditScope.thisEvent, 'This event only'),
            (_EditScope.thisAndFollowing, 'This and following events'),
            (_EditScope.all, 'All events in the series'),
          ])
            RadioListTile<_EditScope>(
              key: ValueKey('${widget.keyPrefix}-${option.$1.name}'),
              value: option.$1,
              title: Text(option.$2),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        key: ValueKey('${widget.keyPrefix}-cancel'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: ValueKey('${widget.keyPrefix}-confirm'),
        onPressed: () => Navigator.of(context).pop(_scope),
        child: Text(widget.confirmLabel),
      ),
    ],
  );
}

class _EngineNativeWeekStrip extends StatelessWidget {
  const _EngineNativeWeekStrip({
    required this.selectedDate,
    required this.byDay,
    required this.onSelectDate,
    required this.onSelectEntry,
    required this.modernTheme,
    required this.accent,
  });

  final DateTime selectedDate;
  final Map<String, List<_CalendarEntry>> byDay;
  final ValueChanged<String> onSelectDate;
  final ValueChanged<String> onSelectEntry;
  final LoomCardTheme modernTheme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // Keep the month grid's Monday-first column convention.
    final start = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    return Row(
      key: const ValueKey('engine-native-calendar-week-strip'),
      children: [
        for (var weekday = 0; weekday < DateTime.daysPerWeek; weekday++)
          Builder(
            builder: (context) {
              final date = start.add(Duration(days: weekday));
              final dateKey = _calendarDay(date);
              final events = byDay[dateKey] ?? const <_CalendarEntry>[];
              return Expanded(
                child: InkWell(
                  onTap: () => onSelectDate(dateKey),
                  child: Container(
                    key: ValueKey('engine-native-calendar-week-cell-$dateKey'),
                    constraints: const BoxConstraints(minHeight: 52),
                    decoration: BoxDecoration(
                      color: modernTheme.resolvedFill,
                      border: Border.all(color: modernTheme.resolvedBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(color: modernTheme.resolvedHeading),
                        ),
                        for (final entry in events)
                          InkWell(
                            key: ValueKey(
                              'engine-native-calendar-entry-${entry.instanceId}-${entry.resolved.definitionBindingIndex}',
                            ),
                            onTap: () => onSelectEntry(entry.identity),
                            child: entry.resolved.binding.styleField == null
                                ? Text(
                                    entry.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: modernTheme.resolvedBody,
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.only(right: 3),
                                        decoration: BoxDecoration(
                                          color: _calendarEntryStyleColor(
                                            entry,
                                            accent,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _EngineNativeWeekHeader extends StatelessWidget {
  const _EngineNativeWeekHeader({
    required this.date,
    required this.modernTheme,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime date;
  final LoomCardTheme modernTheme;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return Row(
      key: const ValueKey('engine-native-calendar-week-navigation'),
      children: [
        IconButton(
          key: const ValueKey('engine-native-calendar-previous-week'),
          onPressed: onPrevious,
          icon: Icon(Icons.chevron_left, color: modernTheme.resolvedHeading),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${_monthLabel(start.month)} ${start.day} – ${_monthLabel(end.month)} ${end.day}, ${end.year}',
              style: TextStyle(color: modernTheme.resolvedHeading),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('engine-native-calendar-next-week'),
          onPressed: onNext,
          icon: Icon(Icons.chevron_right, color: modernTheme.resolvedHeading),
        ),
      ],
    );
  }
}

class _EngineNativeDayHeader extends StatelessWidget {
  const _EngineNativeDayHeader({
    required this.date,
    required this.modernTheme,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime date;
  final LoomCardTheme modernTheme;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('engine-native-calendar-day-header'),
    children: [
      IconButton(
        key: const ValueKey('engine-native-calendar-previous-day'),
        onPressed: onPrevious,
        icon: Icon(Icons.chevron_left, color: modernTheme.resolvedHeading),
      ),
      Expanded(
        child: Center(
          child: Text(
            '${_monthLabel(date.month)} ${date.day}, ${date.year}',
            style: TextStyle(color: modernTheme.resolvedHeading),
          ),
        ),
      ),
      IconButton(
        key: const ValueKey('engine-native-calendar-next-day'),
        onPressed: onNext,
        icon: Icon(Icons.chevron_right, color: modernTheme.resolvedHeading),
      ),
    ],
  );
}

String _calendarDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
