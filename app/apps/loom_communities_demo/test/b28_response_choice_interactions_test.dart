import 'dart:convert';
import 'dart:io';

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
        final fixture = _writeTabletopClubPackagePair();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);
        await selectPersona(tester, 'tabletop-member');

        const workflow = LoomWorkflowDefinition(
          workflowId: 'tabletop-game-night-rsvp',
          title: '',
          entryText: '',
          actionText: '',
          resultText: '',
        );
        await scrollToWorkflowCard(tester, workflow);
        final workflowButton = find.byKey(
          ValueKey('workflow-button-${workflow.workflowId}'),
        );
        await scrollFinderIntoViewport(tester, workflowButton);
        await tester.tap(workflowButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('workflow-response-going')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('workflow-response-maybe')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('workflow-response-not-going')),
          findsOneWidget,
        );
        // The old binary confirm/cancel bar must not also be present.
        expect(
          find.byKey(ValueKey('workflow-action-submit-${workflow.workflowId}')),
          findsNothing,
        );

        final maybeButton = find.byKey(
          const ValueKey('workflow-response-maybe'),
        );
        await scrollFinderIntoViewport(tester, maybeButton);
        await tester.tap(maybeButton);
        await tester.pumpAndSettle();

        // The action surface auto-focuses the Event's home tab (Calendar);
        // return to Home, which always lists every workflow, before
        // re-scrolling to the card.
        await tester.tap(find.byKey(const ValueKey('community-tab-home')));
        await tester.pumpAndSettle();
        await scrollToWorkflowCard(tester, workflow);
        expect(
          find.byKey(ValueKey('workflow-complete-${workflow.workflowId}')),
          findsOneWidget,
        );
        expect(find.textContaining('You responded: Maybe'), findsOneWidget);
      },
    );

    testWidgets(
      'wf_approval-workflow-offers-approve-reject-request-changes',
      (tester) async {
        final fixture = _writeTabletopClubPackagePair();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);
        // Organizer is the default active persona and the actor for the
        // committee-decision workflow.

        const workflow = LoomWorkflowDefinition(
          workflowId: 'tabletop-committee-decision',
          title: '',
          entryText: '',
          actionText: '',
          resultText: '',
        );
        await scrollToWorkflowCard(tester, workflow);
        final workflowButton = find.byKey(
          ValueKey('workflow-button-${workflow.workflowId}'),
        );
        await scrollFinderIntoViewport(tester, workflowButton);
        await tester.tap(workflowButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('workflow-response-approved')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('workflow-response-changes-requested')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('workflow-response-rejected')),
          findsOneWidget,
        );

        final changesRequestedButton = find.byKey(
          const ValueKey('workflow-response-changes-requested'),
        );
        await scrollFinderIntoViewport(tester, changesRequestedButton);
        await tester.tap(changesRequestedButton);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('community-tab-home')));
        await tester.pumpAndSettle();
        await scrollToWorkflowCard(tester, workflow);
        expect(
          find.textContaining('You responded: Request changes'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'wf_single-choice-workflow-keeps-plain-confirm-cancel',
      (tester) async {
        // Regression guard: a non-Event/Approval category (Publishing, via
        // the announcement workflow) must keep today's plain one-button
        // confirm surface, not a branching choice bar.
        final fixture = _writeTabletopClubPackagePair();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);

        const workflow = LoomWorkflowDefinition(
          workflowId: 'tabletop-meetup-announcement',
          title: '',
          entryText: '',
          actionText: '',
          resultText: '',
        );
        await scrollToWorkflowCard(tester, workflow);
        final workflowButton = find.byKey(
          ValueKey('workflow-button-${workflow.workflowId}'),
        );
        await scrollFinderIntoViewport(tester, workflowButton);
        await tester.tap(workflowButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('workflow-response-choice-bar')),
          findsNothing,
        );
        expect(
          find.byKey(ValueKey('workflow-action-submit-${workflow.workflowId}')),
          findsOneWidget,
        );
      },
    );
  });
}

