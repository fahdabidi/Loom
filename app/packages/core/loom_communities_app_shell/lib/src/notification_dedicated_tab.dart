part of '../loom_communities_app_shell.dart';

/// The engine-native notification inbox used by the `dedicatedTab` style.
///
/// This surface owns the whole tab body. It deliberately talks to the shared
/// [NotificationInboxController] instead of the legacy notification store so
/// that list rows and mark-read actions use the community's real workflow
/// engine and guarded transition.
class _NotificationDedicatedTabSurface extends StatefulWidget {
  const _NotificationDedicatedTabSurface({
    required this.experience,
    required this.actorIdentity,
    required this.accent,
    this.modernTheme,
  });

  final LoomExperienceDefinition experience;
  final LoomActorIdentity actorIdentity;
  final Color accent;
  final LoomCardTheme? modernTheme;

  @override
  State<_NotificationDedicatedTabSurface> createState() =>
      _NotificationDedicatedTabSurfaceState();
}

class _NotificationDedicatedTabSurfaceState
    extends State<_NotificationDedicatedTabSurface> {
  NotificationInboxController? _controller;
  Timer? _timer;
  List<WorkflowInstance> _items = const [];
  var _isLoading = true;
  var _isRefreshing = false;
  int _initializationGeneration = 0;
  String? _loadError;
  final Set<String> _markingRead = <String>{};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      _notificationRefreshInterval,
      (_) => unawaited(_refresh()),
    );
    unawaited(_initializeController());
  }

  @override
  void didUpdateWidget(_NotificationDedicatedTabSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.experience.extensionId == widget.experience.extensionId &&
        oldWidget.actorIdentity.roleId == widget.actorIdentity.roleId) {
      return;
    }
    _controller = null;
    _items = const [];
    _isLoading = true;
    _loadError = null;
    unawaited(_initializeController());
    setState(() {});
  }

  Future<void> _initializeController() async {
    final generation = ++_initializationGeneration;
    try {
      final engine = await workflowEngineForExtensionId(
        widget.experience.extensionId,
      );
      if (!mounted || generation != _initializationGeneration) return;
      _controller = NotificationInboxController(
        engine: engine,
        fanId: widget.actorIdentity.fanId,
      );
      await _refresh();
    } catch (error) {
      if (!mounted || generation != _initializationGeneration) return;
      setState(() {
        _isLoading = false;
        _loadError = '$error';
      });
    }
  }

  Future<void> _refresh() async {
    final controller = _controller;
    if (controller == null || _isRefreshing) return;
    _isRefreshing = true;
    try {
      final page = await controller.queryPage(limit: 1000);
      if (!mounted || !identical(controller, _controller)) return;
      if (_isLoading || !_sameItems(_items, page.items)) {
        setState(() {
          _items = page.items;
          _isLoading = false;
          _loadError = null;
        });
      }
    } catch (error) {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _loadError = '$error';
        });
      }
    } finally {
      _isRefreshing = false;
    }
  }

  bool _sameItems(List<WorkflowInstance> first, List<WorkflowInstance> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index += 1) {
      final left = first[index];
      final right = second[index];
      if (left.instanceId != right.instanceId ||
          left.currentState != right.currentState ||
          left.instanceData['title'] != right.instanceData['title'] ||
          left.instanceData['body'] != right.instanceData['body'] ||
          left.instanceData['createdAt'] != right.instanceData['createdAt']) {
        return false;
      }
    }
    return true;
  }

  Future<void> _markRead(WorkflowInstance notification) async {
    final controller = _controller;
    if (controller == null ||
        notification.currentState != 'unread' ||
        !_markingRead.add(notification.instanceId)) {
      return;
    }
    try {
      await controller.markRead(notification);
      await _refresh();
    } finally {
      _markingRead.remove(notification.instanceId);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground =
        widget.modernTheme?.resolvedHeading ?? _foregroundFor(widget.accent);
    final children = <Widget>[
      _buildHeader(context, foreground),
      if (_isLoading)
        const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_loadError != null)
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError!,
            key: const ValueKey('notification-dedicated-load-error'),
            style: TextStyle(color: foreground),
          ),
        )
      else if (_items.isEmpty)
        _buildEmptyState(context, foreground)
      else
        for (var index = 0; index < _items.length; index += 1) ...[
          _buildRow(context, _items[index], foreground),
          if (index < _items.length - 1)
            Divider(height: 1, color: foreground.withValues(alpha: 0.14)),
        ],
    ];
    return ListView(
      key: const ValueKey('notification-dedicated-tab-list'),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: children,
    );
  }

  Widget _buildHeader(BuildContext context, Color foreground) {
    final fill =
        widget.modernTheme?.resolvedFill ??
        widget.accent.withValues(alpha: 0.10);
    final border =
        widget.modernTheme?.resolvedBorder ??
        foreground.withValues(alpha: 0.18);
    return DecoratedBox(
      key: const ValueKey('notification-dedicated-header'),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.notifications_outlined, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${widget.experience.displayName} notifications',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${_items.where((item) => item.currentState == 'unread').length} unread',
              key: const ValueKey('notification-dedicated-unread-count'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color foreground) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 44),
      child: Column(
        key: const ValueKey('notification-dedicated-empty'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_outlined, color: foreground, size: 52),
          const SizedBox(height: 14),
          Text(
            'No notifications yet.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New updates and reminders for you will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    WorkflowInstance notification,
    Color foreground,
  ) {
    final unread = notification.currentState == 'unread';
    final title = _notificationField(notification, 'title', 'Notification');
    final body = _notificationField(notification, 'body', '');
    final createdAt = _notificationField(notification, 'createdAt', '');
    return ListTile(
      key: ValueKey('notification-dedicated-row-${notification.instanceId}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: SizedBox(
        width: 24,
        child: unread
            ? Icon(
                Icons.circle,
                key: ValueKey(
                  'notification-dedicated-unread-${notification.instanceId}',
                ),
                size: 10,
                color: widget.modernTheme?.accent ?? widget.accent,
              )
            : Icon(
                Icons.notifications_none_outlined,
                size: 18,
                color: foreground.withValues(alpha: 0.58),
              ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: foreground,
          fontWeight: unread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        [
          if (body.isNotEmpty) body,
          if (createdAt.isNotEmpty) 'Created $createdAt',
        ].join('\n'),
        style: TextStyle(color: foreground.withValues(alpha: 0.80)),
      ),
      isThreeLine: body.isNotEmpty && createdAt.isNotEmpty,
      onTap: unread ? () => unawaited(_markRead(notification)) : null,
    );
  }
}
