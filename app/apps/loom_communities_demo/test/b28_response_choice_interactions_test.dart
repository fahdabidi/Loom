import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  group('B28 real multi-choice response interactions (Phase 2)', () {
    testWidgets(
      'wf_event-workflow-offers-going-maybe-cant-go-and-records-choice',
      (tester) async {
        final fixture = _writeTabletopClubPackagePair('event');
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(
          tester,
          fixture.package,
          communityId: fixture.communityId,
          fanId: 'tabletop-member',
        );
        await tapCommunityTab(tester, 'calendar');

        const instanceId = 'tabletop-game-night-rsvp';
        expect(
          find.byKey(const ValueKey('engine-native-calendar-root')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('event-rsvp-card-$instanceId')),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey('event-rsvp-$instanceId-action-respond-going'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('event-rsvp-$instanceId-action-respond-maybe'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey('event-rsvp-$instanceId-action-respond-declined'),
          ),
          findsOneWidget,
        );
        // The removed legacy action surface must not reappear beside the real
        // event card and its engine-backed response transitions.
        expect(
          find.byKey(const ValueKey('workflow-response-choice-bar')),
          findsNothing,
        );

        final maybeButton = find.byKey(
          const ValueKey('event-rsvp-$instanceId-action-respond-maybe'),
        );
        await scrollFinderIntoViewport(tester, maybeButton);
        await tester.tap(maybeButton);
        await tester.pumpAndSettle();

        final selectedMaybe = tester.widget<InputChip>(
          find.descendant(of: maybeButton, matching: find.byType(InputChip)),
        );
        expect(selectedMaybe.selected, isTrue);
        expect(selectedMaybe.onPressed, isNull);
      },
    );

    testWidgets('wf_approval-workflow-offers-approve-reject-request-changes', (
      tester,
    ) async {
      final fixture = _writeTabletopClubPackagePair('approval');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(
        tester,
        fixture.package,
        communityId: fixture.communityId,
        fanId: 'tabletop-organizer',
      );
      await tapCommunityTab(tester, 'admin');

      const instanceId = 'tabletop-committee-decision';
      expect(
        find.byKey(const ValueKey('engine-native-list-root-admin')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('generic-instance-card-$instanceId')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey('generic-instance-$instanceId-action-approve'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-$instanceId-action-request-changes'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('generic-instance-$instanceId-action-reject'),
        ),
        findsOneWidget,
      );

      final changesRequestedButton = find.byKey(
        const ValueKey('generic-instance-$instanceId-action-request-changes'),
      );
      await scrollFinderIntoViewport(tester, changesRequestedButton);
      await tester.tap(changesRequestedButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Request changes'), findsOneWidget);
    });

    testWidgets('wf_single-choice-workflow-keeps-plain-confirm-cancel', (
      tester,
    ) async {
      // Regression guard: a non-Event/Approval category (Publishing, via
      // the announcement workflow) must keep today's plain one-button
      // confirm surface, not a branching choice bar.
      final fixture = _writeTabletopClubPackagePair('publishing');
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(
        tester,
        fixture.package,
        communityId: fixture.communityId,
        fanId: 'tabletop-organizer',
      );
      await tapCommunityTab(tester, 'admin');

      const instanceId = 'tabletop-meetup-announcement';
      expect(
        find.byKey(const ValueKey('generic-instance-card-$instanceId')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey('workflow-response-choice-bar')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey(
            'generic-instance-$instanceId-action-publish-announcement',
          ),
        ),
        findsOneWidget,
      );
    });
  });
}

Future<void> _installAndOpen(
  WidgetTester tester,
  EvidencePackagePair fixture, {
  required String communityId,
  required String fanId,
}) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('community-card-$communityId')));
  await tester.pumpAndSettle();
  await selectPersona(tester, fanId);
}

