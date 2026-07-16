import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

// Reuses the same frozen-JSON fixture and installation pattern as
// v3_milestone_a8_calendar_end_to_end_test.dart.

const _fixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

File _fixtureFile() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_fixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find frozen Tabletop fixture');
}

class _InstalledTabletop {
  const _InstalledTabletop(
    this.community,
    this.experience,
    this.engine,
    this.temp,
  );
  final LocalInstalledCommunity community;
  final LoomExperienceDefinition experience;
  final WorkflowEngineApi engine;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

Future<_InstalledTabletop> _install(String extensionId) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp('loom-a11-$extensionId-');
  try {
    final init = File('${temp.path}/tabletop.loom-init.zip');
    final extension = File('${temp.path}/tabletop.loom-extension.zip');
    await init.writeAsString(jsonEncode(source));
    await extension.writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'extensionId': extensionId,
        'displayName': source['displayName'],
        'version': '1.0.0',
        'mode': 'local-demo',
        'permissions': <String>[],
      }),
    );
    final community = LocalInAppBackend()
        .installLocalPackagePairFromFiles(
          extensionPackagePath: extension.path,
          initializationPackagePath: init.path,
        )
        .community;
    final experience = experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
      experienceConfiguration: community.experienceConfiguration,
    );
    return _InstalledTabletop(
      community,
      experience,
      await workflowEngineForExtensionId(community.extensionId),
      temp,
    );
  } catch (_) {
    await temp.delete(recursive: true);
    rethrow;
  }
}

LoomPersonaDefinition _persona(_InstalledTabletop installed, String id) =>
    installed.experience.personas!.firstWhere(
      (persona) => persona.personaId == id,
    );

Widget _calendar(
  _InstalledTabletop installed,
  String personaId, {
  int revision = 0,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: EngineNativeCalendarSurface(
        key: ValueKey('a11-calendar-$personaId-$revision'),
        experience: installed.experience,
        persona: _persona(installed, personaId),
        accent: Colors.deepPurple,
        modernTheme: null,
        engine: installed.engine,
      ),
    ),
  ),
);

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<WorkflowInstance> _instance(
  WidgetTester tester,
  _InstalledTabletop installed,
  String id, {
  String personaId = 'tabletop-organizer',
}) async => (await tester.runAsync(() async {
  final page = await installed.engine.queryInstances(
    tabId: 'calendar',
    personaId: personaId,
    limit: 50,
  );
  return page.items.singleWhere((row) => row.instanceId == id);
}))!;