Future<void> _installAndOpen(
  WidgetTester tester,
  _PackagePairFixture fixture,
) async {
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
  await tester.tap(
    find.byKey(
      const ValueKey('community-card-community_verify_tabletop_club'),
    ),
  );
  await tester.pumpAndSettle();
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}

_PackagePairFixture _writeTabletopClubPackagePair() {
  final tempDir = Directory.systemTemp.createTempSync('loom_b28_tabletop_');
  final extensionFile = File(
    '${tempDir.path}/$_extensionId.loom-extension.zip',
  );
  final initializationFile = File(
    '${tempDir.path}/$_extensionId.loom-init.zip',
  );
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': _extensionId,
      'displayName': 'Tabletop Club',
      'version': '1.0.0',
      'permissions': ['content.publish', 'events.write', 'forms.write'],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'communityId': 'community_verify_tabletop_club',
      'communityName': 'Tabletop Club',
      'extensionId': _extensionId,
      'seedDataFiles': ['seed/community.json', 'seed/workflows.json'],
      'branding': {'accentColor': '#C4703F'},
      'experience': {
        'displayName': 'Tabletop Club',
        'tagline':
            'Board game nights, loaner games, and dues for local tabletop fans.',
        'accentColor': '#C4703F',
        'personas': [
          {
            'personaId': 'tabletop-organizer',
            'label': 'Organizer',
            'roleLabel': 'Organizer',
            'description':
                'Plans game nights, manages the game library, and decides committee items.',
          },
          {
            'personaId': 'tabletop-member',
            'label': 'Member',
            'roleLabel': 'Member',
            'description': 'RSVPs to game nights and pays dues.',
          },
        ],
        'workflows': [
          {
            'workflowId': 'tabletop-game-night-rsvp',
            'title': 'RSVP to Friday game night',
            'entryText':
                'Friday game night at the community room, 7-10pm. 12 of 20 seats filled.',
            'actionText': "Reserve a seat at Friday's game night.",
            'resultText': "You're on the roster for Friday's game night.",
            'responseChoices': [
              {'responseId': 'going', 'label': 'Going'},
              {'responseId': 'maybe', 'label': 'Maybe'},
              {
                'responseId': 'not-going',
                'label': "Can't go",
                'isDestructive': true,
              },
            ],
          },
          {
            'workflowId': 'tabletop-committee-decision',
            'title': 'Decide on new game purchase',
            'entryText':
                'A member proposed buying a copy of Wingspan for the club library.',
            'actionText': 'Decide on the Wingspan purchase proposal.',
            'resultText': 'Decision recorded for the Wingspan proposal.',
            'responseChoices': [
              {'responseId': 'approved', 'label': 'Approve'},
              {
                'responseId': 'changes-requested',
                'label': 'Request changes',
              },
              {
                'responseId': 'rejected',
                'label': 'Reject',
                'isDestructive': true,
              },
            ],
          },
          {
            'workflowId': 'tabletop-meetup-announcement',
            'title': 'Publish game night announcement',
            'entryText':
                "Draft: 'Friday game night moves to the larger room starting next week.'",
            'actionText':
                'Publish the game night announcement to all members.',
            'resultText':
                'Announcement published to all Tabletop Club members.',
          },
        ],
        'personaPolicies': {
          'tabletop-game-night-rsvp': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
            'receiverEntryText': "A member RSVP'd to Friday's game night.",
            'receiverActionText': 'Acknowledge RSVP',
            'receiverResultText':
                'RSVP acknowledged and added to the roster.',
          },
          'tabletop-committee-decision': {
            'actorPersonaIds': ['tabletop-organizer'],
            'receiverPersonaIds': ['tabletop-member'],
            'receiverEntryText':
                'The committee decided on the Wingspan purchase proposal.',
            'receiverActionText': 'View decision',
            'receiverResultText': 'Decision visible to members.',
          },
          'tabletop-meetup-announcement': {
            'actorPersonaIds': ['tabletop-organizer'],
            'receiverPersonaIds': ['tabletop-member'],
            'receiverEntryText':
                'The organizer published a new game night announcement.',
            'receiverActionText': 'Mark as read',
            'receiverResultText': 'Announcement marked as read.',
          },
        },
      },
    }),
  );
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}
