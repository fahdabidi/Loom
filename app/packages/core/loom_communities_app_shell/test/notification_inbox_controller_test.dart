import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

const _personaA = 'persona-a';
const _personaB = 'persona-b';

LoomWorkflowStateMachine _notificationMachine() =>
    LoomWorkflowStateMachine.fromJson({
      'initialState': 'unread',
      'states': {
        'unread': {'label': 'Unread'},
        'read': {'label': 'Read', 'isTerminal': true},
      },
      'transitions': [
        {
          'id': 'mark-read',
          'label': 'Mark read',
          'from': ['unread'],
          'to': 'read',
          'guard': {
            'actorEqualsField': {'key': 'recipientFanId'},
          },
        },
      ],
      'instanceDataSchema': {
        'recipientFanId': {
          'type': 'fanId',
          'required': true,
          'writableBy': 'effect',
          'storage': 'inline',
        },
        'title': {
          'type': 'text',
          'required': true,
          'writableBy': 'effect',
          'storage': 'inline',
        },
        'body': {
          'type': 'text',
          'required': true,
          'writableBy': 'effect',
          'storage': 'inline',
        },
        'createdAt': {
          'type': 'text',
          'required': true,
          'writableBy': 'effect',
          'storage': 'inline',
          'sortable': true,
        },
      },
    }, NotificationInboxController.workflowType);

LocalWorkflowEngineApi _engine() => LocalWorkflowEngineApi(
  db: WorkflowDatabase.memory(),
  communityId: 'notification-inbox-controller-test',
)..registerDefinition(_notificationMachine());

Future<String> _createNotification(
  LocalWorkflowEngineApi engine, {
  required String recipientFanId,
  required String title,
}) => engine.createInstance(
  workflowType: NotificationInboxController.workflowType,
  fanId: 'notification-effect',
  initialInstanceData: {
    'recipientFanId': recipientFanId,
    'title': title,
    'body': '$title body',
    'createdAt': '2026-07-31T12:00:00Z',
  },
);

Future<WorkflowInstance> _find(
  LocalWorkflowEngineApi engine,
  String instanceId,
) async => (await engine.queryInstances(
  tabId: 'notification-inbox',
  fanId: _personaA,
  limit: 1000,
)).items.singleWhere((item) => item.instanceId == instanceId);

void main() {
  test(
    'scopes count and live list, and preserves the guarded mark-read transition',
    () async {
      final engine = _engine();
      final controllerA = NotificationInboxController(
        engine: engine,
        fanId: _personaA,
      );
      final controllerB = NotificationInboxController(
        engine: engine,
        fanId: _personaB,
      );

      final aUnreadId = await _createNotification(
        engine,
        recipientFanId: _personaA,
        title: 'A unread',
      );
      final aReadId = await _createNotification(
        engine,
        recipientFanId: _personaA,
        title: 'A read',
      );
      final bUnreadId = await _createNotification(
        engine,
        recipientFanId: _personaB,
        title: 'B unread',
      );

      await controllerA.markRead(await _find(engine, aReadId));

      expect(await controllerA.unreadCount(), 1);

      final source = controllerA.live(tabId: 'notification-inbox-test');
      expect(source.engine, same(engine));
      expect(source.workflowType, NotificationInboxController.workflowType);
      expect(source.fanId, _personaA);
      expect(source.tabId, 'notification-inbox-test');

      final rawPage = await source.engine.queryInstances(
        tabId: source.tabId,
        fanId: source.fanId,
        query: source.query,
        limit: 1000,
      );
      expect(rawPage.items.any((item) => item.instanceId == bUnreadId), isTrue);
      final liveItems = controllerA.filterMine(rawPage.items);
      expect(
        liveItems.map((item) => item.instanceId),
        unorderedEquals([aUnreadId, aReadId]),
      );
      expect(liveItems.any((item) => item.instanceId == bUnreadId), isFalse);

      final scopedPage = await controllerA.queryPage(
        tabId: 'notification-inbox-test',
      );
      expect(
        scopedPage.items.map((item) => item.instanceId),
        unorderedEquals([aUnreadId, aReadId]),
      );
      expect(
        scopedPage.items.any((item) => item.instanceId == bUnreadId),
        isFalse,
      );

      final aUnread = await _find(engine, aUnreadId);
      await expectLater(
        controllerB.markRead(aUnread),
        throwsA(isA<StateError>()),
      );
      expect((await _find(engine, aUnreadId)).currentState, 'unread');

      await controllerA.markRead(aUnread);
      expect((await _find(engine, aUnreadId)).currentState, 'read');
      expect(await controllerA.unreadCount(), 0);
    },
  );
}
