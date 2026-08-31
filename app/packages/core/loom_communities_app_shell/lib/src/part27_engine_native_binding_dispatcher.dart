part of '../loom_communities_app_shell.dart';

/// Supplies the authoritative roles for one persisted workflow instance.
typedef EngineNativeRolesForInstance =
    Iterable<String> Function(WorkflowInstance instance, String fanId);

/// Builds the complete successful result. Product surfaces own this layout.
typedef EngineNativeBindingsBuilder =
    Widget Function(
      BuildContext context,
      List<EngineNativeResolvedBinding> bindings,
      ValueChanged<WorkflowInstance> onInstanceChanged,
    );

/// Opens a create action that is owned by a specific rendered instance.
typedef EngineNativeInstanceScopedCreate =
    Future<void> Function({
      required WorkflowAction action,
      required WorkflowInstance instance,
      required RenderBinding binding,
    });

@immutable
class EngineNativeResolvedBinding {
  const EngineNativeResolvedBinding({
    required this.instance,
    required this.machine,
    required this.binding,
    required this.definitionBindingIndex,
    this.responseMachine,
  });

  final WorkflowInstance instance;
  final LoomWorkflowStateMachine machine;
  final RenderBinding binding;
  final int definitionBindingIndex;

  /// The definition named by `binding.responseTable.workflowType`, when there
  /// is one. Resolved here because this is where the definitions map is in
  /// scope; the surfaces below it hold only their own machine.
  ///
  /// Needed to offer response actions to a member who has **no** response row
  /// yet: availability has to be computed against that workflow's declared
  /// `initialState`, and without it the surface can only ask about rows that
  /// already exist — which is why a member who joined after an event was
  /// created saw no RSVP controls at all.
  final LoomWorkflowStateMachine? responseMachine;

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
    required this.fanId,
    required this.builder,
    this.rolesForInstance = _noRolesForInstance,
    this.pageSize = 25,
  }) : assert(pageSize > 0);

  final WorkflowEngineApi engine;
  final Map<String, LoomWorkflowStateMachine> definitions;
  final String tabId;
  final String fanId;
  final EngineNativeBindingsBuilder builder;
  final EngineNativeRolesForInstance rolesForInstance;
  final int pageSize;

  static Iterable<String> _noRolesForInstance(
    WorkflowInstance instance,
    String fanId,
  ) => const <String>[];

  @override
  State<EngineNativeBindingDispatcher> createState() =>
      _EngineNativeBindingDispatcherState();
}

