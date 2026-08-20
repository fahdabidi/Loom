import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'authz_p6_test_helpers.dart';

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
  required String recipientPersonaId,
  required String title,
  String currentState = 'unread',
}) => {
  'instanceId': instanceId,
  'workflowType': NotificationInboxController.workflowType,
  'currentState': currentState,
  'createdByFanId': 'notification-effect',
  'instanceData': {
    'recipientFanId': recipientPersonaId,
    'title': title,
    'body': '$title body',
    'createdAt': '2026-07-31T12:00:00Z',
  },
};

Map<String, Object?> _experienceConfiguration({
  required List<Map<String, dynamic>> seeds,
  String? notificationStyle,
}) => {
  'roles': [
    {
      'roleId': _personaA,
      'label': 'Member A',
      'roleLabel': 'Member',
      'description': 'Member A notifications',
    },
    {
      'roleId': _personaB,
      'label': 'Member B',
      'roleLabel': 'Member',
      'description': 'Member B notifications',
    },
  ],
  'workflowDefinitions': {
    NotificationInboxController.workflowType: _notificationDefinition(),
  },
  'workflowInstances': seeds,
  if (notificationStyle != null)
    'notificationPresentation': <String, Object?>{'style': notificationStyle},
};

Future<WorkflowEngineApi> _installEngine(
  String extensionId,
  Map<String, Object?> experienceConfiguration,
) async {
  experienceForExtensionId(
    extensionId,
    displayName: 'Engine-native Community',
    specVersion: currentCommunitySpecVersion,
    experienceConfiguration: experienceConfiguration,
  );
  return workflowEngineForExtensionId(extensionId);
}

LocalInstalledCommunity _community({
  required String extensionId,
  required Map<String, Object?> experienceConfiguration,
}) => LocalInstalledCommunity(
  communityId: '$extensionId-community',
  displayName: 'Engine-native Community',
  extensionId: extensionId,
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#246B62',
  specVersion: currentCommunitySpecVersion,
  appShellConfiguration: const {},
  experienceConfiguration: experienceConfiguration,
);

Widget _host(LocalInstalledCommunity community) => MaterialApp(
  home: LocalExtensionScreen(
    community: community,
    seedDataFiles: const [],
    authApi: activeAuthForInstalledCommunity(
      community: community,
      personaTypeId: _personaA,
    ),
  ),
);

Finder _badgeLabel(String label) => find.descendant(
  of: find.byKey(const ValueKey('notification-fab-badge')),
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
      personaId: _personaA,
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

Future<void> _tapMessagesTab(WidgetTester tester) async {
  final tab = find.byKey(const ValueKey('community-tab-messages'));
  await _pumpUntil(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pump();
}

void main() {
  testWidgets(
    'FAB notification style is global, scoped, and marks unread rows read',
    (tester) async {
      const extensionId = 'notification-fab-test';
      final experienceConfiguration = _experienceConfiguration(
        notificationStyle: 'fab',
        seeds: [
          _notificationSeed(
            instanceId: 'a-unread-1',
            recipientPersonaId: _personaA,
            title: 'A unread one',
          ),
          _notificationSeed(
            instanceId: 'a-unread-2',
            recipientPersonaId: _personaA,
            title: 'A unread two',
          ),
          _notificationSeed(
            instanceId: 'a-read',
            recipientPersonaId: _personaA,
            title: 'A already read',
            currentState: 'read',
          ),
          _notificationSeed(
            instanceId: 'b-unread',
            recipientPersonaId: _personaB,
            title: 'B private notification',
          ),
        ],
      );
      final engine = await _installEngine(extensionId, experienceConfiguration);

      await tester.pumpWidget(
        _host(
          _community(
            extensionId: extensionId,
            experienceConfiguration: experienceConfiguration,
          ),
        ),
      );
      await _pumpUntil(tester, _badgeLabel('2'));

      expect(find.byKey(const ValueKey('notification-fab')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('creatable-fab-speed-dial')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('notification-fab')));
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
      expect(find.text('B private notification'), findsNothing);

      final unreadRow = find.byKey(
        const ValueKey('notification-bell-row-a-unread-1'),
      );
      await tester.ensureVisible(unreadRow);
      await tester.pump();
      await tester.tap(unreadRow);
      await _pumpUntilRead(tester, engine, 'a-unread-1');

      final persisted = await engine.queryInstances(
        tabId: 'notification-inbox',
        personaId: _personaA,
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

      await _tapMessagesTab(tester);
      expect(find.byKey(const ValueKey('notification-fab')), findsOneWidget);
    },
  );

  testWidgets('the absent notification style does not render the FAB', (
    tester,
  ) async {
    const extensionId = 'notification-fab-absent-test';
    final experienceConfiguration = _experienceConfiguration(
      seeds: [
        _notificationSeed(
          instanceId: 'absent-unread',
          recipientPersonaId: _personaA,
          title: 'Absent style notification',
        ),
      ],
    );
    await _installEngine(extensionId, experienceConfiguration);

    await tester.pumpWidget(
      _host(
        _community(
          extensionId: extensionId,
          experienceConfiguration: experienceConfiguration,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('notification-fab')), findsNothing);
    expect(
      find.byKey(const ValueKey('notification-bell-button')),
      findsOneWidget,
    );
  });

  testWidgets('the explicit bell notification style does not render the FAB', (
    tester,
  ) async {
    const extensionId = 'notification-fab-bell-test';
    final experienceConfiguration = _experienceConfiguration(
      notificationStyle: 'bell',
      seeds: [
        _notificationSeed(
          instanceId: 'bell-unread',
          recipientPersonaId: _personaA,
          title: 'Bell style notification',
        ),
      ],
    );
    await _installEngine(extensionId, experienceConfiguration);

    await tester.pumpWidget(
      _host(
        _community(
          extensionId: extensionId,
          experienceConfiguration: experienceConfiguration,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('notification-fab')), findsNothing);
    expect(
      find.byKey(const ValueKey('notification-bell-button')),
      findsOneWidget,
    );
  });
}
