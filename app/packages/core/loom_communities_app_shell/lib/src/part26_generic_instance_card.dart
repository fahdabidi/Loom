part of '../loom_communities_app_shell.dart';

/// A schema-driven presentation and editing surface for one workflow instance.
///
/// This widget deliberately has no knowledge of a workflow type. Its only
/// persistence path is [WorkflowEngineApi], so the state it presents after a
/// mutation is always the result of a real engine operation.
class GenericWorkflowInstanceCard extends StatefulWidget {
  const GenericWorkflowInstanceCard({
    super.key,
    required this.instance,
    required this.machine,
    required this.engine,
    required this.personaId,
    this.displayContext = 'tile',
    this.onInstanceChanged,
    this.accent,
    this.foreground,
    this.visibleFieldKeys,
    this.showEditors = true,
    this.instanceScopedCreateActions = const [],
    this.onInstanceScopedCreate,
  }) : assert(displayContext == 'tile' || displayContext == 'detail');

  final WorkflowInstance instance;
  final LoomWorkflowStateMachine machine;
  final WorkflowEngineApi engine;
  final String personaId;
  final String displayContext;
  final ValueChanged<WorkflowInstance>? onInstanceChanged;
  final Color? accent;
  final Color? foreground;

  /// Optional bounded presentation filter. Null preserves the schema-driven
  /// presentation used by existing callers.
  final Set<String>? visibleFieldKeys;
  final bool showEditors;
  final List<WorkflowAction> instanceScopedCreateActions;
  final Future<void> Function(WorkflowAction action)? onInstanceScopedCreate;

  @override
  State<GenericWorkflowInstanceCard> createState() =>
      _GenericWorkflowInstanceCardState();
}

