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
  }) : assert(displayContext == 'tile' || displayContext == 'detail');

  final WorkflowInstance instance;
  final LoomWorkflowStateMachine machine;
  final WorkflowEngineApi engine;
  final String personaId;
  final String displayContext;
  final ValueChanged<WorkflowInstance>? onInstanceChanged;
  final Color? accent;
  final Color? foreground;

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
      _loadActions();
    }
  }

  @override
  void dispose() {
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
          if (schema.formula == null && schema.writableBy != 'effect') key,
    ];
  }

  dynamic _valueFor(String key) =>
      _edits.containsKey(key) ? _edits[key] : _instance.instanceData[key];

  TextEditingController _controllerFor(String key) => _controllers.putIfAbsent(
    key,
    () => TextEditingController(text: '${_valueFor(key) ?? ''}'),
  );

  Future<void> _loadActions() async {
    final request = ++_actionRequest;
    if (mounted) {
      setState(() {
        _loadingActions = true;
        _error = null;
        _retry = null;
      });
    }
    try {
      final result = await widget.engine.availableTransitionsAsync(
        workflowType: _instance.workflowType,
        instanceId: _instance.instanceId,
        currentState: _instance.currentState,
        instanceData: _instance.instanceData,
        personaId: widget.personaId,
      );
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _actions = result;
        _loadingActions = false;
      });
    } catch (_) {
      if (!mounted || request != _actionRequest) return;
      setState(() {
        _loadingActions = false;
        _error = 'Could not load available actions.';
        _retry = _loadActions;
      });
    }
  }

  Future<void> _save() async {
    if (_mutating || _edits.isEmpty) return;
    final updates = <String, dynamic>{};
    for (final key in _editableKeys) {
      if (!_edits.containsKey(key)) continue;
      final field = widget.machine.instanceDataSchema[key]!;
      final value = _edits[key];
      if (field.type == 'number' && value is String) {
        final parsed = num.tryParse(value.trim());
        if (parsed == null) {
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
    await _runMutation(() async {
      await widget.engine.updateInstanceFields(
        workflowType: _instance.workflowType,
        instanceId: _instance.instanceId,
        fieldUpdates: updates,
        personaId: widget.personaId,
      );
      final next = WorkflowInstance(
        instanceId: _instance.instanceId,
        workflowType: _instance.workflowType,
        currentState: _instance.currentState,
        instanceData: {..._instance.instanceData, ...updates},
        createdByPersonaId: _instance.createdByPersonaId,
      );
      _edits.clear();
      _publish(next);
    }, _save);
  }

  Future<void> _applyTransition(String transitionId) => _runMutation(() async {
    final result = await widget.engine.applyTransition(
      workflowType: _instance.workflowType,
      instanceId: _instance.instanceId,
      transitionId: transitionId,
      personaId: widget.personaId,
    );
    _edits.clear();
    _publish(
      WorkflowInstance(
        instanceId: _instance.instanceId,
        workflowType: _instance.workflowType,
        currentState: result.newState,
        instanceData: result.newInstanceData,
        createdByPersonaId: _instance.createdByPersonaId,
      ),
    );
  }, () => _applyTransition(transitionId));

  Future<void> _runMutation(
    Future<void> Function() operation,
    Future<void> Function() retry,
  ) async {
    if (_mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
      _retry = null;
    });
    try {
      await operation();
      if (!mounted) return;
      setState(() => _mutating = false);
      await _loadActions();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mutating = false;
        _error = 'Could not save this change. Please try again.';
        _retry = retry;
      });
    }
  }

  void _publish(WorkflowInstance next) {
    _instance = next;
    widget.onInstanceChanged?.call(next);
  }

  WorkflowActionTone _toneFor(String? tone) => switch (tone) {
    'secondary' => WorkflowActionTone.secondary,
    'destructive' => WorkflowActionTone.destructive,
    _ => WorkflowActionTone.primary,
  };

  String _fieldLabel(String key, InstanceDataField schema) =>
      _renderLabel(schema.labelTemplate ?? key, _valueFor(key));

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
              if (editable.isNotEmpty) ...[
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
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(
                    key: ValueKey('generic-instance-progress'),
                  ),
                ),
              if (_error != null)
                Padding(
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
            final initial =
                DateTime.tryParse('${_valueFor(key) ?? ''}') ?? DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null && mounted) {
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
            final parts = '${_valueFor(key) ?? ''}'.split(':');
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.tryParse(parts.first) ?? TimeOfDay.now().hour,
                minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
              ),
            );
            if (picked != null && mounted) {
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
    child: OutlinedButton(
      key: editorKey,
      onPressed: disabled ? null : onPick,
      child: Text('${label.isEmpty ? key : label}: ${_valueFor(key) ?? ''}'),
    ),
  );
}