class _EngineNativeBindingDispatcherState
    extends State<EngineNativeBindingDispatcher> {
  int _generation = 0;
  List<EngineNativeResolvedBinding>? _bindings;
  LoomWorkflowReadMetadata? _readMetadata;
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
        widget.fanId != oldWidget.fanId ||
        !identical(widget.rolesForInstance, oldWidget.rolesForInstance) ||
        widget.pageSize != oldWidget.pageSize) {
      // A widget reconfiguration can make the displayed bindings belong to a
      // different query context. Do not retain those while its replacement
      // loads.
      _startLoad(clearBindings: true);
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  void _startLoad({bool clearBindings = false}) {
    final generation = ++_generation;
    final engine = widget.engine;
    final definitions = Map<String, LoomWorkflowStateMachine>.unmodifiable(
      Map<String, LoomWorkflowStateMachine>.from(widget.definitions),
    );
    final tabId = widget.tabId;
    final fanId = widget.fanId;
    final rolesForInstance = widget.rolesForInstance;
    final pageSize = widget.pageSize;
    setState(() {
      // Mutation callbacks re-query the same context. Retaining the last
      // successful result keeps the enclosing scrollable's extent stable
      // until the refreshed bindings are ready to replace it.
      if (clearBindings) {
        _bindings = null;
        _readMetadata = null;
      }
      _error = null;
    });
    _load(
      generation: generation,
      engine: engine,
      definitions: definitions,
      tabId: tabId,
      fanId: fanId,
      rolesForInstance: rolesForInstance,
      pageSize: pageSize,
    );
  }

  Future<void> _load({
    required int generation,
    required WorkflowEngineApi engine,
    required Map<String, LoomWorkflowStateMachine> definitions,
    required String tabId,
    required String fanId,
    required EngineNativeRolesForInstance rolesForInstance,
    required int pageSize,
  }) async {
    try {
      final instances = <WorkflowInstance>[];
      final seenCursors = <String>{};
      LoomWorkflowReadMetadata? readMetadata;
      String? cursor;
      while (true) {
        final page = await engine.queryInstances(
          tabId: tabId,
          fanId: fanId,
          limit: pageSize,
          cursor: cursor,
        );
        // A replaced dispatcher must not turn a completed stale page into
        // further pagination work (or a later stale publication).
        if (!mounted || generation != _generation) return;
        instances.addAll(page.items);
        if (engine case final LoomReplicaFallbackWorkflowEngineApi replica) {
          readMetadata = replica.lastRead;
        }
        if (!page.hasMore) break;
        final nextCursor = page.nextCursor;
        if (nextCursor == null ||
            nextCursor.trim().isEmpty ||
            !seenCursors.add(nextCursor)) {
          throw StateError(
            'Invalid pagination cursor while loading $tabId for $fanId',
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
          rolesForInstance(instance, fanId),
          instanceData: instance.instanceData,
          fanId: fanId,
        );
        for (var index = 0; index < machine.renderBindings.length; index++) {
          final binding = machine.renderBindings[index];
          if (binding.tabId == tabId &&
              resolved.any((candidate) => identical(candidate, binding))) {
            output.add(
              EngineNativeResolvedBinding(
                instance: instance,
                machine: machine,
                binding: binding,
                definitionBindingIndex: index,
                responseMachine:
                    definitions[binding.responseTable?.workflowType],
              ),
            );
          }
        }
      }
      _publishSuccess(generation, output, readMetadata);
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _error = error);
    }
  }

  void _publishSuccess(
    int generation,
    List<EngineNativeResolvedBinding> value,
    LoomWorkflowReadMetadata? readMetadata,
  ) {
    if (!mounted || generation != _generation) return;
    setState(() {
      _bindings = List<EngineNativeResolvedBinding>.unmodifiable(value);
      _readMetadata = readMetadata;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabId = widget.tabId;
    final fanId = widget.fanId;
    final error = _error;
    late final Widget child;
    if (error != null) {
      child = Column(
        key: Key('engine-native-bindings-error-$tabId-$fanId'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$error'),
          TextButton(
            key: Key('engine-native-bindings-retry-$tabId-$fanId'),
            onPressed: _startLoad,
            child: const Text('Retry'),
          ),
        ],
      );
    } else {
      final bindings = _bindings;
      if (bindings == null) {
        child = SizedBox(
          key: Key('engine-native-bindings-loading-$tabId-$fanId'),
        );
      } else {
        final generation = _generation;
        final result = widget.builder(context, bindings, (WorkflowInstance _) {
          if (!mounted || generation != _generation) return;
          _startLoad();
        });
        child = bindings.isEmpty
            ? KeyedSubtree(
                key: Key('engine-native-bindings-empty-$tabId-$fanId'),
                child: result,
              )
            : result;
      }
    }
    final readMetadata = _readMetadata;
    final decoratedChild = readMetadata?.cameFromReplica == true
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LoomOfflineReplicaReadStatus(metadata: readMetadata!),
              const SizedBox(height: 12),
              child,
            ],
          )
        : child;
    return KeyedSubtree(
      key: Key('engine-native-bindings-$tabId'),
      child: decoratedChild,
    );
  }
}

/// Renders one resolved binding as its declared archetype, or the generic
/// schema-driven fallback if no bespoke archetype exists for its
/// `cardSurfaceFamily`. This is the tab-agnostic half of the generic
/// pipeline: [EngineNativeBindingDispatcher] decides *which* bindings apply
/// to a tab; this widget decides *how one binding renders*, regardless of
/// which tab it is rendering in.
///
/// To add a new bespoke archetype, add a case here — this is the single
/// place `cardSurfaceFamily` is ever switched on for rendering purposes.
class EngineNativeArchetypeCard extends StatelessWidget {
  const EngineNativeArchetypeCard({
    required this.contentKey,
    required this.resolved,
    required this.engine,
    required this.communityExtensionId,
    required this.fanId,
    required this.roleId,
    required this.accent,
    required this.onInstanceChanged,
    this.modernTheme,
    this.displayContext = 'tile',
    this.showEditors = true,
    this.visibleFieldKeys,
    this.onInstanceScopedCreate,
  }) : assert(displayContext == 'tile' || displayContext == 'detail');

  /// Applied to the rendered card rather than this dispatcher widget so a
  /// caller's keyed identity remains the same as before this extraction.
  final Key contentKey;
  final EngineNativeResolvedBinding resolved;
  final WorkflowEngineApi engine;
  final String communityExtensionId;
  final String fanId;
  final String roleId;
  final Color accent;
  final ValueChanged<WorkflowInstance> onInstanceChanged;
  final LoomCardTheme? modernTheme;
  final String displayContext;
  final bool showEditors;
  final Set<String>? visibleFieldKeys;
  final EngineNativeInstanceScopedCreate? onInstanceScopedCreate;

