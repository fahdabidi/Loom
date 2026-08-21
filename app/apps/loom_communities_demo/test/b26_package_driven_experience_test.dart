import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  group('B26 package-driven experience', () {
    test('wf_package-driven-experience-overrides-fallback', () {
      final fixture = _writeTabletopClubPackagePair();
      final backend = LocalInAppBackend();

      final report = backend.installLocalPackagePairFromFiles(
        extensionPackagePath: fixture.extensionPath,
        initializationPackagePath: fixture.initializationPath,
      );
      final community = report.community;

      expect(community.extensionId, _extensionId);
      expect(
        community.experienceConfiguration,
        isNotEmpty,
        reason:
            'the initialization package experience block must be parsed onto the installed community',
      );

      final experience = experienceForExtensionId(
        community.extensionId,
        displayName: community.displayName,
        specVersion: community.specVersion,
        experienceConfiguration: community.experienceConfiguration,
      );

      // Today, an unknown extensionId with no package experience renders only
      // this single fallback workflow. Package-driven parsing must replace it.
      expect(
        experience.workflows.map((workflow) => workflow.workflowId),
        isNot(contains('local-home-open')),
      );
      expect(experience.workflows, hasLength(4));
      expect(experience.displayName, 'Tabletop Club');
      expect(experience.tagline, contains('game nights'));

      final workflowIds = experience.workflows
          .map((workflow) => workflow.workflowId)
          .toSet();
      expect(
        workflowIds,
        containsAll(<String>[
          'tabletop-game-night-rsvp',
          'tabletop-game-loan',
          'tabletop-club-dues-payment',
          'tabletop-meetup-announcement',
        ]),
      );
    });

    test('wf_package-driven-personas-and-receiver-policy', () {
      final fixture = _writeTabletopClubPackagePair();
      final backend = LocalInAppBackend();
      final community = backend
          .installLocalPackagePairFromFiles(
            extensionPackagePath: fixture.extensionPath,
            initializationPackagePath: fixture.initializationPath,
          )
          .community;

      final experience = experienceForExtensionId(
        community.extensionId,
        displayName: community.displayName,
        specVersion: community.specVersion,
        experienceConfiguration: community.experienceConfiguration,
      );

      final personas = personasForExtensionId(
        community.extensionId,
        experience: experience,
      );
      expect(
        personas.map((persona) => persona.personaId),
        containsAll(<String>['tabletop-organizer', 'tabletop-member']),
      );

      final rsvpPolicy = personaPolicyForWorkflow(
        community.extensionId,
        'tabletop-game-night-rsvp',
        experience: experience,
      );
      expect(rsvpPolicy.actorPersonaIds, ['tabletop-member']);
      expect(rsvpPolicy.receiverPersonaIds, ['tabletop-organizer']);
      expect(
        rsvpPolicy.receiverActionText,
        'Acknowledge RSVP',
      );
    });

    test('wf_package-driven-tabs-are-derived-from-workflows', () {
      final fixture = _writeTabletopClubPackagePair();
      final backend = LocalInAppBackend();
      final community = backend
          .installLocalPackagePairFromFiles(
            extensionPackagePath: fixture.extensionPath,
            initializationPackagePath: fixture.initializationPath,
          )
          .community;

      final experience = experienceForExtensionId(
        community.extensionId,
        displayName: community.displayName,
        specVersion: community.specVersion,
        experienceConfiguration: community.experienceConfiguration,
      );

      // Member persona: no admin-eligible workflow, so no Admin tab.
      final memberTabs = appShellTabsFor(
        experience: experience,
        personaId: 'tabletop-member',
        appShellConfiguration: community.appShellConfiguration,
      );
      final memberTabIds = memberTabs.map((tab) => tab.tabId).toSet();
      expect(
        memberTabIds,
        containsAll(<String>['home', 'calendar', 'marketplace', 'giving', 'messages']),
      );
      expect(memberTabIds, isNot(contains('admin')));

      // Organizer persona is the actor for the announcement workflow, so the
      // Admin tab must appear only for them.
      final organizerTabs = appShellTabsFor(
        experience: experience,
        personaId: 'tabletop-organizer',
        appShellConfiguration: community.appShellConfiguration,
      );
      expect(organizerTabs.map((tab) => tab.tabId), contains('admin'));
    });
  });
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
  final tempDir = Directory.systemTemp.createTempSync('loom_b26_tabletop_');
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
      'specVersion': currentCommunitySpecVersion,
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
        'theme': {
          'accent': '#C4703F',
          'tabThemes': {
            'giving': {'accent': '#8A5A34'},
          },
        },
        'roles': [
          {
            'roleId': 'tabletop-organizer',
            'label': 'Organizer',
            'roleLabel': 'Organizer',
            'description':
                'Plans game nights, manages the game library, and collects dues.',
          },
          {
            'roleId': 'tabletop-member',
            'label': 'Member',
            'roleLabel': 'Member',
            'description': 'RSVPs to game nights, borrows games, and pays dues.',
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
            'calendar': {
              'date': '2026-07-10',
              'time': '19:00',
              'location': 'Community room',
              'capacityLabel': '12 of 20 seats filled',
            },
          },
          {
            'workflowId': 'tabletop-game-loan',
            'title': 'Borrow a game from the club library',
            'entryText': 'Catan is available in the club game library.',
            'actionText': 'Request to borrow Catan for two weeks.',
            'resultText':
                'Your loan request for Catan was sent to the organizer.',
          },
          {
            'workflowId': 'tabletop-club-dues-payment',
            'title': 'Pay quarterly club dues',
            'entryText': 'Quarterly dues of \$15 are due by the end of the month.',
            'actionText': 'Pay \$15 in quarterly dues.',
            'resultText': 'Dues payment recorded and receipt saved.',
            'theme': {'accent': '#8A5A34'},
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
          'tabletop-game-loan': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
            'receiverEntryText':
                'A member requested to borrow Catan from the club library.',
            'receiverActionText': 'Approve loan',
            'receiverResultText':
                'Loan approved and logged in the club library.',
          },
          'tabletop-club-dues-payment': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
            'receiverEntryText': 'A member paid quarterly dues.',
            'receiverActionText': 'Confirm receipt',
            'receiverResultText':
                'Dues payment confirmed and receipt issued.',
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
