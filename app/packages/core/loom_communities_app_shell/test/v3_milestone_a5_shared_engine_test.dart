import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

const _fixtureRelative =
    'docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

File _fixtureFile() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_fixtureRelative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not find the frozen Tabletop fixture.');
}

void main() {
  test('real Tabletop package install shares one seeded engine', () async {
    final fixture = _fixtureFile();
    final initialization = jsonDecode(stripJsonComments(fixture.readAsStringSync()))
        as Map<String, dynamic>;
    final temp = await Directory.systemTemp.createTemp('loom-a5-tabletop-');
    try {
      final initFile = File('${temp.path}/tabletop.loom-init.zip');
      final extensionFile = File('${temp.path}/tabletop.loom-extension.zip');
      await initFile.writeAsString(jsonEncode(initialization));
      await extensionFile.writeAsString(jsonEncode(<String, Object?>{
        'extensionId': initialization['extensionId'],
        'displayName': initialization['displayName'],
        'version': '1.0.0',
        'permissions': <String>[],
      }));

      final backend = LocalInAppBackend();
      final firstInstall = backend.installLocalPackagePairFromFiles(
        extensionPackagePath: extensionFile.path,
        initializationPackagePath: initFile.path,
      );
      final community = firstInstall.community;
      final resolved = experienceForExtensionId(
        community.extensionId,
        displayName: community.displayName,
        experienceConfiguration: community.experienceConfiguration,
      );
      final engine = await workflowEngineForExtensionId(community.extensionId);
      final rows = (await engine.queryInstances(
        tabId: 'home',
        personaId: 'tabletop-member',
        limit: 50,
      )).items;

      const expectedIds = <String>{
        'event-friday-game-night',
        'event-summer-tournament',
        'ballot-summer-tournament',
        'vote-m03-catan',
        'vote-m04-wingspan',
        'vote-m05-catan',
        'vote-m06-azul',
        'listing-catan',
        'listing-wingspan',
        'listing-root',
        'listing-old-catan',
        'dues-2026-q3-member',
        'proposal-wingspan',
        'proposal-brass',
        'announcement-room-change',
        'thread-welcome',
        'thread-game-suggestions',
      };
      expect(rows, hasLength(17));
      expect(rows.map((row) => row.instanceId), unorderedEquals(expectedIds));

      final expectedSeeds = <String, LoomWorkflowSeedInstance>{
        for (final seed in resolved.workflowInstances!) seed.instanceId: seed,
      };
      expect(expectedSeeds.keys, unorderedEquals(expectedIds));
      for (final row in rows) {
        final seed = expectedSeeds[row.instanceId]!;
        expect(row.workflowType, seed.workflowType);
        expect(row.currentState, seed.currentState);
        expect(row.createdByPersonaId, seed.createdByPersonaId);
        for (final entry in seed.instanceData.entries) {
          expect(row.instanceData[entry.key], entry.value, reason: row.instanceId);
        }
      }
      expect(
        rows.singleWhere((row) => row.instanceId == 'proposal-wingspan').currentState,
        'approved',
      );
      expect(
        rows.singleWhere((row) => row.instanceId == 'proposal-brass').currentState,
        'pending',
      );
      final fridaySeed = expectedSeeds['event-friday-game-night']!;
      expect(fridaySeed.instanceData, isNot(contains('goingCount')));
      final friday = rows.singleWhere(
        (row) => row.instanceId == 'event-friday-game-night',
      );
      expect(friday.instanceData['goingPersonaIds'], hasLength(12));
      expect(friday.instanceData['goingCount'], 12);

      final secondInstall = backend.installLocalPackagePairFromFiles(
        extensionPackagePath: extensionFile.path,
        initializationPackagePath: initFile.path,
      );
      final reinstalled = secondInstall.community;
      experienceForExtensionId(
        reinstalled.extensionId,
        displayName: reinstalled.displayName,
        experienceConfiguration: reinstalled.experienceConfiguration,
      );
      final reloadedEngine = await workflowEngineForExtensionId(
        reinstalled.extensionId,
      );
      expect(identical(engine, reloadedEngine), isTrue);
      final repeatedRows = (await reloadedEngine.queryInstances(
        tabId: 'home',
        personaId: 'tabletop-member',
        limit: 50,
      )).items;
      expect(repeatedRows, hasLength(17));
      expect(
        repeatedRows.map((row) => row.instanceId),
        unorderedEquals(expectedIds),
      );

      await reloadedEngine.createInstance(
        workflowType: 'tabletop-game-loan',
        initialInstanceData: const <String, dynamic>{},
        personaId: 'tabletop-member',
      );
      expect(resolved.workflowDefinitions, hasLength(11));
    } finally {
      await temp.delete(recursive: true);
    }
  });
}