  @override
  Widget build(BuildContext context) {
    switch (resolved.binding.cardSurfaceFamily) {
      case 'event-rsvp':
        return _EventRsvpDetailCard(
          key: contentKey,
          instance: resolved.instance,
          binding: resolved.binding,
          machine: resolved.machine,
          responseMachine: resolved.responseMachine,
          engine: engine,
          communityExtensionId: communityExtensionId,
          fanId: fanId,
          roleId: roleId,
          accent: accent,
          onInstanceChanged: onInstanceChanged,
          instanceScopedCreateActions: [
            for (final action in resolved.binding.actions)
              if (action.kind == 'create' &&
                  action.scope == 'instance' &&
                  action.presentation == 'button' &&
                  action.byRoleIds?.contains(roleId) == true)
                action,
          ],
          onInstanceScopedCreate: onInstanceScopedCreate == null
              ? null
              : (action) => onInstanceScopedCreate!(
                  action: action,
                  instance: resolved.instance,
                  binding: resolved.binding,
                ),
        );
      case 'votePoll':
        // The repeater binding is the ballot (candidates plus per-candidate
        // vote buttons). The tournament-event summary binding has no repeater
        // but is the one other votePoll-family case with a bespoke surface:
        // its attendance/quorum summary belongs to VotePollArchetypeCard too.
        if (resolved.binding.repeater != null ||
            (resolved.binding.repeater == null &&
                resolved.machine.workflowType == 'tournament-event')) {
          return VotePollArchetypeCard(
            key: contentKey,
            resolved: resolved,
            engine: engine,
            fanId: fanId,
            accent: accent,
            modernTheme: modernTheme,
            onInstanceChanged: onInstanceChanged,
          );
        }
        return GenericWorkflowInstanceCard(
          key: contentKey,
          instance: resolved.instance,
          machine: resolved.machine,
          engine: engine,
          fanId: fanId,
          displayContext: displayContext,
          showEditors: showEditors,
          visibleFieldKeys: visibleFieldKeys,
          accent: accent,
          modernTheme: modernTheme,
          onInstanceChanged: onInstanceChanged,
          instanceScopedCreateActions: [
            for (final action in resolved.binding.actions)
              if (action.kind == 'create' &&
                  action.scope == 'instance' &&
                  action.presentation == 'button' &&
                  action.byRoleIds?.contains(roleId) == true)
                action,
          ],
          onInstanceScopedCreate: onInstanceScopedCreate == null
              ? null
              : (action) => onInstanceScopedCreate!(
                  action: action,
                  instance: resolved.instance,
                  binding: resolved.binding,
                ),
        );
      case 'equipment-loan':
        return EquipmentLoanArchetypeCard(
          key: contentKey,
          resolved: resolved,
          engine: engine,
          fanId: fanId,
          accent: accent,
          modernTheme: modernTheme,
          displayContext: displayContext,
          visibleFieldKeys: visibleFieldKeys,
          onInstanceChanged: onInstanceChanged,
        );
      case 'documentLibrary':
        return DocumentLibraryArchetypeCard(
          key: contentKey,
          resolved: resolved,
          engine: engine,
          fanId: fanId,
          accent: accent,
          modernTheme: modernTheme,
          displayContext: displayContext,
          visibleFieldKeys: visibleFieldKeys,
          onInstanceChanged: onInstanceChanged,
        );
      case 'searchAiAnswer':
        return SearchAiAnswerArchetypeCard(
          key: contentKey,
          resolved: resolved,
          engine: engine,
          fanId: fanId,
          accent: accent,
          onInstanceChanged: onInstanceChanged,
          modernTheme: modernTheme,
          displayContext: displayContext,
          visibleFieldKeys: visibleFieldKeys,
        );
      case 'exportWizard':
        return ExportWizardArchetypeCard(
          key: contentKey,
          resolved: resolved,
          engine: engine,
          fanId: fanId,
          accent: accent,
          onInstanceChanged: onInstanceChanged,
          modernTheme: modernTheme,
          displayContext: displayContext,
          visibleFieldKeys: visibleFieldKeys,
        );
      default:
        return GenericWorkflowInstanceCard(
          key: contentKey,
          instance: resolved.instance,
          machine: resolved.machine,
          engine: engine,
          fanId: fanId,
          displayContext: displayContext,
          showEditors: showEditors,
          visibleFieldKeys: visibleFieldKeys,
          accent: accent,
          modernTheme: modernTheme,
          onInstanceChanged: onInstanceChanged,
          instanceScopedCreateActions: [
            for (final action in resolved.binding.actions)
              if (action.kind == 'create' &&
                  action.scope == 'instance' &&
                  action.presentation == 'button' &&
                  action.byRoleIds?.contains(roleId) == true)
                action,
          ],
          onInstanceScopedCreate: onInstanceScopedCreate == null
              ? null
              : (action) => onInstanceScopedCreate!(
                  action: action,
                  instance: resolved.instance,
                  binding: resolved.binding,
                ),
        );
    }
  }
}
