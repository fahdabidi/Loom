part of '../loom_communities_app_shell.dart';

/// The inline notification presentation used by the `fixedCard` style.
///
/// The App Shell mounts this card only above the `home` tab's native content.
/// It deliberately uses the same engine-backed controller as the bell and
/// dedicated-tab presentations so recipient scoping and guarded mark-read
/// behavior stay consistent across all notification surfaces.
class NotificationFixedCard extends StatefulWidget {
  const NotificationFixedCard({
    super.key,
    required this.extensionId,
    required this.fanId,
  });

  final String extensionId;
  final String fanId;

  @override
  State<NotificationFixedCard> createState() => _NotificationFixedCardState();
}

class _NotificationFixedCardState extends State<NotificationFixedCard> {
  static const _maxListHeight = 320.0;

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
  void didUpdateWidget(covariant NotificationFixedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extensionId == widget.extensionId &&
        oldWidget.fanId == widget.fanId) {
      return;
    }
    _controller = null;
    _items = const [];
    _isLoading = true;
    _loadError = null;
    _markingRead.clear();
    unawaited(_initializeController());
    setState(() {});
  }

  Future<void> _initializeController() async {
    final generation = ++_initializationGeneration;
    try {
      final engine = await workflowEngineForExtensionId(widget.extensionId);
      if (!mounted || generation != _initializationGeneration) return;
      _controller = NotificationInboxController(
        engine: engine,
        fanId: widget.fanId,
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
      if (mounted && _isLoading && identical(controller, _controller)) {
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
    if (_isLoading) return const SizedBox.shrink();
    if (_loadError != null) return _buildError(context);
    // Empty notifications should not reserve permanent space above Home.
    if (_items.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final unreadCount = _items
        .where((item) => item.currentState == 'unread')
        .length;
    return Card(
      key: const ValueKey('notification-fixed-card'),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            key: const ValueKey('notification-fixed-header'),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '$unreadCount unread',
                  key: const ValueKey('notification-fixed-unread-count'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _maxListHeight),
            child: ListView.separated(
              key: const ValueKey('notification-fixed-card-list'),
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _items.length,
              itemBuilder: (context, index) =>
                  _buildRow(context, _items[index], colorScheme),
              separatorBuilder: (_, _) => const Divider(height: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Card(
      key: const ValueKey('notification-fixed-error'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          _loadError!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    WorkflowInstance notification,
    ColorScheme colorScheme,
  ) {
    final unread = notification.currentState == 'unread';
    final title = _notificationField(notification, 'title', 'Notification');
    final body = _notificationField(notification, 'body', '');
    final createdAt = _notificationField(notification, 'createdAt', '');
    return ListTile(
      key: ValueKey('notification-fixed-row-${notification.instanceId}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      leading: SizedBox(
        width: 24,
        child: unread
            ? Icon(
                Icons.circle,
                key: ValueKey(
                  'notification-fixed-unread-${notification.instanceId}',
                ),
                size: 10,
                color: colorScheme.primary,
              )
            : Icon(
                Icons.notifications_none_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: unread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        [
          if (body.isNotEmpty) body,
          if (createdAt.isNotEmpty) 'Created $createdAt',
        ].join('\n'),
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      isThreeLine: body.isNotEmpty && createdAt.isNotEmpty,
      onTap: unread ? () => unawaited(_markRead(notification)) : null,
    );
  }
}
