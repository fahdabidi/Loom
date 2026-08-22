import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'authz_p6_test_helpers.dart';

const _memberId = 'tabletop-member';

LocalInstalledCommunity _community({
  required String extensionId,
  required List<Map<String, Object?>> threads,
}) => LocalInstalledCommunity(
  communityId: '$extensionId-community',
  displayName: 'Tabletop Club',
  extensionId: extensionId,
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  specVersion: currentCommunitySpecVersion,
  experienceConfiguration: {
    'workflowDefinitions': {
      'tabletop-discussion': {
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
          'archived': {'label': 'Archived', 'isTerminal': true},
        },
        'transitions': [
          {
            'id': 'post-message',
            'label': 'Post message',
            'from': ['open'],
            'to': null,
            'guard': {
              'allowedRoleIds': [_memberId],
            },
            'inputs': {
              'body': {'type': 'text', 'required': true},
            },
            'effects': [
              {
                'op': 'append',
                'key': 'messages',
                'value': {
                  'messageId': r'$timestamp-$actor',
                  'senderFanId': r'$actor',
                  'body': '{input.body}',
                  'timestamp': r'$timestamp',
                },
              },
            ],
          },
          {
            'id': 'archive',
            'label': 'Archive',
            'tone': 'destructive',
            'from': ['open'],
            'to': 'archived',
            'guard': {
              'allowedRoleIds': [_memberId],
            },
          },
        ],
        'renderBindings': [
          {
            'states': ['open'],
            'audience': 'any',
            'tabId': 'messages',
            'cardSurfaceFamily': 'discussionThread',
            'bindingKind': 'primary',
          },
        ],
        'instanceDataSchema': {
          'threadId': {'type': 'text', 'required': true},
          'subject': {
            'type': 'text',
            'required': true,
            'searchable': true,
            'sortable': true,
            'labelTemplate': '{value}',
          },
          'participantFanIds': {'type': 'fanId[]', 'required': true},
          'messages': {'type': 'list', 'writableBy': 'effect'},
          'messageCount': {'type': 'number', 'formula': 'size(messages)'},
        },
      },
    },
    'workflowInstances': [
      for (final thread in threads)
        {
          'instanceId': thread['threadId'],
          'workflowType': 'tabletop-discussion',
          'currentState': 'open',
          'createdByFanId': 'tabletop-organizer',
          'instanceData': {
            'threadId': thread['threadId'],
            'subject': thread['subject'],
            'participantFanIds': thread['participantFanIds'],
            'messages': thread['messages'],
          },
        },
    ],
    'roles': [
      {
        'roleId': _memberId,
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'Tabletop Club member',
      },
    ],
  },
);

const _communityWithoutWorkflowDefinitions = LocalInstalledCommunity(
  communityId: 'v3-messages-no-workflows-community',
  displayName: 'No-workflow Community',
  extensionId: 'v3-messages-no-workflows',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  specVersion: currentCommunitySpecVersion,
);

Map<String, Object?> _thread(String id, String subject) => {
  'threadId': id,
  'subject': subject,
  'participantFanIds': [_memberId],
  'messages': [
    {
      'messageId': '$id-message',
      'senderFanId': 'tabletop-organizer',
      'body': 'Seeded message for $subject',
      'timestamp': '2026-07-10T18:00:00Z',
    },
  ],
};

Widget _host(LocalInstalledCommunity community, LoomAuthApi authApi) =>
    MaterialApp(
      home: LocalExtensionScreen(
        community: community,
        seedDataFiles: const [],
        authApi: authApi,
      ),
    );

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Finder _messageListItems() => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('engine-native-list-item-messages-');
});