/// Taps an action chip keyed to the bespoke event-rsvp widget.
Future<void> _tapRsvpAction(
  WidgetTester tester,
  String instanceId,
  String transitionId,
) async {
  final action = find.byKey(
    ValueKey('event-rsvp-$instanceId-action-$transitionId'),
  );
  await _pumpUntil(tester, action);
  await tester.ensureVisible(action);
  await tester.pump();
  await tester.tap(action);
  await tester.pump();
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _selectAgenda(
  WidgetTester tester,
  String instanceId,
  int ordinal,
) async {
  final row = find.byKey(
    ValueKey('engine-native-calendar-agenda-$instanceId-$ordinal'),
  );
  await _pumpUntil(tester, row);
  await tester.ensureVisible(row);
  await tester.tap(row);
  await tester.pump();
}

void main() {
  // ---------------------------------------------------------------------------
  // Test 1: Selecting the Friday game-night event renders the bespoke
  //         _EventRsvpDetailCard, NOT GenericWorkflowInstanceCard.
  // ---------------------------------------------------------------------------
  testWidgets('Friday game-night renders bespoke event-rsvp card, not generic', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a11-bespoke')))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey(
            'engine-native-calendar-agenda-event-friday-game-night-0',
          ),
        ),
      );
      await tester.pump();

      // The detail card should be the bespoke widget, not the generic one.
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'engine-native-calendar-selected-detail-event-friday-game-night-0',
          ),
        ),
      );
      expect(
        find.byKey(
          const ValueKey('event-rsvp-card-event-friday-game-night'),
        ),
        findsOneWidget,
      );
      expect(find.byType(GenericWorkflowInstanceCard), findsNothing);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  // ---------------------------------------------------------------------------
  // Test 2: The capacity visualization reflects the real going-count/capacity
  //         (Friday seed: goingPersonaIds length 12, capacity 20).
  // ---------------------------------------------------------------------------
  testWidgets('capacity bar reflects real going count and capacity', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a11-capacity')))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);

      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey('event-rsvp-card-event-friday-game-night'),
        ),
      );

      // Going: 12 / 20
      expect(find.text('12 / 20 going'), findsOneWidget);
      expect(find.text('8 seats left'), findsOneWidget);

      // Progress bar present
      final bar = find.byKey(
        const ValueKey('event-rsvp-capacity-bar-event-friday-game-night'),
      );
      expect(bar, findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(bar);
      expect(indicator.value, 12 / 20);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  // ---------------------------------------------------------------------------
  // Test 3: Tapping "Going" for a persona not yet in goingPersonaIds calls the
  //         real engine, and the resulting instance reflects the new state.
  // ---------------------------------------------------------------------------
  testWidgets('Going action persists through real engine and updates the card', (
    tester,
  ) async {
    final installed = (await tester.runAsync(() => _install('a11-going')))!;
    try {
      // The organizer is in maybePersonaIds, not goingPersonaIds.
      await tester.pumpWidget(_calendar(installed, 'tabletop-organizer'));
      await _selectAgenda(tester, 'event-friday-game-night', 0);

      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey('event-rsvp-card-event-friday-game-night'),
        ),
      );

      // Before: organizer is not in goingPersonaIds
      final before = await _instance(
        tester,
        installed,
        'event-friday-game-night',
      );
      expect(
        before.instanceData['goingPersonaIds'],
        isNot(contains('tabletop-organizer')),
      );

      await _tapRsvpAction(tester, 'event-friday-game-night', 'rsvp-going');

      // After: organizer IS in goingPersonaIds, not in maybe
      final after = await _instance(
        tester,
        installed,
        'event-friday-game-night',
      );
      expect(
        after.instanceData['goingPersonaIds'],
        contains('tabletop-organizer'),
      );
      expect(
        after.instanceData['maybePersonaIds'],
        isNot(contains('tabletop-organizer')),
      );
      expect(after.instanceData['goingCount'], 13);
      expect(after.instanceData['seatsRemaining'], 7);

      // UI reflects new state
      await _pumpUntil(tester, find.text('13 / 20 going'));
      expect(find.text('13 / 20 going'), findsOneWidget);
      expect(find.text('7 seats left'), findsOneWidget);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  // ---------------------------------------------------------------------------
  // Test 4: The waitlist state renders distinctly once goingPersonaIds fills
  //         capacity.
  // ---------------------------------------------------------------------------
  testWidgets('waitlist indicator renders when capacity is reached', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('a11-waitlist'),
    ))!;
    try {
      // Set up: make tabletop-member withdraw (freeing a seat), then reduce
      // capacity to 11 so the 11 going personas fill it.
      await tester.runAsync(() async {
        await installed.engine.applyTransition(
          workflowType: 'event-rsvp',
          instanceId: 'event-friday-game-night',
          transitionId: 'rsvp-maybe',
          personaId: 'tabletop-member',
        );
        await installed.engine.updateInstanceFields(
          workflowType: 'event-rsvp',
          instanceId: 'event-friday-game-night',
          fieldUpdates: const {'capacity': 11},
          personaId: 'tabletop-organizer',
        );
      });

      // Now 11 going, capacity 11 → full. tabletop-member is not going.
      await tester.pumpWidget(
        _calendar(installed, 'tabletop-member', revision: 2),
      );
      await _selectAgenda(tester, 'event-friday-game-night', 0);

      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey('event-rsvp-card-event-friday-game-night'),
        ),
      );

      // Full capacity bar
      expect(find.text('11 / 11 going'), findsOneWidget);
      expect(find.text('0 seats left'), findsOneWidget);

      // Join waitlist action should be available (not Going)
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-join-waitlist',
          ),
        ),
      );
      expect(
        find.byKey(
          const ValueKey(
            'event-rsvp-event-friday-game-night-action-rsvp-going',
          ),
        ),
        findsNothing,
      );

      // No waitlist indicator yet
      expect(
        find.byKey(
          const ValueKey('event-rsvp-waitlist-event-friday-game-night'),
        ),
        findsNothing,
      );

      // Join waitlist
      await _tapRsvpAction(tester, 'event-friday-game-night', 'join-waitlist');

      final waitlisted = await _instance(
        tester,
        installed,
        'event-friday-game-night',
        personaId: 'tabletop-member',
      );
      expect(
        waitlisted.instanceData['waitlistPersonaIds'],
        contains('tabletop-member'),
      );
      expect(waitlisted.instanceData['goingCount'], 11);

      // Waitlist indicator appears
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey('event-rsvp-waitlist-event-friday-game-night'),
        ),
      );
      expect(
        find.byKey(
          const ValueKey('event-rsvp-waitlist-event-friday-game-night'),
        ),
        findsOneWidget,
      );
      expect(find.text('You are on the waitlist'), findsOneWidget);
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });

  // ---------------------------------------------------------------------------
  // Test 5: Selecting the Summer Tournament (tournament-event, which shares
  //         cardSurfaceFamily 'event-rsvp') also renders the bespoke widget.
  // ---------------------------------------------------------------------------
  testWidgets('Summer Tournament also renders bespoke event-rsvp card', (
    tester,
  ) async {
    final installed = (await tester.runAsync(
      () => _install('a11-tournament'),
    ))!;
    try {
      await tester.pumpWidget(_calendar(installed, 'tabletop-member'));
      await _selectAgenda(tester, 'event-summer-tournament', 0);

      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'engine-native-calendar-selected-detail-event-summer-tournament-0',
          ),
        ),
      );

      // Bespoke card, not generic
      expect(
        find.byKey(
          const ValueKey('event-rsvp-card-event-summer-tournament'),
        ),
        findsOneWidget,
      );
      expect(find.byType(GenericWorkflowInstanceCard), findsNothing);

      // Tournament-specific: Accepted count, quorum met indicator
      expect(find.text('8 / 8 going'), findsOneWidget); // accepted=8, minimumAttendance=8
      expect(
        find.byKey(
          const ValueKey('event-rsvp-capacity-bar-event-summer-tournament'),
        ),
        findsOneWidget,
      );

      // tabletop-member is in goingPersonaIds, so withdraw should be visible
      await _pumpUntil(
        tester,
        find.byKey(
          const ValueKey(
            'event-rsvp-event-summer-tournament-action-rsvp-withdraw',
          ),
        ),
      );
      expect(
        find.byKey(
          const ValueKey(
            'event-rsvp-event-summer-tournament-action-rsvp-going',
          ),
        ),
        findsNothing,
      );
    } finally {
      await tester.runAsync(installed.dispose);
    }
  });
}
