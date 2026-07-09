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
      // Date-group header ("Jul 10") + fact pill ("Jul 10, 7:00 PM")
      expect(find.textContaining('Jul 10'), findsAtLeast(1));
      expect(find.textContaining('Community room'), findsOneWidget);
      // Appears twice by design: the capacity fact pill states it as a
      // compact tag, and the workflow tile's body restates it in the full
      // entryText sentence below.
      expect(find.textContaining('12 of 20 seats filled'), findsNWidgets(2));
    });

    testWidgets(
      'wf_calendar-tab-dedupes-date-strip-chips-and-uses-semantic-icons',
      (tester) async {
        // Regression: two workflows on same date must produce ONE chip
        // (not two), and event detail fact pills must use semantic icons.
        final fixture = _writeTabletopClubTwoSameDayFixture();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);
        await _tapTab(tester, 'calendar');

        // Date strip is present
        expect(
          find.byKey(const ValueKey('calendar-agenda-date-strip')),
          findsOneWidget,
        );

        // Two dated workflows share 2026-07-10 → exactly 1 date-group header
        // in the vertical agenda list below the strip.
        expect(
          find.byKey(
            const ValueKey('calendar-agenda-date-group-2026-07-10'),
          ),
          findsOneWidget,
        );

        // Regression proof for the horizontal quick-jump STRIP itself (the
        // actual reported bug): its chips are keyed per-workflow
        // (calendar-agenda-date-<workflowId>), not per-date, so a naive
        // implementation renders one chip per workflow even when they share
        // a date. Only one of the two same-date workflows' chips should
        // survive the strip's dedup-by-date logic.
        final gameNightChip = find.byKey(
          const ValueKey('calendar-agenda-date-tabletop-game-night-rsvp'),
        );
        final tournamentChip = find.byKey(
          const ValueKey('calendar-agenda-date-tabletop-tournament-rsvp'),
        );
        expect(
          gameNightChip.evaluate().length + tournamentChip.evaluate().length,
          1,
          reason:
              'the date strip must render exactly ONE chip for the two '
              'same-date events, not one per workflow',
        );

        // Default event detail shows semantic fact-pill icons (M4 fix)
        // schedule, location, capacity — NOT a generic check_circle_outline
        final detail = find.byKey(
          const ValueKey('calendar-event-detail-tabletop-game-night-rsvp'),
        );
        expect(detail, findsOneWidget);
        // Scope icon checks to within the event detail (avoids false match
        // from the date-strip chip which also uses Icons.schedule)
        for (final icon in <IconData>[
          Icons.schedule,
          Icons.location_on_outlined,
          Icons.groups_outlined,
        ]) {
          expect(
            find.descendant(of: detail, matching: find.byIcon(icon)),
            findsOneWidget,
          );
        }
        // The old generic icon must not appear anywhere
        expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      },
    );

    testWidgets(
      'wf_calendar-tab-renders-host-when-declared',
      (tester) async {
        final fixture = _writeTabletopClubPackagePair(includeHost: true);
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);
        await _tapTab(tester, 'calendar');
        // host renders as a fact pill in the event detail
        expect(
          find.textContaining('Alex Chen (Organizer)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'wf_calendar-tab-still-renders-without-host',
      (tester) async {
        // Rule 2: negative direction — detail renders correctly when host is absent
        final fixture = _writeTabletopClubPackagePair(includeHost: false);
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);
        await _tapTab(tester, 'calendar');
        expect(
          find.byKey(const ValueKey('calendar-tab-surface')),
          findsOneWidget,
        );
        expect(find.textContaining('Alex Chen'), findsNothing);
      },
    );

    testWidgets(
      'wf_calendar-tab-catalog-community-keeps-placeholder-strip',
      (tester) async {
        // Regression guard: Camera Club now has package-declared calendar
        // workflow data, so it must render the engine-backed agenda surface
        // instead of the legacy placeholder strip.
        final target = loomEvidenceTargets.firstWhere(
          (target) => target.extensionId == 'ext_camera_club',
        );
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await installEvidenceTarget(tester, target);
        await openEvidenceTarget(tester, target);

        await _tapTab(tester, 'calendar');

        expect(
          find.byKey(const ValueKey('camera-engine-calendar')),
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

_PackagePairFixture _writeTabletopClubPackagePair({bool includeHost = false}) {
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
              if (includeHost) 'host': 'Alex Chen (Organizer)',
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

_PackagePairFixture _writeTabletopClubTwoSameDayFixture() {
  final tempDir = Directory.systemTemp.createTempSync('loom_b27_twosameday_');
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
          {
            'workflowId': 'tabletop-tournament-rsvp',
            'title': 'Sign up for the Saturday tournament',
            'entryText':
                'Saturday board game tournament at the community hall, 1-5pm. 20 of 20 seats filled.',
            'actionText': 'Sign up for the Saturday tournament.',
            'resultText': "You're signed up for the Saturday tournament.",
            'calendar': {
              'date': '2026-07-10',
              'time': '13:00',
              'location': 'Community hall',
              'capacityLabel': '20 of 20 seats filled',
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
          'tabletop-tournament-rsvp': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
            'receiverEntryText':
                'A member signed up for the Saturday tournament.',
            'receiverActionText': 'Acknowledge signup',
            'receiverResultText': 'Signup acknowledged.',
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
