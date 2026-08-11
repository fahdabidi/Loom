part of '../loom_communities_app_shell.dart';

/// A blank, schema-driven editor for creating a workflow instance.
class GenericWorkflowCreationCard extends StatefulWidget {
  const GenericWorkflowCreationCard({
    super.key,
    required this.workflowType,
    required this.machine,
    required this.engine,
    required this.personaId,
    required this.keyPrefix,
    this.onCreated,
    this.title,
    this.resolvedInitialValues = const {},
    this.audienceCandidates = const [],
  });

  final String workflowType;
  final LoomWorkflowStateMachine machine;
  final WorkflowEngineApi engine;
  final String personaId;
  final String keyPrefix;
  final Future<void> Function(String instanceId)? onCreated;
  final String? title;
  final Map<String, dynamic> resolvedInitialValues;
  final List<AudienceMultiSelectCandidate> audienceCandidates;

  @override
  State<GenericWorkflowCreationCard> createState() =>
      _GenericWorkflowCreationCardState();
}

class _GenericWorkflowCreationCardState
    extends State<GenericWorkflowCreationCard> {
  final Map<String, dynamic> _values = <String, dynamic>{};
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _values.addAll(widget.resolvedInitialValues);
  }

  List<MapEntry<String, InstanceDataField>> get _fields {
    final editable =
        widget.machine.states[widget.machine.initialState]?.editableFields ??
        const <String>[];
    return [
      for (final key in editable)
        if (widget.machine.instanceDataSchema[key] case final schema?)
          if (_isEditingFieldVisible(schema, _values)) MapEntry(key, schema),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controller(String key) => _controllers.putIfAbsent(
    key,
    () => TextEditingController(text: '${_values[key] ?? ''}'),
  );


  String _label(String key, InstanceDataField schema) {
    final template = (schema.labelTemplate ?? '')
        .replaceAll('{value.length}', '')
        .replaceAll('{value}', '')
        .replaceAll(RegExp(r'[:\-–—]+\s*$'), '')
        .trim();
    if (template.isNotEmpty) return template;
    return key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceFirstMapped(
          RegExp(r'^.'),
          (match) => match.group(0)!.toUpperCase(),
        );
  }

  Future<void> _submit() async {
    if (_saving) return;
    for (final field in _fields) {
      final value = _values[field.key];
      final empty =
          value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is Iterable && value.isEmpty);
      if (field.value.required && empty) {
        setState(
          () => _error = '${_label(field.key, field.value)} is required.',
        );
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    String? instanceId;
    try {
      final values = <String, dynamic>{
        ..._values,
        for (final field in _fields)
          if (_values.containsKey(field.key))
            field.key: _normalizedValue(field.key, field.value),
      };
      instanceId = await widget.engine.createInstance(
        workflowType: widget.workflowType,
        initialInstanceData: values,
        personaId: widget.personaId,
      );
      await widget.onCreated?.call(instanceId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = instanceId == null
            ? 'Could not create the instance. Please try again.'
            : 'The instance was created, but the follow-up step failed. Please retry.';
      });
    }
  }

  dynamic _normalizedValue(String key, InstanceDataField schema) {
    final value = _values[key];
    if (schema.type == 'number') {
      if (value is num) return value;
      if (value is String) return num.tryParse(value.trim()) ?? value;
      return value;
    }
    if (schema.type != 'list' && schema.type != 'personaId[]') return value;
    if (value is Iterable) return value.toList(growable: false);
    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return value;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title ?? 'New ${widget.workflowType}'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final field in _fields) _editor(field.key, field.value),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                key: ValueKey('${widget.keyPrefix}-error'),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: ValueKey('${widget.keyPrefix}-submit'),
        onPressed: _saving ? null : _submit,
        child: Text(_saving ? 'Creating…' : 'Create'),
      ),
    ],
  );

  Widget _editor(String key, InstanceDataField schema) {
    final label = _label(key, schema);
    final editorKey = ValueKey('${widget.keyPrefix}-editor-$key');
    if (schema.type == 'personaId[]' && widget.audienceCandidates.isNotEmpty) {
      final selected =
          (_values[key] is Iterable
                  ? (_values[key] as Iterable)
                  : const <dynamic>[])
              .map((value) => '$value')
              .toSet();
      return KeyedSubtree(
        key: editorKey,
        child: AudienceMultiSelectPicker(
          candidates: widget.audienceCandidates,
          selectedPersonaIds: selected,
          onChanged: (next) =>
              setState(() => _values[key] = next.toList()..sort()),
          label: label,
        ),
      );
    }
    switch (schema.type) {
      case 'bool':
        return SwitchListTile(
          key: editorKey,
          title: Text(label),
          value: _values[key] == true,
          onChanged: _saving
              ? null
              : (value) => setState(() => _values[key] = value),
        );
      case 'date':
        return _picker(
          key: key,
          label: label,
          editorKey: editorKey,
          onPick: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  DateTime.tryParse('${_values[key] ?? ''}') ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null && mounted) {
              setState(
                () => _values[key] =
                    '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
              );
            }
          },
        );
      case 'time':
        return _picker(
          key: key,
          label: label,
          editorKey: editorKey,
          onPick: () async {
            final parts = '${_values[key] ?? ''}'.split(':');
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.tryParse(parts.first) ?? TimeOfDay.now().hour,
                minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
              ),
            );
            if (picked != null && mounted) {
              setState(
                () => _values[key] =
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
            controller: _controller(key),
            enabled: !_saving,
            keyboardType: schema.type == 'number'
                ? const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  )
                : TextInputType.text,
            decoration: InputDecoration(labelText: label),
            onChanged: (value) => setState(() => _values[key] = value),
          ),
        );
    }
  }

  Widget _picker({
    required String key,
    required String label,
    required Key editorKey,
    required Future<void> Function() onPick,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      key: editorKey,
      onTap: _saving ? null : onPick,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, enabled: !_saving),
        child: Text('${_values[key] ?? ''}'),
      ),
    ),
  );
}
