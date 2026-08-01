part of loom_communities_app_shell;

/// Delivers workflow notifications through the host device's local
/// notification system.
class LocalNotificationDeliveryService implements NotificationDeliveryService {
  LocalNotificationDeliveryService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'loom_workflow_notifications';
  static const _channelName = 'Workflow notifications';
  static const _channelDescription =
      'Notifications created by Loom community workflows.';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;

  @override
  Future<void> deliver(WorkflowInstance notification) async {
    try {
      await _initializeOnce();
      await _plugin.show(
        id: _notificationId(notification.instanceId),
        title: _textValue(notification.instanceData['title'], 'Notification'),
        body: _textValue(notification.instanceData['body'], ''),
        notificationDetails: _notificationDetails,
        payload: notification.instanceId,
      );
    } catch (_) {
      // Local notification delivery is best-effort. A missing platform
      // channel, denied permission, or other platform error must never reach
      // the workflow engine.
    }
  }

  Future<void> _initializeOnce() {
    return _initialization ??= _initializePlatform();
  }

  Future<void> _initializePlatform() async {
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('notification_icon'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          linux: LinuxInitializationSettings(
            defaultActionName: 'Open notification',
          ),
        ),
      );
    } catch (_) {
      // Keep initialization one-shot even when no host platform channel is
      // available, as in a unit-test harness.
    }

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {}

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'notification_icon',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static String _textValue(Object? value, String fallback) {
    if (value is! String) return fallback;
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static int _notificationId(String instanceId) {
    var hash = 17;
    for (final codeUnit in instanceId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
