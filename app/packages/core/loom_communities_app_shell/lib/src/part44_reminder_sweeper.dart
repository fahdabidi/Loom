part of '../loom_communities_app_shell.dart';

/// Delivers the reminders a member asked for, once each, when they come due.
///
/// This is the missing half of `set_reminder`. A member could always schedule a
/// reminder — the transition creates a notification instance carrying `dueAt` —
/// and nothing ever delivered it. `permissions.md` describes `deliver_reminder`
/// as platform-applied "through the `dueNotifications({asOf})` platform
/// service"; this is the caller of that service.
///
/// It replaces a delivery path in the engine that could not have worked: that
/// one fired on `createInstance` when `workflowType == 'notification'`, and no
/// shipped community declares a workflow by that name — the five that have one
/// call it `book-notification`, `garden-notification`, and so on. It also
/// delivered at creation, so a reminder set for next week would have arrived
/// immediately.
final class LoomReminderSweeper {
  LoomReminderSweeper({
    required WorkflowEngineApi engine,
    required NotificationDeliveryService delivery,
    required LoomNotificationConfiguration notificationConfiguration,
    DateTime Function()? clock,
  }) : _engine = engine,
       _delivery = delivery,
       _notificationConfiguration = notificationConfiguration,
       _clock = clock ?? DateTime.now;

  final WorkflowEngineApi _engine;
  final NotificationDeliveryService _delivery;
  final LoomNotificationConfiguration _notificationConfiguration;
  final DateTime Function() _clock;

  /// Reminders already shown, so a second sweep does not repeat them.
  ///
  /// A reminder stays due forever once its `dueAt` passes — nothing marks it
  /// delivered, and `read` means the member read it rather than that it was
  /// shown. Without this set, every sweep would re-deliver the whole backlog.
  ///
  /// Deliberately in memory only. Restarting the app may show a reminder twice;
  /// persisting it would mean a reminder silently lost if the write succeeded
  /// and the delivery did not. Between annoying and losing, this chooses
  /// annoying.
  final Set<String> _delivered = <String>{};

  /// Delivers everything now due, and reports how many were shown.
  ///
  /// Never throws. A sweep runs on app lifecycle, and an unreachable backend
  /// must not take a screen down — a missed reminder is recoverable by the next
  /// sweep, a crash is not.
  Future<int> sweep() async {
    final List<WorkflowInstance> due;
    try {
      due = await _engine.dueNotifications(asOf: _clock());
    } catch (error) {
      debugPrint('Reminder sweep could not query due notifications: $error');
      return 0;
    }

    var shown = 0;
    for (final notification in due) {
      if (!_notificationConfiguration.deviceDeliveryEnabled) continue;
      if (!_delivered.add(notification.instanceId)) continue;
      try {
        await _delivery.deliver(notification);
        shown++;
      } catch (error) {
        // Un-track it so the next sweep tries again. A delivery that failed is
        // not a delivery.
        debugPrint(
          'Reminder delivery failed for ${notification.instanceId}: $error',
        );
        _deliveryFailureCount++;
        _delivered.remove(notification.instanceId);
      }
    }
    return shown;
  }

  /// Forgets what has been delivered, so the next sweep re-delivers.
  ///
  /// For a fan switching accounts: the reminders of the fan who just left are
  /// not the reminders of the one arriving, and the id set is not scoped by fan.
  void reset() => _delivered.clear();

  int _deliveryFailureCount = 0;

  @visibleForTesting
  int get deliveredCount => _delivered.length;

  @visibleForTesting
  int get deliveryFailureCount => _deliveryFailureCount;
}
