import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

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
  const _InstalledTabletop(this.community, this.engine, this.temp);

  final LocalInstalledCommunity community;
  final WorkflowEngineApi engine;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

Future<_InstalledTabletop> _install(String extensionId) async {
  final source =
      jsonDecode(stripJsonComments(_fixtureFile().readAsStringSync()))
          as Map<String, dynamic>;
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp('loom-phaseb-votepoll-');
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
    // Register the engine-native store before the widget is pumped. Keeping
    // registration and engine creation in this same runAsync call avoids
    // creating the native sqlite connection in Flutter's fake-async zone and
    // later accessing it from a real async zone.
    experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
      experienceConfiguration: community.experienceConfiguration,
    );
    final engine = await workflowEngineForExtensionId(community.extensionId);
    return _InstalledTabletop(community, engine, temp);
  } catch (_) {
    await temp.delete(recursive: true);
    rethrow;
  }
}

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

Future<void> _selectPersona(WidgetTester tester, String personaId) async {
  final personaPicker = find.byKey(const ValueKey('persona-picker-button'));
  await _pumpUntil(tester, personaPicker);
  await tester.tap(personaPicker);
  await tester.pump();
  final option = find.byKey(ValueKey('persona-option-$personaId'));
  await _pumpUntil(tester, option);
  await tester.tap(option);
  await tester.pump();
}

Future<List<WorkflowInstance>> _voteRows(
  _InstalledTabletop installed,
  String personaId,
) async {
  final page = await installed.engine.queryInstances(
    tabId: 'home',
    personaId: personaId,
    limit: 200,
  );
  return page.items
      .where(
        (instance) =>
            instance.workflowType == 'tournament-vote' &&
            instance.instanceData['ballotId'] == 'ballot-summer-tournament',
      )
      .toList();
}

Future<List<WorkflowInstance>> _instancesOfType(
  _InstalledTabletop installed,
  String personaId,
  String workflowType,
) async {
  final page = await installed.engine.queryInstances(
    tabId: 'home',
    personaId: personaId,
    limit: 200,
  );
  return page.items
      .where((instance) => instance.workflowType == workflowType)
      .toList();
}

Future<WorkflowInstance> _instanceById(
  _InstalledTabletop installed,
  String personaId,
  String instanceId,
) async {
  final page = await installed.engine.queryInstances(
    tabId: 'home',
    personaId: personaId,
    limit: 200,
  );
  return page.items.singleWhere(
    (instance) => instance.instanceId == instanceId,
  );
}

Future<WorkflowInstance> _waitForState(
  WidgetTester tester,
  _InstalledTabletop installed,
  String personaId,
  String instanceId,
  String state,
) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    final instance = (await tester.runAsync(
      () => _instanceById(installed, personaId, instanceId),
    ))!;
    if (instance.currentState == state) return instance;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw StateError('Timed out waiting for $instanceId to enter $state');
}

Map<String, int> _voteCounts(dynamic rawCounts) => <String, int>{
  if (rawCounts is Map)
    for (final entry in rawCounts.entries)
      '${entry.key}': (entry.value as num).toInt(),
};

Set<String> _candidateIds(dynamic rawCandidates) => {
  if (rawCandidates is Iterable)
    for (final candidate in rawCandidates)
      candidate is Map ? '${candidate['id']}' : '$candidate',
};

Widget _app(_InstalledTabletop installed) => MaterialApp(
  home: LocalExtensionScreen(
    community: installed.community,
    seedDataFiles: const [],
  ),
);

