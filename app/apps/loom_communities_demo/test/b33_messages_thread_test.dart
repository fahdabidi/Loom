import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_messages';
const _ownerAccountId = 'tabletop-member-morgan';
const _peerAccountId = 'tabletop-member-riley';
const _organizerAccountId = 'tabletop-organizer-mara';
var _fixtureSequence = 0;

const _accounts = <LoomAccount>[
  LoomAccount(
    accountId: _ownerAccountId,
    displayName: 'Morgan Member',
    personaTypeId: 'tabletop-member',
  ),
  LoomAccount(
    accountId: _peerAccountId,
    displayName: 'Riley Member',
    personaTypeId: 'tabletop-member',
  ),
  LoomAccount(
    accountId: _organizerAccountId,
    displayName: 'Mara Organizer',
    personaTypeId: 'tabletop-organizer',
  ),
];

void main() {
  group('B33 Messages thread test', () {
    testWidgets('wf_messages-inbox-lists-seeded-threads', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Morgan Member');
      await _openMessages(tester, expectedInstanceId: 'thread-welcome');

      expect(_threadCard('thread-welcome'), findsOneWidget);
      expect(_threadCard('thread-game-suggestions'), findsOneWidget);
      expect(find.text('Welcome to Tabletop Club'), findsWidgets);
      expect(find.text('Game suggestions for Friday'), findsWidgets);
      expect(find.text('Glad to be here.'), findsOneWidget);
      expect(find.text('Any requests?'), findsOneWidget);

      // `discussionThread` is participant-scoped by individual account id.
      // A second account with the same role must not inherit Morgan's threads.
      await signInEvidenceAccount(tester, 'Riley Member');
      await openEvidenceTarget(tester, fixture.target);
      await tapCommunityTab(tester, 'messages');
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-empty-messages')),
        description: 'participant-private empty Messages state',
      );
      expect(_threadCard('thread-welcome'), findsNothing);
      expect(
        find.byKey(const ValueKey('engine-native-list-error-messages')),
        findsNothing,
      );

      // The data-absence direction remains distinct from privacy filtering.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
      final bareFixture = _writeTabletopClubPackagePair(includeThreads: false);
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, bareFixture, 'Morgan Member');
      await tapCommunityTab(tester, 'messages');
      await waitForEngineNativeWidget(
        tester,
        find.byKey(const ValueKey('engine-native-list-empty-messages')),
        description: 'Messages empty state without open thread instances',
      );
      expect(_threadCard('thread-welcome'), findsNothing);
    });

    testWidgets('wf_messages-open-thread-and-send-reply', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Morgan Member');
      await _openMessages(tester, expectedInstanceId: 'thread-welcome');

      expect(
        find.byKey(
          const ValueKey('generic-instance-list-field-thread-welcome-messages'),
        ),
        findsOneWidget,
      );
      expect(find.text('Welcome everyone!'), findsOneWidget);
      expect(find.text('Glad to be here.'), findsOneWidget);

      final post = _threadAction('thread-welcome', 'post-message');
      await waitForEngineNativeWidget(
        tester,
        post,
        description: 'Post message transition',
      );
      await _tapVisible(tester, post);
      expect(
        find.byKey(const ValueKey('generic-transition-input-dialog')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('generic-transition-input-body')),
        'Test reply from member',
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('generic-transition-input-confirm')),
      );
      await waitForEngineNativeWidget(
        tester,
        find.text('Test reply from member'),
        description: 'new reply in the structured message list',
      );
      expect(find.text('Test reply from member'), findsOneWidget);
    });

    testWidgets('wf_messages-mute-and-archive-toggle', (tester) async {
      final fixture = _writeTabletopClubPackagePair();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndSignIn(tester, fixture, 'Morgan Member');
      await _openMessages(tester, expectedInstanceId: 'thread-welcome');

      expect(_threadCard('thread-welcome'), findsOneWidget);
      expect(_threadCard('thread-game-suggestions'), findsOneWidget);

      final mutedEditor = find.byKey(
        const ValueKey('generic-instance-editor-thread-welcome-muted'),
      );
      await _tapVisible(tester, mutedEditor);
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('generic-instance-save-thread-welcome')),
      );

      final engine = await workflowEngineForExtensionId(
        fixture.target.extensionId,
      );
      final afterMute = await engine.queryInstances(
        tabId: 'messages',
        personaId: _ownerAccountId,
        limit: 10,
      );
      expect(
        afterMute.items
            .singleWhere((item) => item.instanceId == 'thread-welcome')
            .instanceData['muted'],
        isTrue,
      );
      expect(_threadCard('thread-welcome'), findsOneWidget);

      final archive = _threadAction(
        'thread-game-suggestions',
        'archive-thread',
      );
      await waitForEngineNativeWidget(
        tester,
        archive,
        description: 'Archive thread transition',
      );
      await _tapVisible(tester, archive);
      await _waitForNothing(tester, _threadCard('thread-game-suggestions'));

      expect(_threadCard('thread-welcome'), findsOneWidget);
      expect(_threadCard('thread-game-suggestions'), findsNothing);
    });
  });
}

