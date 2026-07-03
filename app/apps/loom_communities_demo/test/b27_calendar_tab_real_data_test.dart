import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  group('B27 Calendar tab real data (Phase 2 spike)', () {
    testWidgets('wf_calendar-tab-renders-real-package-declared-agenda', (
      tester,
    ) async {
      final fixture = _writeTabletopClubPackagePair();

      await tester.pumpWidget(const LoomCommunitiesDemoApp());
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
      await tester.tap(
        find.byKey(const ValueKey('load-local-community-button')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey('community-card-community_verify_tabletop_club'),
        ),
      );
      await tester.pumpAndSettle();

      await _tapTab(tester, 'calendar');

      expect(
        find.byKey(const ValueKey('calendar-tab-surface')),
        findsOneWidget,
      );
      // Real, package-driven calendar chrome must replace the placeholder
      // week strip that always showed "12-18" regardless of actual dates.
      expect(
        find.byKey(const ValueKey('calendar-agenda-date-strip')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('calendar-week-strip')), findsNothing);
      expect(
        find.byKey(
          const ValueKey(
            'calendar-event-detail-tabletop-game-night-rsvp',
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Jul 10'), findsOneWidget);
      expect(find.textContaining('Community room'), findsOneWidget);
      // Appears twice by design: the capacity fact pill states it as a
      // compact tag, and the workflow tile's body restates it in the full
      // entryText sentence below.
      expect(find.textContaining('12 of 20 seats filled'), findsNWidgets(2));
    });

    testWidgets(
      'wf_calendar-tab-catalog-community-keeps-placeholder-strip',
      (tester) async {
        // Regression guard: a catalog-driven community with no
        // package-declared calendar data must keep today's placeholder
        // rendering rather than showing an empty/broken agenda strip.
        final target = loomEvidenceTargets.firstWhere(
          (target) => target.extensionId == 'ext_camera_club',
        );
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await installEvidenceTarget(tester, target);
        await openEvidenceTarget(tester, target);

        await _tapTab(tester, 'calendar');

        expect(
          find.byKey(const ValueKey('calendar-week-strip')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('calendar-agenda-date-strip')),
          findsNothing,
        );
      },
    );
  });
}

Future<void> _tapTab(WidgetTester tester, String tabId) async {
  final tabFinder = find.byKey(ValueKey('community-tab-$tabId'));
  final tabRail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (
    var attempt = 0;
    attempt < 8 && tabFinder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.drag(tabRail, const Offset(-220, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(tabFinder, findsOneWidget, reason: tabId);
  await tester.tap(tabFinder, warnIfMissed: false);
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
  final tempDir = Directory.systemTemp.createTempSync('loom_b27_tabletop_');
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
            'personaId': 'tabletop-member',
            'label': 'Member',
            'roleLabel': 'Member',
            'description': 'RSVPs to game nights, borrows games, and pays dues.',
          },
          {
            'personaId': 'tabletop-organizer',
            'label': 'Organizer',
            'roleLabel': 'Organizer',
            'description':
                'Plans game nights, manages the game library, and collects dues.',
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
        },
      },
    }),
  );
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}