({EvidencePackagePair package, String communityId})
_writeTabletopClubPackagePair(String suffix) {
  final extensionId = '${_extensionId}_$suffix';
  final communityId = 'community_verify_tabletop_club_$suffix';
  final event = engineNativeEventRsvpTestFixture(
    eventWorkflowType: 'tabletop-game-night-rsvp',
    responseWorkflowType: 'tabletop-game-night-rsvp-response',
    eventInstanceId: 'tabletop-game-night-rsvp',
    title: 'RSVP to Friday game night',
    eventDate: '2026-07-10',
    eventTime: '19:00',
    location: 'Community room',
    organizerRoleId: 'tabletop-organizer',
    organizerFanId: 'tabletop-organizer-01',
    memberRoleId: 'tabletop-member',
  );
  final committeeDecision = engineNativeTestWorkflowDefinition(
    initialState: 'pending',
    states: <String, Object?>{
      'pending': <String, Object?>{'label': 'Awaiting decision'},
      'approved': <String, Object?>{'label': 'Approved', 'isTerminal': true},
      'changes-requested': <String, Object?>{
        'label': 'Changes requested',
        'isTerminal': true,
      },
      'rejected': <String, Object?>{'label': 'Rejected', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'approve',
        'label': 'Approve',
        'tone': 'primary',
        'from': <String>['pending'],
        'to': 'approved',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-organizer'],
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'set',
            'key': 'decision',
            'value': 'Approved',
          },
        ],
      },
      <String, Object?>{
        'id': 'request-changes',
        'label': 'Request changes',
        'tone': 'secondary',
        'from': <String>['pending'],
        'to': 'changes-requested',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-organizer'],
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'set',
            'key': 'decision',
            'value': 'Request changes',
          },
        ],
      },
      <String, Object?>{
        'id': 'reject',
        'label': 'Reject',
        'tone': 'destructive',
        'from': <String>['pending'],
        'to': 'rejected',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-organizer'],
        },
        'effects': <Object?>[
          <String, Object?>{
            'op': 'set',
            'key': 'decision',
            'value': 'Rejected',
          },
        ],
      },
    ],
    renderBindings: <Map<String, Object?>>[
      engineNativeTestRenderBinding(
        states: <String>[
          'pending',
          'approved',
          'changes-requested',
          'rejected',
        ],
        tabId: 'admin',
        cardSurfaceFamily: 'approvalQueueItem',
      ),
    ],
    instanceDataSchema: <String, Object?>{
      'title': <String, Object?>{
        'type': 'text',
        'storage': 'inline',
        'labelTemplate': '{value}',
      },
      'decision': <String, Object?>{
        'type': 'text',
        'writableBy': 'effect',
        'storage': 'inline',
        'labelTemplate': 'Decision: {value}',
        'hideWhenEmpty': true,
      },
    },
  );
  final announcement = engineNativeTestWorkflowDefinition(
    initialState: 'draft',
    states: <String, Object?>{
      'draft': <String, Object?>{'label': 'Draft'},
      'published': <String, Object?>{'label': 'Published', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'publish-announcement',
        'label': 'Publish announcement',
        'tone': 'primary',
        'from': <String>['draft'],
        'to': 'published',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>['tabletop-organizer'],
        },
      },
    ],
    renderBindings: <Map<String, Object?>>[
      engineNativeTestRenderBinding(
        states: <String>['draft', 'published'],
        tabId: 'admin',
        cardSurfaceFamily: 'notificationInbox',
      ),
    ],
    instanceDataSchema: <String, Object?>{
      'title': <String, Object?>{'type': 'text', 'storage': 'inline'},
      'body': <String, Object?>{'type': 'textarea', 'storage': 'inline'},
    },
  );

  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b28_tabletop_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: 'Tabletop Club',
    experience: <String, Object?>{
      'displayName': 'Tabletop Club',
      'tagline':
          'Board game nights, loaner games, and dues for local tabletop fans.',
      'accentColor': '#C4703F',
      'roles': [
        {
          'roleId': 'tabletop-organizer',
          'label': 'Organizer',
          'roleLabel': 'Organizer',
          'description':
              'Plans game nights, manages the game library, and decides committee items.',
        },
        {
          'roleId': 'tabletop-member',
          'label': 'Member',
          'roleLabel': 'Member',
          'description': 'RSVPs to game nights and pays dues.',
        },
      ],
      'workflowDefinitions': <String, Object?>{
        ...event.workflowDefinitions,
        'tabletop-committee-decision': committeeDecision,
        'tabletop-meetup-announcement': announcement,
      },
      'workflowInstances': <Object?>[
        ...event.workflowInstances,
        engineNativeTestWorkflowInstance(
          instanceId: 'tabletop-committee-decision',
          workflowType: 'tabletop-committee-decision',
          currentState: 'pending',
          createdByFanId: 'tabletop-member',
          instanceData: <String, Object?>{
            'title': 'Decide on new game purchase',
            'decision': '',
          },
        ),
        engineNativeTestWorkflowInstance(
          instanceId: 'tabletop-meetup-announcement',
          workflowType: 'tabletop-meetup-announcement',
          currentState: 'draft',
          createdByFanId: 'tabletop-organizer',
          instanceData: <String, Object?>{
            'title': 'Friday game night room change',
            'body': 'Friday game night moves to the larger room next week.',
          },
        ),
      ],
    },
    appShell: <String, Object?>{
      'tabs': <Object?>[
        <String, Object?>{
          'tabId': 'calendar',
          'label': 'Calendar',
          'iconKey': 'calendar',
        },
        <String, Object?>{
          'tabId': 'admin',
          'label': 'Admin',
          'iconKey': 'admin',
          'visibleRoleIds': <String>['tabletop-organizer'],
        },
      ],
    },
  );
  return (package: package, communityId: communityId);
}
