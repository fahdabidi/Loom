part of loom_communities_app_shell;

const _notificationRefreshInterval = Duration(milliseconds: 250);

/// AppBar entry point for the community's bell-style notification inbox.
class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({
    super.key,
    required this.extensionId,
    required this.fanId,
  });

  final String extensionId;
  final String fanId;

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  NotificationInboxController? _controller;
  Timer? _timer;
  Future<void>? _initialization;
  int _unreadCount = 0;
  bool _isRefreshing = false;
  int _initializationGeneration = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      _notificationRefreshInterval,
      (_) => _refreshUnreadCount(),
    );
    _initialization = _initializeController();
  }

  @override
  void didUpdateWidget(covariant NotificationBellButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extensionId == widget.extensionId &&
        oldWidget.fanId == widget.fanId) {
      return;
    }
    _controller = null;
    _unreadCount = 0;
    _initialization = _initializeController();
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
      await _refreshUnreadCount();
    } catch (_) {
      // Legacy-schema communities may not have an engine-native store. The
      // shell still keeps the AppBar action stable and simply has no badge
      // data until a store is available.
    }
  }

  Future<void> _refreshUnreadCount() async {
    final controller = _controller;
    if (controller == null || _isRefreshing) return;
    _isRefreshing = true;
    try {
      final count = await controller.unreadCount();
      if (!mounted || !identical(controller, _controller)) return;
      if (count != _unreadCount) {
        setState(() => _unreadCount = count);
      }
    } catch (_) {
      // Keep the last known count if a transient engine read fails.
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _openSheet() async {
    await _initialization;
    final controller = _controller;
    if (!mounted || controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NotificationBellSheet(controller: controller),
    );
    if (mounted) await _refreshUnreadCount();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Badge.count(
      key: const ValueKey('notification-bell-badge'),
      count: _unreadCount,
      isLabelVisible: _unreadCount > 0,
      child: IconButton(
        key: const ValueKey('notification-bell-button'),
        tooltip: 'Notifications',
        onPressed: _openSheet,
        icon: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _NotificationBellSheet extends StatefulWidget {
  const _NotificationBellSheet({required this.controller});

  final NotificationInboxController controller;

  @override
  State<_NotificationBellSheet> createState() => _NotificationBellSheetState();
}

class _NotificationBellSheetState extends State<_NotificationBellSheet> {
  Timer? _timer;
  List<WorkflowInstance> _items = const [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final Set<String> _markingRead = <String>{};

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(_notificationRefreshInterval, (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final page = await widget.controller.queryPage(limit: 1000);
      if (!mounted) return;
      final hasChanged = _isLoading || !_sameItems(_items, page.items);
      if (hasChanged) {
        setState(() {
          _items = page.items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && _isLoading) setState(() => _isLoading = false);
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
    if (notification.currentState != 'unread' ||
        !_markingRead.add(notification.instanceId)) {
      return;
    }
    try {
      await widget.controller.markRead(notification);
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
    final height = MediaQuery.sizeOf(context).height * 0.75;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          ListTile(
            title: const Text('Notifications'),
            trailing: IconButton(
              key: const ValueKey('notification-sheet-close'),
              tooltip: 'Close notifications',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildList(context)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('No notifications yet.'));
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final notification = _items[index];
        final unread = notification.currentState == 'unread';
        final title = _notificationField(notification, 'title', 'Notification');
        final body = _notificationField(notification, 'body', '');
        final createdAt = _notificationField(notification, 'createdAt', '');
        return ListTile(
          key: ValueKey('notification-bell-row-${notification.instanceId}'),
          leading: SizedBox(
            width: 24,
            child: unread
                ? Icon(
                    Icons.circle,
                    key: ValueKey(
                      'notification-bell-unread-${notification.instanceId}',
                    ),
                    size: 10,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
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
          ),
          isThreeLine: body.isNotEmpty && createdAt.isNotEmpty,
          onTap: unread ? () => _markRead(notification) : null,
        );
      },
    );
  }
}

String _notificationField(
  WorkflowInstance notification,
  String field,
  String fallback,
) {
  final value = notification.instanceData[field];
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}