Future<void> _openMessages(WidgetTester tester, Finder readyFinder) async {
  final tab = find.byKey(const ValueKey('community-tab-messages'));
  await _pumpUntilFound(tester, tab);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pump();
  await _pumpUntilFound(tester, readyFinder);
  await tester.ensureVisible(readyFinder);
  await tester.pump();
  // The finder can exist before the tab fade's IgnorePointer is removed.
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

void main() {
  testWidgets(
    'default Messages tab is stable when workflowDefinitions are absent',
    (tester) async {
      final auth = activeAuthForInstalledCommunity(
        community: _communityWithoutWorkflowDefinitions,
        roleId: 'local-member',
        accounts: const [
          LoomAccount(
            accountId: 'no-workflow-member',
            displayName: 'No-workflow Member',
            roleId: 'local-member',
          ),
        ],
      );
      await tester.pumpWidget(
        _host(_communityWithoutWorkflowDefinitions, auth),
      );

      final emptyState = find.byKey(
        const ValueKey('engine-native-list-empty-messages'),
      );
      await _openMessages(tester, emptyState);
      await tester.pump();

      expect(emptyState, findsOneWidget);
      expect(
        find.byKey(const ValueKey('engine-native-list-error-messages')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Messages repeater renders the live seeded thread cardinality', (
    tester,
  ) async {
    final first = _community(
      extensionId: 'v3-messages-cardinality-three',
      threads: [
        _thread('one', 'Thread one'),
        _thread('two', 'Thread two'),
        _thread('three', 'Thread three'),
      ],
    );
    final firstAuth = activeAuthForInstalledCommunity(
      community: first,
      roleId: _memberId,
    );
    await tester.pumpWidget(_host(first, firstAuth));
    await selectTestTabletopPersona(tester, _memberId);
    await _openMessages(
      tester,
      find.byKey(const ValueKey('engine-native-list-item-messages-one-0')),
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-one')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-two')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-three')),
      findsOneWidget,
    );
    expect(_messageListItems(), findsNWidgets(3));

    await tester.pumpWidget(const SizedBox.shrink());
    final second = _community(
      extensionId: 'v3-messages-cardinality-four',
      threads: [
        _thread('one', 'Thread one'),
        _thread('two', 'Thread two'),
        _thread('three', 'Thread three'),
        _thread('four', 'Thread four'),
      ],
    );
    final secondAuth = activeAuthForInstalledCommunity(
      community: second,
      roleId: _memberId,
    );
    await tester.pumpWidget(_host(second, secondAuth));
    await selectTestTabletopPersona(tester, _memberId);
    await _openMessages(
      tester,
      find.byKey(const ValueKey('engine-native-list-item-messages-one-0')),
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-four')),
      findsOneWidget,
    );
    expect(_messageListItems(), findsNWidgets(4));
  });

  testWidgets('posted message survives full Messages widget reconstruction', (
    tester,
  ) async {
    final community = _community(
      extensionId: 'v3-messages-post-persistence',
      threads: [_thread('persist', 'Persistence thread')],
    );
    final auth = activeAuthForInstalledCommunity(
      community: community,
      roleId: _memberId,
    );
    await tester.pumpWidget(_host(community, auth));
    await selectTestTabletopPersona(tester, _memberId);
    final threadItem = find.text('Persistence thread');
    await _openMessages(tester, threadItem);
    await _tapVisible(
      tester,
      find.byKey(
        const ValueKey('generic-instance-persist-action-post-message'),
      ),
    );
    final messageInput = find.byKey(
      const ValueKey('generic-transition-input-body'),
    );
    await _pumpUntilFound(tester, messageInput);
    await tester.enterText(
      messageInput,
      'This reply must survive reconstruction.',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('generic-transition-input-confirm')),
    );
    await _pumpUntilFound(
      tester,
      find.text('This reply must survive reconstruction.'),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('This reply must survive reconstruction.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_host(community, auth));
    await selectTestTabletopPersona(tester, _memberId);
    await _openMessages(tester, threadItem);
    expect(
      find.text('This reply must survive reconstruction.'),
      findsOneWidget,
    );
  });

  testWidgets('archived thread survives full Messages widget reconstruction', (
    tester,
  ) async {
    final community = _community(
      extensionId: 'v3-messages-archive-persistence',
      threads: [_thread('archive', 'Archive persistence thread')],
    );
    final auth = activeAuthForInstalledCommunity(
      community: community,
      roleId: _memberId,
    );
    await tester.pumpWidget(_host(community, auth));
    await selectTestTabletopPersona(tester, _memberId);
    final threadItem = find.text('Archive persistence thread');
    await _openMessages(tester, threadItem);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('generic-instance-archive-action-archive')),
    );
    await _pumpUntilAbsent(tester, find.text('Archive persistence thread'));
    expect(find.text('Archive persistence thread'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_host(community, auth));
    await selectTestTabletopPersona(tester, _memberId);
    await _openMessages(
      tester,
      find.byKey(const ValueKey('engine-native-list-empty-messages')),
    );
    expect(find.text('Archive persistence thread'), findsNothing);
  });
}