class _GenericWorkflowInstanceCardState
    extends State<GenericWorkflowInstanceCard> {
  late WorkflowInstance _instance;
  final _controllers = <String, TextEditingController>{};
  final _edits = <String, dynamic>{};
  List<LoomWorkflowTransition> _actions = const [];
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
  void didUpdateWidget(covariant GenericWorkflowInstanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instance != widget.instance ||
        oldWidget.personaId != widget.personaId ||
        oldWidget.machine != widget.machine ||
        oldWidget.engine != widget.engine) {
      _actionRequest++;
      _generation++;
      _instance = widget.instance;
      _edits.clear();
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      _controllers.clear();
      _error = null;
      _retry = null;
      _actions = const [];
      _loadingActions = true;
      // A mutation belonging to the invalidated inputs may still be awaiting
      // the engine.  Its completion is generation-guarded, so release the new
      // card immediately rather than leaving it disabled behind that call.
      _mutating = false;
      _loadActions();
    }
  }

  @override
  void dispose() {
    _generation++;
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _editableKeys {
    final state = widget.machine.states[_instance.currentState];
    return [
      for (final key in state?.editableFields ?? const <String>[])
        if (widget.machine.instanceDataSchema[key] case final schema?)
          if (schema.formula == null && schema.writableBy != 'effect')
            if (_isEditingFieldVisible(schema, {
              ..._instance.instanceData,
              ..._edits,
            }))
              key,
    ];
  }

  dynamic _valueFor(String key) =>
      _edits.containsKey(key) ? _edits[key] : _instance.instanceData[key];

  TextEditingController _controllerFor(String key) => _controllers.putIfAbsent(
    key,
    () => TextEditingController(text: '${_valueFor(key) ?? ''}'),
  );

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

  void _resyncControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    for (final key in _editableKeys) {
      final schema = widget.machine.instanceDataSchema[key]!;
      if (schema.type != 'bool' &&
          schema.type != 'date' &&
          schema.type != 'time') {
        _controllerFor(key);
      }
    }
  }

  Future<void> _loadActions() async {
    final generation = _generation;
    final instance = _instance;
    final machine = widget.machine;
    final engine = widget.engine;
    final personaId = widget.personaId;
    final request = ++_actionRequest;
    if (_isCurrent(generation, instance, machine, engine, personaId)) {
      setState(() {
        _loadingActions = true;
        _actions = const [];
        _error = null;
        _retry = null;
      });
    }
    try {
      final result = await engine.availableTransitionsAsync(
        workflowType: instance.workflowType,
        instanceId: instance.instanceId,
        currentState: instance.currentState,
        instanceData: instance.instanceData,
        personaId: personaId,
      );
      if (!_isCurrent(generation, instance, machine, engine, personaId) ||
          request != _actionRequest) {
        return;
      }
      setState(() {
        _actions = result;
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

  Future<void> _save() async {
    if (_mutating || _edits.isEmpty) return;
    final generation = _generation;
    final instance = _instance;
    final machine = widget.machine;
    final engine = widget.engine;
    final personaId = widget.personaId;
    final updates = <String, dynamic>{};
    final editableKeys = _editableKeys;
    for (final key in editableKeys) {
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
    await _runMutation(
      generation: generation,
      instance: instance,
      machine: machine,
      engine: engine,
      personaId: personaId,
      operation: () async {
        await engine.updateInstanceFields(
          workflowType: instance.workflowType,
          instanceId: instance.instanceId,
          fieldUpdates: updates,
          personaId: personaId,
        );
        return WorkflowInstance(
          instanceId: instance.instanceId,
          workflowType: instance.workflowType,
          currentState: instance.currentState,
          instanceData: {...instance.instanceData, ...updates},
          createdByPersonaId: instance.createdByPersonaId,
        );
      },
      retry: _save,
    );
  }

  Future<void> _applyTransition(String transitionId) async {
    final transition = widget.machine.transitions
        .where((candidate) => candidate.id == transitionId)
        .firstOrNull;
    final declaredInputs = transition?.inputs;
    final inputs = declaredInputs == null || declaredInputs.isEmpty
        ? null
        : await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => GenericTransitionInputDialog(
              transition: transition!,
              instanceData: _instance.instanceData,
            ),
          );
    if (declaredInputs != null && declaredInputs.isNotEmpty && inputs == null) {
      return;
    }
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
          transitionId: transitionId,
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
      _edits.clear();
      _instance = next;
      _resyncControllers();
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

  String _fieldLabel(String key, InstanceDataField schema) =>
      _editorLabel(key, schema.labelTemplate);

  String _editorLabel(String key, String? template) {
    final label = (template ?? '')
        .replaceAll('{value.length}', '')
        .replaceAll('{value}', '')
        .replaceAll(RegExp(r'[:\-–—]+\s*$'), '')
        .trim();
    if (label.isNotEmpty) return label;
    return _humanizeFieldName(key);
  }

  bool _isVisibleField(String key, InstanceDataField schema) {
    if (widget.visibleFieldKeys != null &&
        !widget.visibleFieldKeys!.contains(key))
      return false;
    if (schema.displayContexts != null &&
        schema.displayContexts!.isNotEmpty &&
        !schema.displayContexts!.contains(widget.displayContext)) {
      return false;
    }
    final value = _instance.instanceData[key];
    if (schema.hideWhenEmpty && _isEmpty(value)) return false;
    return _renderLabel(schema.labelTemplate ?? key, value).trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final editable = _editableKeys;
    return Card(
      key: ValueKey('generic-instance-card-${_instance.instanceId}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in widget.machine.instanceDataSchema.entries)
                if (_isVisibleField(entry.key, entry.value))
                  KeyedSubtree(
                    key: ValueKey(
                      'generic-instance-field-${_instance.instanceId}-${entry.key}',
                    ),
                    child: WorkflowFactPillRow(
                      instanceData: _instance.instanceData,
                      instanceDataSchema: {
                        entry.key: WorkflowFactPillFieldSchema(
                          displayIcon: entry.value.displayIcon,
                          labelTemplate: entry.value.labelTemplate,
                          hideWhenEmpty: entry.value.hideWhenEmpty,
                          displayContexts: entry.value.displayContexts,
                        ),
                      },
                      displayContext: widget.displayContext,
                      foreground: widget.foreground,
                      accent: widget.accent,
                    ),
                  ),
              if (widget.showEditors && editable.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final key in editable)
                  _editor(key, widget.machine.instanceDataSchema[key]!),
                const SizedBox(height: 8),
                FilledButton(
                  key: ValueKey(
                    'generic-instance-save-${_instance.instanceId}',
                  ),
                  onPressed: _mutating || _edits.isEmpty ? null : _save,
                  child: const Text('Save changes'),
                ),
              ],
              if (_loadingActions || _mutating)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(
                    key: ValueKey(
                      'generic-instance-progress-${_instance.instanceId}',
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  key: ValueKey(
                    'generic-instance-error-${_instance.instanceId}',
                  ),
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(_error!)),
                      TextButton(
                        key: ValueKey(
                          'generic-instance-retry-${_instance.instanceId}',
                        ),
                        onPressed: _mutating ? null : () => _retry?.call(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              if (!_loadingActions)
                WorkflowActionButtonRow(
                  surface: 'generic-instance-${_instance.instanceId}',
                  availableTransitions: [
                    for (final action in _actions)
                      WorkflowActionButtonTransition(
                        id: action.id,
                        label: action.label,
                        iconName: action.icon,
                        tone: _toneFor(action.tone),
                      ),
                  ],
                  onTransitionPressed: _mutating ? null : _applyTransition,
                  foreground: widget.foreground,
                  accent: widget.accent,
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
          ),
        ),
      ),
    );
  }

  Widget _editor(String key, InstanceDataField schema) {
    final disabled = _mutating;
    final label = _fieldLabel(key, schema);
    final editorKey = ValueKey(
      'generic-instance-editor-${_instance.instanceId}-$key',
    );
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
  }) {
    final fieldLabel = label.isEmpty ? _humanizeFieldName(key) : label;
    final value = '${_valueFor(key) ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: editorKey,
        onTap: disabled ? null : onPick,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: fieldLabel,
            enabled: !disabled,
            border: const OutlineInputBorder(),
          ),
          child: Text(value),
        ),
      ),
    );
  }

  String _humanizeFieldName(String key) {
    final spaced = key.replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    if (spaced.isEmpty) return spaced;
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}

/// Schema-driven collection of GAP-1 transition inputs.  Visibility is
/// evaluated against persisted instance data plus the values currently entered
/// in this dialog, so dependent fields update without a second parser.
class GenericTransitionInputDialog extends StatefulWidget {
  const GenericTransitionInputDialog({
    super.key,
    required this.transition,
    required this.instanceData,
  });

  final LoomWorkflowTransition transition;
  final Map<String, dynamic> instanceData;

  @override
  State<GenericTransitionInputDialog> createState() =>
      _GenericTransitionInputDialogState();
}

class _GenericTransitionInputDialogState
    extends State<GenericTransitionInputDialog> {
  final _controllers = <String, TextEditingController>{};
  final _values = <String, dynamic>{};
  final _modes = <String, String>{};
  String? _validationMessage;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key) => _controllers.putIfAbsent(
    key,
    () => TextEditingController(text: '${_values[key] ?? ''}'),
  );

  Map<String, dynamic> get _formulaValues => {
    ...widget.instanceData,
    ..._values,
    ..._modes,
  };

  bool _visible(TransitionInputSpec spec) {
    final formula = spec.visibleWhen;
    return formula == null || evaluateFormula(formula, instanceData: _formulaValues) == true;
  }

  String _label(String key) {
    final spaced = key.replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  Iterable<MapEntry<String, TransitionInputSpec>> get _entries =>
      widget.transition.inputs!.entries;

  String? _modeFor(String group) => _modes[group] ??
      _entries
          .where(
            (entry) =>
                entry.value.modeGroup == group &&
                _visible(entry.value) &&
                (entry.value.writesTo == null ||
                    entry.value.writesTo == entry.key),
          )
          .map((entry) => entry.value.modeValue)
          .whereType<String>()
          .cast<String?>()
          .firstOrNull;

  bool _relevant(String key, TransitionInputSpec spec) {
    final group = spec.modeGroup;
    if (group == null) return true;
    return _modeFor(group) == spec.modeValue;
  }

  void _confirm() {
    final result = <String, dynamic>{};
    for (final entry in _entries) {
      final key = entry.key;
      final spec = entry.value;
      if (!_visible(spec) || !_relevant(key, spec)) continue;
      var value = _values[key];
      if (spec.type == 'number' && value is String && value.trim().isNotEmpty) {
        value = num.tryParse(value.trim());
        if (value == null) {
          setState(() => _validationMessage = '${_label(key)} must be a valid number.');
          return;
        }
      }
      if (spec.type == 'list' && spec.options == null && value is String) {
        value = value
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      final empty = value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty);
      if (spec.required && empty) {
        setState(() => _validationMessage = '${_label(key)} is required.');
        return;
      }
      if (!empty) result[spec.writesTo ?? key] = value;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final renderedGroups = <String>{};
    return AlertDialog(
      key: const ValueKey('generic-transition-input-dialog'),
      title: Text(widget.transition.label),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in _entries) ...[
              if (entry.value.modeGroup case final group?)
                if (renderedGroups.add(group)) _modeGroup(group),
              if (_visible(entry.value) && _relevant(entry.key, entry.value))
                _field(entry.key, entry.value),
            ],
            if (_validationMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _validationMessage!,
                  key: const ValueKey('generic-transition-input-validation-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('generic-transition-input-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('generic-transition-input-confirm'),
          onPressed: _confirm,
          child: Text(widget.transition.label),
        ),
      ],
    );
  }

  Widget _modeGroup(String group) {
    final options = _entries
        .where(
          (entry) =>
              entry.value.modeGroup == group &&
              _visible(entry.value) &&
              (entry.value.writesTo == null ||
                  entry.value.writesTo == entry.key),
        )
        .toList();
    if (options.isEmpty) return const SizedBox();
    final current = _modeFor(group);
    return RadioGroup<String>(
      groupValue: current,
      onChanged: (value) => setState(() {
        if (value != null) _modes[group] = value;
        _validationMessage = null;
      }),
      child: Column(
        children: [
          for (final option in options)
            RadioListTile<String>(
              key: ValueKey('generic-transition-input-mode-$group-${option.value.modeValue}'),
              value: option.value.modeValue!,
              title: Text(_label(option.key)),
            ),
        ],
      ),
    );
  }

  Widget _field(String key, TransitionInputSpec spec) {
    final fieldKey = ValueKey('generic-transition-input-$key');
    // `options` is multi-select for lists.  A text input can also declare
    // options when its persisted contract is a scalar (for example the
    // recurrence position); that remains a single stored string.
    if (spec.type == 'text' && spec.options != null) {
      final selected = _values[key] as String?;
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_label(key)),
            Wrap(
              spacing: 6,
              children: [
                for (final option in spec.options!)
                  ChoiceChip(
                    key: ValueKey('generic-transition-input-$key-$option'),
                    label: Text(option),
                    selected: selected == option,
                    onSelected: (_) => setState(() {
                      _values[key] = option;
                      _validationMessage = null;
                    }),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    if (spec.type == 'list' && spec.options != null) {
      final selected = (_values[key] as List<String>?) ?? <String>[];
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_label(key)),
            Wrap(
              spacing: 6,
              children: [
                for (final option in spec.options!)
                  FilterChip(
                    key: ValueKey('generic-transition-input-$key-$option'),
                    label: Text(option),
                    selected: selected.contains(option),
                    onSelected: (isSelected) => setState(() {
                      final next = [...selected];
                      if (isSelected) {
                        final maxSelections = spec.maxSelections;
                        if (maxSelections != null &&
                            maxSelections > 0 &&
                            next.length >= maxSelections) {
                          next.removeAt(0);
                        }
                        next.add(option);
                      } else {
                        next.remove(option);
                      }
                      _values[key] = next;
                      _validationMessage = null;
                    }),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        key: fieldKey,
        controller: _controllerFor(key),
        keyboardType: spec.type == 'number'
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: _label(key),
          hintText: spec.type == 'list' ? 'Comma-separated values' : null,
        ),
        onChanged: (value) => setState(() {
          _values[key] = value;
          _validationMessage = null;
        }),
      ),
    );
  }
}