Finder _threadCard(String instanceId) =>
    find.byKey(ValueKey('generic-instance-card-$instanceId'));

Finder _threadAction(String instanceId, String transitionId) =>
    find.byKey(ValueKey('generic-instance-$instanceId-action-$transitionId'));

Future<void> _openMessages(
  WidgetTester tester, {
  required String expectedInstanceId,
}) async {
  await tapCommunityTab(tester, 'messages');
  await waitForEngineNativeWidget(
    tester,
    _threadCard(expectedInstanceId),
    description: 'discussion thread $expectedInstanceId',
  );
}

Future<void> _installAndSignIn(
  WidgetTester tester,
  ({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
  fixture,
  String displayName,
) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.package.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.package.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(ValueKey('community-card-${fixture.communityId}')),
  );
  await tester.pumpAndSettle();
  await seedEvidenceAccounts(tester, fixture.target, _accounts);
  await signInEvidenceAccount(tester, displayName);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _waitForNothing(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt += 1) {
    if (finder.evaluate().isEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for $finder to disappear.');
}

({EvidencePackagePair package, String communityId, LoomEvidenceTarget target})
_writeTabletopClubPackagePair({bool includeThreads = true}) {
  final sequence = _fixtureSequence++;
  final extensionId = '${_extensionId}_$sequence';
  final communityId = 'community_verify_tabletop_messages_$sequence';
  final definition = engineNativeTestWorkflowDefinition(
    initialState: 'open',
    visibility: <String, Object?>{
      'default': 'guarded',
      'readGuard': <String, Object?>{
        'actorInList': <String, Object?>{
          'key': 'participantFanIds',
          'present': true,
        },
      },
      'fields': <String, Object?>{
        'participants': <String>['participantFanIds'],
      },
    },
    states: <String, Object?>{
      'open': <String, Object?>{
        'label': 'Open',
        'editableFields': <String>['muted'],
        'editGuard': <String, Object?>{
          'actorInList': <String, Object?>{
            'key': 'participantFanIds',
            'present': true,
          },
        },
      },
      'archived': <String, Object?>{'label': 'Archived', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'post-message',
        'label': 'Post message',
        'tone': 'primary',
        'from': <String>['open'],
        'to': null,
        'guard': <String, Object?>{
          'actorInList': <String, Object?>{
            'key': 'participantFanIds',
            'present': true,
          },
        },
        'inputs': <String, Object?>{
          'body': <String, Object?>{'type': 'text', 'required': true},
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'append',
            'key': 'messages',
            'value': <String, Object?>{
              'senderFanId': r'$actor',
              'body': '{input.body}',
              'timestamp': r'$timestamp',
            },
          },
        ],
      },
      <String, Object?>{
        'id': 'archive-thread',
        'label': 'Archive',
        'tone': 'destructive',
        'from': <String>['open'],
        'to': 'archived',
        'guard': <String, Object?>{
          'actorInList': <String, Object?>{
            'key': 'participantFanIds',
            'present': true,
          },
        },
      },
    ],
    renderBindings: <Map<String, Object?>>[
      engineNativeTestRenderBinding(
        states: <String>['open'],
        tabId: 'messages',
        cardSurfaceFamily: 'discussionThread',
      ),
    ],
    instanceDataSchema: <String, Object?>{
      'subject': <String, Object?>{
        'type': 'text',
        'required': true,
        'labelTemplate': '{value}',
        'displayContexts': <String>['tile', 'detail'],
      },
      'threadOwnerFanId': <String, Object?>{
        'type': 'fanId',
        'required': true,
        'displayContexts': <String>['detail'],
      },
      'participantFanIds': <String, Object?>{
        'type': 'fanId[]',
        'required': true,
        'displayContexts': <String>['detail'],
      },
      'messages': <String, Object?>{
        'type': 'list',
        'writableBy': 'effect',
        'displayContexts': <String>['detail'],
      },
      'muted': <String, Object?>{
        'type': 'bool',
        'writableBy': 'formEntry',
        'labelTemplate': 'Muted: {value}',
        'displayContexts': <String>['detail'],
      },
    },
  );

  final instances = includeThreads
      ? <Object?>[
          engineNativeTestWorkflowInstance(
            instanceId: 'thread-welcome',
            workflowType: 'discussion-thread',
            currentState: 'open',
            createdByFanId: _organizerAccountId,
            instanceData: <String, Object?>{
              'subject': 'Welcome to Tabletop Club',
              'threadOwnerFanId': _organizerAccountId,
              'participantFanIds': <String>[
                _ownerAccountId,
                _organizerAccountId,
              ],
              'messages': <Object?>[
                <String, Object?>{
                  'senderFanId': _organizerAccountId,
                  'body': 'Welcome everyone!',
                  'timestamp': '2026-07-03T10:00:00Z',
                },
                <String, Object?>{
                  'senderFanId': _ownerAccountId,
                  'body': 'Glad to be here.',
                  'timestamp': '2026-07-03T10:05:00Z',
                },
              ],
              'muted': false,
            },
          ),
          engineNativeTestWorkflowInstance(
            instanceId: 'thread-game-suggestions',
            workflowType: 'discussion-thread',
            currentState: 'open',
            createdByFanId: _ownerAccountId,
            instanceData: <String, Object?>{
              'subject': 'Game suggestions for Friday',
              'threadOwnerFanId': _ownerAccountId,
              'participantFanIds': <String>[
                _ownerAccountId,
                _organizerAccountId,
              ],
              'messages': <Object?>[
                <String, Object?>{
                  'senderFanId': _organizerAccountId,
                  'body': 'Any requests?',
                  'timestamp': '2026-07-03T11:00:00Z',
                },
              ],
              'muted': false,
            },
          ),
        ]
      : <Object?>[
          engineNativeTestWorkflowInstance(
            instanceId: 'thread-empty-sentinel',
            workflowType: 'discussion-thread',
            currentState: 'archived',
            createdByFanId: _ownerAccountId,
            instanceData: <String, Object?>{
              'subject': 'Archived sentinel',
              'threadOwnerFanId': _ownerAccountId,
              'participantFanIds': <String>[_ownerAccountId],
              'messages': <Object?>[],
              'muted': false,
            },
          ),
        ];

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b33_tabletop_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Tabletop Club',
    experience: <String, Object?>{
      'displayName': 'Tabletop Club',
      'tagline': 'Board game nights and private member conversations.',
      'accentColor': '#C4703F',
      'theme': <String, Object?>{'accent': '#C4703F'},
      'roles': const <Object?>[
        <String, Object?>{
          'roleId': 'tabletop-member',
          'label': 'Member',
          'roleLabel': 'Member',
          'description': 'Participates in club conversations.',
        },
        <String, Object?>{
          'roleId': 'tabletop-organizer',
          'label': 'Organizer',
          'roleLabel': 'Organizer',
          'description': 'Organizes club conversations.',
        },
      ],
      'workflowDefinitions': <String, Object?>{'discussion-thread': definition},
      'workflowInstances': instances,
    },
  );
  return (
    package: package,
    communityId: communityId,
    target: LoomEvidenceTarget(
      phase: 'test',
      communityId: communityId,
      communityName: 'Tabletop Club',
      handle: 'tabletop-messages-$sequence',
      extensionId: extensionId,
      accentColor: '#C4703F',
      seedDataFiles: const <String>[
        'seed/community.json',
        'seed/workflows.json',
      ],
    ),
  );
}
