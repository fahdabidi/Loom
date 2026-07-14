part of '../loom_communities_app_shell.dart';

/// Supplies the authoritative roles for one persisted workflow instance.
typedef EngineNativeRolesForInstance =
    Iterable<String> Function(WorkflowInstance instance, String personaId);

/// Builds the complete successful result. Product surfaces own this layout.
typedef EngineNativeBindingsBuilder =
    Widget Function(
      BuildContext context,
      List<EngineNativeResolvedBinding> bindings,
      ValueChanged<WorkflowInstance> onInstanceChanged,
    );

@immutable
class EngineNativeResolvedBinding {
  const EngineNativeResolvedBinding({
    required this.instance,
    required this.machine,
    required this.binding,
    required this.definitionBindingIndex,
  });

  final WorkflowInstance instance;
  final LoomWorkflowStateMachine machine;
  final RenderBinding binding;
  final int definitionBindingIndex;

  String get identity =>
      '${binding.tabId}::${instance.instanceId}::$definitionBindingIndex';
}

/// Headless engine-native binding loader for the Calendar surface.
///
/// [definitions] is a load snapshot. Callers must replace its map when their
/// definitions change; this widget never reads a possibly-replaced map after
/// an asynchronous boundary.
class EngineNativeBindingDispatcher extends StatefulWidget {
  const EngineNativeBindingDispatcher({
    super.key,
    required this.engine,
    required this.definitions,
    required this.tabId,
    required this.personaId,
    required this.builder,
    this.rolesForInstance = _noRolesForInstance,
    this.pageSize = 25,
  }) : assert(pageSize > 0);

  final WorkflowEngineApi engine;
  final Map<String, LoomWorkflowStateMachine> definitions;
  final String tabId;
  final String personaId;
  final EngineNativeBindingsBuilder builder;
  final EngineNativeRolesForInstance rolesForInstance;
  final int pageSize;

  static Iterable<String> _noRolesForInstance(
    WorkflowInstance instance,
    String personaId,
  ) => const <String>[];

  @override
  State<EngineNativeBindingDispatcher> createState() =>
      _EngineNativeBindingDispatcherState();
}

class _EngineNativeBindingDispatcherState
    extends State<EngineNativeBindingDispatcher> {
  static const _enabledTabs = <String>{'calendar'};
  int _generation = 0;
  List<EngineNativeResolvedBinding>? _bindings;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _startLoad();
  }

  @override
  void didUpdateWidget(covariant EngineNativeBindingDispatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.engine, oldWidget.engine) ||
        !identical(widget.definitions, oldWidget.definitions) ||
        widget.tabId != oldWidget.tabId ||
        widget.personaId != oldWidget.personaId ||
        !identical(widget.rolesForInstance, oldWidget.rolesForInstance) ||
        widget.pageSize != oldWidget.pageSize) {
      _startLoad();
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  void _startLoad() {
    final generation = ++_generation;
    final engine = widget.engine;
    final definitions = Map<String, LoomWorkflowStateMachine>.unmodifiable(
      Map<String, LoomWorkflowStateMachine>.from(widget.definitions),
    );
    final tabId = widget.tabId;
    final personaId = widget.personaId;
    final rolesForInstance = widget.rolesForInstance;
    final pageSize = widget.pageSize;
    setState(() {
      _bindings = null;
      _error = null;
    });
    if (!_enabledTabs.contains(tabId)) {
      _publishSuccess(generation, const <EngineNativeResolvedBinding>[]);
      return;
    }
    _load(
      generation: generation,
      engine: engine,
      definitions: definitions,
      tabId: tabId,
      personaId: personaId,
      rolesForInstance: rolesForInstance,
      pageSize: pageSize,
    );
  }

  Future<void> _load({
    required int generation,
    required WorkflowEngineApi engine,
    required Map<String, LoomWorkflowStateMachine> definitions,
    required String tabId,
    required String personaId,
    required EngineNativeRolesForInstance rolesForInstance,
    required int pageSize,
  }) async {
    try {
      final instances = <WorkflowInstance>[];
      final seenCursors = <String>{};
      String? cursor;
      while (true) {
        final page = await engine.queryInstances(
          tabId: tabId,
          personaId: personaId,
          limit: pageSize,
          cursor: cursor,
        );
        // A replaced dispatcher must not turn a completed stale page into
        // further pagination work (or a later stale publication).
        if (!mounted || generation != _generation) return;
        instances.addAll(page.items);
        if (!page.hasMore) break;
        final nextCursor = page.nextCursor;
        if (nextCursor == null ||
            nextCursor.trim().isEmpty ||
            !seenCursors.add(nextCursor)) {
          throw StateError(
            'Invalid pagination cursor while loading $tabId for $personaId',
          );
        }
        cursor = nextCursor;
      }

      final output = <EngineNativeResolvedBinding>[];
      for (final instance in instances) {
        final machine = definitions[instance.workflowType];
        if (machine == null) {
          throw StateError(
            'Missing workflow definition for ${instance.workflowType} '
            'instance ${instance.instanceId}',
          );
        }
        final resolved = resolveBindings(
          machine,
          instance.currentState,
          rolesForInstance(instance, personaId),
          instanceData: instance.instanceData,
          personaId: personaId,
        );
        for (var index = 0; index < machine.renderBindings.length; index++) {
          final binding = machine.renderBindings[index];
          if (binding.tabId == tabId &&
              _enabledTabs.contains(binding.tabId) &&
              resolved.any((candidate) => identical(candidate, binding))) {
            output.add(
              EngineNativeResolvedBinding(
                instance: instance,
                machine: machine,
                binding: binding,
                definitionBindingIndex: index,
              ),
            );
          }
        }
      }
      _publishSuccess(generation, output);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = error);
    }
  }

  void _publishSuccess(
    int generation,
    List<EngineNativeResolvedBinding> value,
  ) {
    if (!mounted || generation != _generation) return;
    setState(
      () => _bindings = List<EngineNativeResolvedBinding>.unmodifiable(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabId = widget.tabId;
    final personaId = widget.personaId;
    final error = _error;
    late final Widget child;
    if (error != null) {
      child = Column(
        key: Key('engine-native-bindings-error-$tabId-$personaId'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$error'),
          TextButton(
            key: Key('engine-native-bindings-retry-$tabId-$personaId'),
            onPressed: _startLoad,
            child: const Text('Retry'),
          ),
        ],
      );
    } else {
      final bindings = _bindings;
      if (bindings == null) {
        child = SizedBox(
          key: Key('engine-native-bindings-loading-$tabId-$personaId'),
        );
      } else {
        final generation = _generation;
        final result = widget.builder(context, bindings, (WorkflowInstance _) {
          if (!mounted || generation != _generation) return;
          _startLoad();
        });
        child = bindings.isEmpty
            ? KeyedSubtree(
                key: Key('engine-native-bindings-empty-$tabId-$personaId'),
                child: result,
              )
            : result;
      }
    }
    return KeyedSubtree(
      key: Key('engine-native-bindings-$tabId'),
      child: child,
    );
  }
}
