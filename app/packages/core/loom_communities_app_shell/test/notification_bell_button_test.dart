import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _personaA = 'persona-a';
const _personaB = 'persona-b';

Map<String, dynamic> _notificationDefinition() => {
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
};

Map<String, dynamic> _notificationSeed({
  required String instanceId,
  required String recipientFanId,
  required String title,
  String currentState = 'unread',
}) => {
  'instanceId': instanceId,
  'workflowType': NotificationInboxController.workflowType,
  'currentState': currentState,
  'createdByFanId': 'notification-effect',
  'instanceData': {
    'recipientFanId': recipientFanId,
    'title': title,
    'body': '$title body',
    'createdAt': '2026-07-31T12:00:00Z',
  },
};

Future<WorkflowEngineApi> _installEngine(
  String extensionId,
  List<Map<String, dynamic>> seeds,
) async {
  experienceForExtensionId(
    extensionId,
    specVersion: currentCommunitySpecVersion,
    experienceConfiguration: {
      'workflowDefinitions': {
        NotificationInboxController.workflowType: _notificationDefinition(),
      },
      'workflowInstances': seeds,
    },
  );
  return workflowEngineForExtensionId(extensionId);
}

Widget _host({required String extensionId, required String fanId}) =>
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            NotificationBellButton(extensionId: extensionId, fanId: fanId),
          ],
        ),
      ),
    );

Finder _badgeLabel(String label) => find.descendant(
  of: find.byKey(const ValueKey('notification-bell-badge')),
  matching: find.text(label),
);

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for $finder');
}

Future<void> _pumpUntilRead(
  WidgetTester tester,
  WorkflowEngineApi engine,
  String instanceId,
) async {
  for (var attempt = 0; attempt < 40; attempt += 1) {
    final page = await engine.queryInstances(
      tabId: 'notification-inbox',
      fanId: _personaA,
      limit: 1000,
    );
    final item = page.items.singleWhere(
      (item) => item.instanceId == instanceId,
    );
    if (item.currentState == 'read') return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for notification $instanceId to become read');
}

void main() {
  testWidgets(
    'bell badge and sheet are scoped to the active persona and mark rows read',
    (tester) async {
      const extensionId = 'notification-bell-button-test';
      final engine = await _installEngine(extensionId, [
        _notificationSeed(
          instanceId: 'a-unread-1',
          recipientFanId: _personaA,
          title: 'A unread one',
        ),
        _notificationSeed(
          instanceId: 'a-unread-2',
          recipientFanId: _personaA,
          title: 'A unread two',
        ),
        _notificationSeed(
          instanceId: 'a-read',
          recipientFanId: _personaA,
          title: 'A already read',
          currentState: 'read',
        ),
        _notificationSeed(
          instanceId: 'b-unread',
          recipientFanId: _personaB,
          title: 'B private notification',
        ),
      ]);

      await tester.pumpWidget(
        _host(extensionId: extensionId, fanId: _personaA),
      );
      await _pumpUntil(tester, _badgeLabel('2'));

      await tester.tap(find.byKey(const ValueKey('notification-bell-button')));
      await tester.pump(const Duration(milliseconds: 300));
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('notification-bell-row-a-unread-1')),
      );

      expect(
        find.byKey(const ValueKey('notification-bell-row-a-unread-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-bell-row-a-unread-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-bell-row-a-read')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('notification-bell-row-b-unread')),
        findsNothing,
      );
      expect(find.text('A unread one'), findsOneWidget);
      expect(find.text('A unread two'), findsOneWidget);
      expect(find.text('A already read'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('notification-bell-row-a-unread-1')),
      );
      await _pumpUntilRead(tester, engine, 'a-unread-1');
      final persisted = await engine.queryInstances(
        tabId: 'notification-inbox',
        fanId: _personaA,
        limit: 1000,
      );
      expect(
        persisted.items
            .singleWhere((item) => item.instanceId == 'a-unread-1')
            .currentState,
        'read',
      );

      await tester.tap(find.byKey(const ValueKey('notification-sheet-close')));
      await tester.pump(const Duration(milliseconds: 300));
      await _pumpUntil(tester, _badgeLabel('1'));
    },
  );

  testWidgets('bell badge label is hidden when there are no unread rows', (
    tester,
  ) async {
    const extensionId = 'notification-bell-button-empty-test';
    await _installEngine(extensionId, const []);

    await tester.pumpWidget(_host(extensionId: extensionId, fanId: _personaA));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey('notification-bell-button')),
      findsOneWidget,
    );
    expect(_badgeLabel('0'), findsNothing);
    expect(find.text('0'), findsNothing);
  });
}
