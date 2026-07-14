import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

void main() {
  test('one shared engine seeds the real Tabletop experience once', () async {
    const relative =
        'docs/Build Plan V2/Loom Communities Workflow Engine V3/Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';
    var directory = Directory.current;
    File? fixture;
    for (var i = 0; i < 8; i++) {
      final candidate = File('${directory.path}/$relative');
      if (candidate.existsSync()) {
        fixture = candidate;
        break;
      }
      directory = directory.parent;
    }
    final decoded =
        jsonDecode(stripJsonComments(fixture!.readAsStringSync()))
            as Map<String, dynamic>;
    final experience = Map<String, Object?>.from(decoded['experience'] as Map);
    final resolved = experienceForExtensionId(
      'a5-tabletop-engine',
      experienceConfiguration: experience,
    );
    final engine = await workflowEngineForExtensionId('a5-tabletop-engine');
    final rows = (await engine.queryInstances(
      tabId: 'home',
      personaId: 'tabletop-member',
      limit: 50,
    )).items;
    expect(rows, hasLength(17));
    expect(
      rows.map((row) => row.instanceId),
      containsAll(<String>[
        'event-friday-game-night',
        'proposal-wingspan',
        'proposal-brass',
      ]),
    );
    expect(
      rows
          .singleWhere((row) => row.instanceId == 'proposal-wingspan')
          .currentState,
      'approved',
    );
    expect(
      rows
          .singleWhere((row) => row.instanceId == 'proposal-brass')
          .currentState,
      'pending',
    );
    final friday = rows.singleWhere(
      (row) => row.instanceId == 'event-friday-game-night',
    );
    expect(friday.instanceData['goingPersonaIds'], hasLength(12));
    expect(friday.instanceData['goingCount'], 12);
    expect(resolved.workflowDefinitions, hasLength(11));
    expect(
      identical(
        engine,
        await workflowEngineForExtensionId('a5-tabletop-engine'),
      ),
      isTrue,
    );
    expect(
      (await engine.queryInstances(
        tabId: 'home',
        personaId: 'tabletop-member',
        limit: 50,
      )).items,
      hasLength(17),
    );
  });
}
