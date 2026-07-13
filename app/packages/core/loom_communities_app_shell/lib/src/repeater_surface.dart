part of loom_communities_app_shell;

/// A reusable, cardinality-driven surface for static data or live workflow
/// instance queries. It owns periodic re-querying so a newly-created instance
/// appears without its parent rebuilding the widget.
class RepeaterSurface extends StatefulWidget {
  final List<dynamic>? staticItems;
  final RepeaterQuerySource? querySource;
  final Widget Function(BuildContext context, dynamic item) itemBuilder;
  final Future<void> Function(dynamic item)? onItemAction;
  final Duration refreshInterval;

  const RepeaterSurface.static({
    super.key,
    required List<dynamic> items,
    required this.itemBuilder,
    this.onItemAction,
  }) : staticItems = items,
       querySource = null,
       refreshInterval = Duration.zero;

  const RepeaterSurface.live({
    super.key,
    required this.querySource,
    required this.itemBuilder,
    this.onItemAction,
    this.refreshInterval = const Duration(milliseconds: 250),
  }) : staticItems = null;

  @override
  State<RepeaterSurface> createState() => _RepeaterSurfaceState();
}

class RepeaterQuerySource {
  final WorkflowEngineApi engine;
  final String workflowType;
  final String personaId;
  final SurfaceQuery query;
  final String tabId;

  const RepeaterQuerySource({
    required this.engine,
    required this.workflowType,
    required this.personaId,
    this.query = const SurfaceQuery.empty(),
    this.tabId = 'repeater',
  });
}

class _RepeaterSurfaceState extends State<RepeaterSurface> {
  Timer? _timer;
  List<WorkflowInstance> _items = const [];

  @override
  void initState() {
    super.initState();
    _startQuery();
  }

  @override
  void didUpdateWidget(covariant RepeaterSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.querySource != widget.querySource) _startQuery();
  }

  void _startQuery() {
    _timer?.cancel();
    if (widget.querySource == null) return;
    _refresh();
    _timer = Timer.periodic(widget.refreshInterval, (_) => _refresh());
  }

  Future<void> _refresh() async {
    final source = widget.querySource;
    if (source == null) return;
    final page = await source.engine.queryInstances(
      tabId: source.tabId,
      personaId: source.personaId,
      query: source.query,
      limit: 1000,
    );
    if (!mounted || source != widget.querySource) return;
    setState(
      () => _items = page.items
          .where((item) => item.workflowType == source.workflowType)
          .toList(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.staticItems ?? _items;
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final instance = item is WorkflowInstance ? item : null;
        final body = widget.itemBuilder(context, item);
        final actions = instance != null && widget.querySource != null
            ? widget.querySource!.engine.availableTransitions(
                workflowType: instance.workflowType,
                instanceId: instance.instanceId,
                currentState: instance.currentState,
                instanceData: instance.instanceData,
                personaId: widget.querySource!.personaId,
              )
            : const <LoomWorkflowTransition>[];
        return Column(
          key: ValueKey('repeater-item-$index'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            body,
            if (widget.onItemAction != null)
              TextButton(
                key: ValueKey('repeater-custom-action-$index'),
                onPressed: () => widget.onItemAction!(item),
                child: const Text('Action'),
              ),
            for (final transition in actions)
              TextButton(
                key: ValueKey(
                  'repeater-transition-${instance?.instanceId ?? index}-${transition.id}',
                ),
                onPressed: () async {
                  await widget.querySource!.engine.applyTransition(
                    workflowType: instance!.workflowType,
                    instanceId: instance.instanceId,
                    transitionId: transition.id,
                    personaId: widget.querySource!.personaId,
                  );
                  await _refresh();
                },
                child: Text(transition.label),
              ),
          ],
        );
      },
    );
  }
}
