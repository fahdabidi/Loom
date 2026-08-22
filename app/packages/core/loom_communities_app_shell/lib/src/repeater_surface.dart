part of loom_communities_app_shell;

/// The visual arrangement used by a [RepeaterSurface].
enum RepeaterLayout { list, grid }

/// Resolves a grid's column count from the space available to the repeater.
typedef RepeaterGridCrossAxisCountBuilder =
    int Function(BuildContext context, BoxConstraints constraints);

/// A reusable, cardinality-driven surface for static data or live workflow
/// instance queries. It owns periodic re-querying so a newly-created instance
/// appears without its parent rebuilding the widget.
class RepeaterSurface extends StatefulWidget {
  final List<dynamic>? staticItems;
  final RepeaterQuerySource? querySource;
  final Widget Function(BuildContext context, dynamic item) itemBuilder;
  final Future<void> Function(dynamic item)? onItemAction;
  final Duration refreshInterval;
  final RepeaterLayout layout;
  final int gridCrossAxisCount;
  final RepeaterGridCrossAxisCountBuilder? gridCrossAxisCountBuilder;
  final double gridChildAspectRatio;
  final double gridMainAxisSpacing;
  final double gridCrossAxisSpacing;
  final bool gridShrinkWrap;
  final bool gridScrollable;
  final bool listShrinkWrap;
  final bool listScrollable;

  const RepeaterSurface.static({
    super.key,
    required List<dynamic> items,
    required this.itemBuilder,
    this.onItemAction,
    this.layout = RepeaterLayout.list,
    this.gridCrossAxisCount = 2,
    this.gridCrossAxisCountBuilder,
    this.gridChildAspectRatio = 1.0,
    this.gridMainAxisSpacing = 0,
    this.gridCrossAxisSpacing = 0,
    this.gridShrinkWrap = false,
    this.gridScrollable = true,
    this.listShrinkWrap = false,
    this.listScrollable = true,
  }) : staticItems = items,
       querySource = null,
       refreshInterval = Duration.zero;

  const RepeaterSurface.live({
    super.key,
    required this.querySource,
    required this.itemBuilder,
    this.onItemAction,
    this.refreshInterval = const Duration(milliseconds: 250),
    this.layout = RepeaterLayout.list,
    this.gridCrossAxisCount = 2,
    this.gridCrossAxisCountBuilder,
    this.gridChildAspectRatio = 1.0,
    this.gridMainAxisSpacing = 0,
    this.gridCrossAxisSpacing = 0,
    this.gridShrinkWrap = false,
    this.gridScrollable = true,
    this.listShrinkWrap = false,
    this.listScrollable = true,
  }) : staticItems = null;

  @override
  State<RepeaterSurface> createState() => _RepeaterSurfaceState();
}

class RepeaterQuerySource {
  final WorkflowEngineApi engine;
  final String workflowType;
  final String fanId;
  final SurfaceQuery query;
  final String tabId;

  const RepeaterQuerySource({
    required this.engine,
    required this.workflowType,
    required this.fanId,
    this.query = const SurfaceQuery.empty(),
    this.tabId = 'repeater',
  });
}

class _RepeaterSurfaceState extends State<RepeaterSurface> {
  Timer? _timer;
  List<WorkflowInstance> _items = const [];
  Map<String, List<LoomWorkflowTransition>> _actionsByInstanceId = const {};

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
      fanId: source.fanId,
      query: source.query,
      limit: 1000,
    );
    if (!mounted || source != widget.querySource) return;
    final items = page.items
        .where((item) => item.workflowType == source.workflowType)
        .toList();
    final actions = <String, List<LoomWorkflowTransition>>{};
    for (final item in items) {
      actions[item.instanceId] = await source.engine.availableTransitionsAsync(
        workflowType: item.workflowType,
        instanceId: item.instanceId,
        currentState: item.currentState,
        instanceData: item.instanceData,
        fanId: source.fanId,
      );
    }
    if (!mounted || source != widget.querySource) return;
    setState(() {
      _items = items;
      _actionsByInstanceId = actions;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.staticItems ?? _items;
    if (widget.layout == RepeaterLayout.grid) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount =
              widget.gridCrossAxisCountBuilder?.call(context, constraints) ??
              widget.gridCrossAxisCount;
          assert(crossAxisCount > 0, 'grid crossAxisCount must be positive');
          return GridView.builder(
            shrinkWrap: widget.gridShrinkWrap,
            physics: widget.gridScrollable
                ? null
                : const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: widget.gridChildAspectRatio,
              mainAxisSpacing: widget.gridMainAxisSpacing,
              crossAxisSpacing: widget.gridCrossAxisSpacing,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildItem(context, items[index], index),
          );
        },
      );
    }
    return ListView.builder(
      shrinkWrap: widget.listShrinkWrap,
      physics: widget.listScrollable
          ? null
          : const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItem(context, items[index], index),
    );
  }

  Widget _buildItem(BuildContext context, dynamic item, int index) {
    final instance = item is WorkflowInstance ? item : null;
    final actions = instance == null
        ? const <LoomWorkflowTransition>[]
        : (_actionsByInstanceId[instance.instanceId] ?? const []);
    return Column(
      key: ValueKey('repeater-item-$index'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.layout == RepeaterLayout.grid)
          Expanded(child: widget.itemBuilder(context, item))
        else
          widget.itemBuilder(context, item),
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
                fanId: widget.querySource!.fanId,
              );
              await _refresh();
            },
            child: Text(transition.label),
          ),
      ],
    );
  }
}
