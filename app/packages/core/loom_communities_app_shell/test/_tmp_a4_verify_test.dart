import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

String _strip(String content) {
  final buf = StringBuffer();
  var i = 0, inString = false;
  while (i < content.length) {
    if (inString && content[i] == '\\' && i + 1 < content.length) {
      buf.write(content[i]);
      i++;
      buf.write(content[i]);
      i++;
      continue;
    }
    if (content[i] == '"') {
      inString = !inString;
      buf.write(content[i]);
      i++;
      continue;
    }
    if (!inString &&
        i + 1 < content.length &&
        content[i] == '/' &&
        content[i + 1] == '/') {
      while (i < content.length && content[i] != '\n') {
        i++;
      }
      continue;
    }
    buf.write(content[i]);
    i++;
  }
  return buf.toString();
}

void main() {
  test('THROWAWAY: verify A.4 against the real Tabletop Club fixture', () {
    final path =
        '../../../../docs/Build Plan V2/Loom Communities Workflow Engine V3/'
        'Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';
    final raw = File(path).readAsStringSync();
    final decoded = jsonDecode(_strip(raw)) as Map<String, dynamic>;
    final experience = decoded['experience'] as Map<String, dynamic>;

    final def = experienceForExtensionId(
      'ext_tabletop_club_verify',
      experienceConfiguration: experience,
    );

    print('workflowDefinitions: ${def.workflowDefinitions?.length}');
    print('workflowDefinitions keys: ${def.workflowDefinitions?.keys.toList()}');
    print('workflowInstances: ${def.workflowInstances?.length}');

    expect(def.workflowDefinitions, isNotNull);
    expect(def.workflowDefinitions!.length, 11);
    expect(def.workflowInstances, isNotNull);
    expect(def.workflowInstances!.length, 17);

    final friday = def.workflowInstances!.firstWhere(
      (i) => i.instanceId == 'event-friday-game-night',
    );
    print('friday currentState: ${friday.currentState}');
    print(
      'friday goingPersonaIds length: '
      '${(friday.instanceData['goingPersonaIds'] as List).length}',
    );
    expect(friday.currentState, 'open');
    expect((friday.instanceData['goingPersonaIds'] as List).length, 12);
  });
}
