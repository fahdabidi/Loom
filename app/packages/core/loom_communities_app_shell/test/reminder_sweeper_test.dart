import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

/// The half of `set_reminder` that was missing.
void main() {
  test('delivers a due reminder exactly once across sweeps', () async {
    final engine = _DueEngine([_notification('n1')]);
    final delivery = _RecordingDelivery();
    final sweeper = LoomReminderSweeper(engine: engine, delivery: delivery);

    expect(await sweeper.sweep(), 1);
    expect(delivery.delivered, ['n1']);

    // A reminder stays due forever once its dueAt passes — nothing marks it
    // delivered. Without the guard this sweep would show it again.
    expect(await sweeper.sweep(), 0);
    expect(delivery.delivered, ['n1']);
  });

  test('delivers each reminder in a backlog', () async {
    final engine = _DueEngine([
      _notification('n1'),
      _notification('n2'),
      _notification('n3'),
    ]);
    final delivery = _RecordingDelivery();

    expect(
      await LoomReminderSweeper(engine: engine, delivery: delivery).sweep(),
      3,
    );
    expect(delivery.delivered, ['n1', 'n2', 'n3']);
  });

  test('a failed delivery is retried on the next sweep', () async {
    final engine = _DueEngine([_notification('n1')]);
    final delivery = _RecordingDelivery(failFirst: true);
    final sweeper = LoomReminderSweeper(engine: engine, delivery: delivery);

    // A delivery that threw is not a delivery, so it must not be remembered as
    // one.
    expect(await sweeper.sweep(), 0);
    expect(sweeper.deliveredCount, 0);

    expect(await sweeper.sweep(), 1);
    expect(delivery.delivered, ['n1']);
  });

  test('an unreachable backend returns zero rather than throwing', () async {
    // A sweep runs on app lifecycle. A backend that is down must not take a
    // screen with it.
    final sweeper = LoomReminderSweeper(
      engine: _ThrowingEngine(),
      delivery: _RecordingDelivery(),
    );
    expect(await sweeper.sweep(), 0);
  });

  test('asks the engine for the reminders due at the given clock', () async {
    final engine = _DueEngine([]);
    final when = DateTime.utc(2026, 8, 27, 9);
    await LoomReminderSweeper(
      engine: engine,
      delivery: _RecordingDelivery(),
      clock: () => when,
    ).sweep();
    expect(engine.askedFor, when);
  });

  test('reset re-delivers, for a fan switching accounts', () async {
    final engine = _DueEngine([_notification('n1')]);
    final delivery = _RecordingDelivery();
    final sweeper = LoomReminderSweeper(engine: engine, delivery: delivery);

    await sweeper.sweep();
    // The reminders of the fan who left are not the reminders of the one
    // arriving, and the id set is not scoped by fan.
    sweeper.reset();
    await sweeper.sweep();
    expect(delivery.delivered, ['n1', 'n1']);
  });
}

WorkflowInstance _notification(String id) => WorkflowInstance(
  instanceId: id,
  workflowType: 'club-notification',
  currentState: 'unread',
  instanceData: const {'title': 'Meeting soon'},
  createdByFanId: 'fan-alice',
);

class _RecordingDelivery implements NotificationDeliveryService {
  _RecordingDelivery({this.failFirst = false});

  final bool failFirst;
  final List<String> delivered = [];
  var _calls = 0;

  @override
  Future<void> deliver(WorkflowInstance notification) async {
    _calls++;
    if (failFirst && _calls == 1) {
      throw StateError('the platform channel was unavailable');
    }
    delivered.add(notification.instanceId);
  }
}

class _DueEngine implements WorkflowEngineApi {
  _DueEngine(this._due);

  final List<WorkflowInstance> _due;
  DateTime? askedFor;

  @override
  Future<List<WorkflowInstance>> dueNotifications({
    required DateTime asOf,
  }) async {
    askedFor = asOf;
    return _due;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}

class _ThrowingEngine implements WorkflowEngineApi {
  @override
  Future<List<WorkflowInstance>> dueNotifications({
    required DateTime asOf,
  }) async => throw StateError('backend unreachable');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}