void main() {
  testWidgets(
    'real frozen ballot renders persona-aware votePoll behavior and casts a row',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('phaseb-votepoll'),
      ))!;
      try {
        await tester.pumpWidget(_app(installed));

        await _selectPersona(tester, 'tabletop-organizer');
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('votepoll-card-ballot-summer-tournament')),
        );
        await _pumpUntil(tester, find.text('Catan: 2 votes'));

        expect(find.text('Azul: 1 votes'), findsOneWidget);
        expect(find.text('Wingspan: 1 votes'), findsOneWidget);
        final candidateTheme = LoomCardTheme.deriveFromAccent(
          const Color(0xffC4703F),
          lightSurface: true,
        );
        final candidateSurface = tester.widget<DecoratedBox>(
          find.byKey(
            const ValueKey(
              'votepoll-candidate-surface-ballot-summer-tournament-catan',
            ),
          ),
        );
        final candidateDecoration =
            candidateSurface.decoration as BoxDecoration;
        expect(candidateDecoration.color, candidateTheme.resolvedFill);
        expect(
          candidateDecoration.border!.top.color,
          candidateTheme.resolvedBorder,
        );
        expect(
          find.byKey(
            const ValueKey('votepoll-reminder-ballot-summer-tournament'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-list-item-home-ballot-summer-tournament-0',
            ),
          ),
          findsOneWidget,
        );

        // The engine's cross-instance eligibility guard excludes the
        // organizer from voting, while the organizer-only close transition
        // remains available.
        for (final candidateId in const ['catan', 'azul', 'wingspan']) {
          expect(
            find.byKey(
              ValueKey('votepoll-vote-ballot-summer-tournament-$candidateId'),
            ),
            findsNothing,
          );
        }
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey('votepoll-close-vote-ballot-summer-tournament'),
          ),
        );
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-list-item-home-event-summer-tournament-1',
            ),
          ),
          findsOneWidget,
        );

        // Candidate names open the bespoke detail dialog.
        final catanName = find.byKey(
          const ValueKey(
            'votepoll-candidate-name-ballot-summer-tournament-catan',
          ),
        );
        await tester.ensureVisible(catanName);
        await tester.tap(catanName);
        await tester.pump();
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey(
              'votepoll-detail-dialog-ballot-summer-tournament-catan',
            ),
          ),
        );
        expect(
          find.byKey(
            const ValueKey(
              'votepoll-detail-description-ballot-summer-tournament-catan',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.text('Classic trading and building game for 3-4 players.'),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(
            const ValueKey(
              'votepoll-detail-close-ballot-summer-tournament-catan',
            ),
          ),
        );
        await tester.pump();

        await _selectPersona(tester, 'tabletop-member');
        await _pumpUntil(
          tester,
          find.byKey(
            const ValueKey('votepoll-vote-ballot-summer-tournament-catan'),
          ),
        );
        for (final candidateId in const ['catan', 'azul', 'wingspan']) {
          expect(
            find.byKey(
              ValueKey('votepoll-vote-ballot-summer-tournament-$candidateId'),
            ),
            findsOneWidget,
          );
        }
        expect(
          find.byKey(
            const ValueKey('votepoll-close-vote-ballot-summer-tournament'),
          ),
          findsNothing,
        );

        final beforeRows = (await tester.runAsync(
          () => _voteRows(installed, 'tabletop-member'),
        ))!;
        expect(beforeRows, hasLength(4));

        await tester.ensureVisible(
          find.byKey(
            const ValueKey('votepoll-vote-ballot-summer-tournament-catan'),
          ),
        );
        await tester.tap(
          find.byKey(
            const ValueKey('votepoll-vote-ballot-summer-tournament-catan'),
          ),
        );
        await tester.pump();
        await _pumpUntil(tester, find.text('Catan: 3 votes'));

        final afterRows = (await tester.runAsync(
          () => _voteRows(installed, 'tabletop-member'),
        ))!;
        expect(afterRows, hasLength(5));
        expect(
          afterRows.any(
            (row) =>
                row.instanceData['voterId'] == 'tabletop-member' &&
                row.instanceData['choice'] == 'catan',
          ),
          isTrue,
        );
        expect(find.text('Catan: 2 votes'), findsNothing);
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'real close-vote writes the clear winner to the related tournament event',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('phaseb6-clear-winner'),
      ))!;
      try {
        await tester.pumpWidget(_app(installed));
        await _selectPersona(tester, 'tabletop-organizer');

        final initialBallot = (await tester.runAsync(
          () => _instanceById(
            installed,
            'tabletop-organizer',
            'ballot-summer-tournament',
          ),
        ))!;
        expect(_voteCounts(initialBallot.instanceData['voteCounts']), {
          'catan': 2,
          'wingspan': 1,
          'azul': 1,
        });
        expect(initialBallot.instanceData['winner'], 'catan');
        expect(initialBallot.instanceData['isTie'], isFalse);

        final closeButton = find.byKey(
          const ValueKey('votepoll-close-vote-ballot-summer-tournament'),
        );
        await _pumpUntil(tester, closeButton);
        await tester.ensureVisible(closeButton);
        await tester.tap(closeButton);
        await tester.pump();

        final closedBallot = await _waitForState(
          tester,
          installed,
          'tabletop-organizer',
          'ballot-summer-tournament',
          'closed',
        );
        expect(closedBallot.instanceData['outcome'], 'decided');

        final event = (await tester.runAsync(
          () => _instanceById(
            installed,
            'tabletop-organizer',
            'event-summer-tournament',
          ),
        ))!;
        expect(event.instanceData['selectedGame'], 'catan');
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'real close-vote creates a runoff ballot for a queried three-way tie',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('phaseb6-tie-runoff'),
      ))!;
      try {
        await tester.pumpWidget(_app(installed));
        await _selectPersona(tester, 'tabletop-organizer');

        final closeButton = find.byKey(
          const ValueKey('votepoll-close-vote-ballot-summer-tournament'),
        );
        await _pumpUntil(tester, closeButton);

        await tester.runAsync(() async {
          await installed.engine.applyTransition(
            workflowType: 'tournament-ballot',
            instanceId: 'ballot-summer-tournament',
            transitionId: 'cast-vote',
            personaId: 'tabletop-member',
            inputs: {'choice': 'wingspan'},
          );
          await installed.engine.applyTransition(
            workflowType: 'tournament-ballot',
            instanceId: 'ballot-summer-tournament',
            transitionId: 'cast-vote',
            personaId: 'tabletop-member',
            inputs: {'choice': 'azul'},
          );
        });

        final tiedBallotBeforeClose = (await tester.runAsync(
          () => _instanceById(
            installed,
            'tabletop-organizer',
            'ballot-summer-tournament',
          ),
        ))!;
        final queriedVoteCounts = _voteCounts(
          tiedBallotBeforeClose.instanceData['voteCounts'],
        );
        expect(queriedVoteCounts, {'catan': 2, 'wingspan': 2, 'azul': 2});
        expect(tiedBallotBeforeClose.instanceData['isTie'], isTrue);
        final tiedCandidateIds = _candidateIds(
          tiedBallotBeforeClose.instanceData['tiedCandidates'],
        );
        expect(tiedCandidateIds, {'catan', 'wingspan', 'azul'});

        await tester.ensureVisible(closeButton);
        await tester.tap(closeButton);
        await tester.pump();

        final closedBallot = await _waitForState(
          tester,
          installed,
          'tabletop-organizer',
          'ballot-summer-tournament',
          'closed',
        );
        expect(closedBallot.instanceData['outcome'], 'runoff');

        final ballots = (await tester.runAsync(
          () => _instancesOfType(
            installed,
            'tabletop-organizer',
            'tournament-ballot',
          ),
        ))!;
        final runoffBallots = ballots
            .where(
              (instance) => instance.instanceId != 'ballot-summer-tournament',
            )
            .toList();
        expect(runoffBallots, hasLength(1));
        final runoff = runoffBallots.single;
        expect(runoff.instanceData['round'], 'runoff');
        expect(runoff.instanceData['eventId'], 'event-summer-tournament');
        expect(
          _candidateIds(runoff.instanceData['candidates']),
          tiedCandidateIds,
        );

        final event = (await tester.runAsync(
          () => _instanceById(
            installed,
            'tabletop-organizer',
            'event-summer-tournament',
          ),
        ))!;
        expect(event.instanceData['selectedGame'], 'TBD');
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );

  testWidgets(
    'engine refuses an ineligible cast-vote and accepts an eligible one',
    (tester) async {
      final installed = (await tester.runAsync(
        () => _install('phaseb4-eligibility'),
      ))!;
      try {
        final beforeRows = (await tester.runAsync(
          () => _voteRows(installed, 'tabletop-organizer'),
        ))!;
        expect(beforeRows, hasLength(4));

        // The organizer is allowed by cast-vote's persona list but is not in
        // the related tournament-event goingPersonaIds list. The engine must
        // reject the transition itself, not merely omit a UI button.
        Object? refusalError;
        await tester.runAsync(() async {
          try {
            await installed.engine.applyTransition(
              workflowType: 'tournament-ballot',
              instanceId: 'ballot-summer-tournament',
              transitionId: 'cast-vote',
              personaId: 'tabletop-organizer',
              inputs: {'choice': 'catan'},
            );
          } catch (error) {
            refusalError = error;
          }
        });
        expect(refusalError, isA<StateError>());

        final afterRefusedRows = (await tester.runAsync(
          () => _voteRows(installed, 'tabletop-organizer'),
        ))!;
        expect(afterRefusedRows, hasLength(4));
        expect(
          afterRefusedRows.any(
            (row) => row.instanceData['voterId'] == 'tabletop-organizer',
          ),
          isFalse,
        );

        // The same engine call succeeds for the seeded eligible member and
        // creates the real vote row as the contrast case.
        await tester.runAsync(
          () => installed.engine.applyTransition(
            workflowType: 'tournament-ballot',
            instanceId: 'ballot-summer-tournament',
            transitionId: 'cast-vote',
            personaId: 'tabletop-member',
            inputs: {'choice': 'catan'},
          ),
        );
        final afterEligibleRows = (await tester.runAsync(
          () => _voteRows(installed, 'tabletop-member'),
        ))!;
        expect(afterEligibleRows, hasLength(5));
        expect(
          afterEligibleRows.any(
            (row) =>
                row.instanceData['voterId'] == 'tabletop-member' &&
                row.instanceData['choice'] == 'catan',
          ),
          isTrue,
        );
      } finally {
        await tester.runAsync(installed.dispose);
      }
    },
  );
}
