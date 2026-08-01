part of loom_communities_app_shell;

/// FloatingActionButton entry point for the community's FAB-style notification
/// inbox.
class NotificationFab extends StatefulWidget {
  const NotificationFab({
    super.key,
    required this.extensionId,
    required this.personaId,
  });

  final String extensionId;
  final String personaId;

  @override
  State<NotificationFab> createState() => _NotificationFabState();
}

class _NotificationFabState extends State<NotificationFab> {
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
  void didUpdateWidget(covariant NotificationFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extensionId == widget.extensionId &&
        oldWidget.personaId == widget.personaId) {
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
        personaId: widget.personaId,
      );
      await _refreshUnreadCount();
    } catch (_) {
      // Legacy-schema communities may not have an engine-native store. The
      // shell still keeps the FAB stable and simply has no badge data until a
      // store is available.
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
      key: const ValueKey('notification-fab-badge'),
      count: _unreadCount,
      isLabelVisible: _unreadCount > 0,
      child: FloatingActionButton.small(
        key: const ValueKey('notification-fab'),
        heroTag: 'notification-fab',
        tooltip: 'Notifications',
        onPressed: _openSheet,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
