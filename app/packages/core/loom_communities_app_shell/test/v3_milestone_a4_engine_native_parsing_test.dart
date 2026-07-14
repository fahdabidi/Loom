import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

const _tabletopRelativePath =
    'docs/Build Plan V2/Loom Communities Workflow Engine V3/'
    'Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

Map<String, Object?> _tabletopExperience() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final file = File('${directory.path}/$_tabletopRelativePath');
    if (file.existsSync()) {
      final package =
          jsonDecode(stripJsonComments(file.readAsStringSync()))
              as Map<String, dynamic>;
      return Map<String, Object?>.from(package['experience'] as Map);
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError('Tabletop fixture not found: $_tabletopRelativePath');
}

Map<String, Object?> _legacyExperience({int? version}) => <String, Object?>{
  if (version != null) 'experienceSchemaVersion': version,
  'displayName': 'Legacy Tabletop',
  'workflows': <Object?>[
    <String, Object?>{
      'workflowId': 'legacy-roster',
      'title': 'Volunteer roster',
      'entryText': 'Choose a shift.',
      'actionText': 'Sign up.',
      'resultText': 'Reserved.',
    },
  ],
  'personas': <Object?>[
    <String, Object?>{
      'personaId': 'legacy-member',
      'label': 'Member',
      'roleLabel': 'Member',
      'description': 'Legacy member',
    },
  ],
};

Map<String, Object?> _v2Experience({int grammarVersion = 1}) =>
    <String, Object?>{
      'experienceSchemaVersion': 2,
      'workflowGrammarVersion': grammarVersion,
      'workflowDefinitions': <String, Object?>{
        'valid': <String, Object?>{
          'initialState': 'open',
          'states': <String, Object?>{
            'open': <String, Object?>{'label': 'Open'},
            'done': <String, Object?>{'label': 'Done', 'isTerminal': true},
          },
          'transitions': <Object?>[
            <String, Object?>{
              'id': 'finish',
              'label': 'Finish',
              'from': <Object?>['open'],
              'to': 'done',
            },
          ],
        },
      },
      'workflowInstances': <Object?>[
        <String, Object?>{
          'instanceId': 'valid-instance',
          'workflowType': 'valid',
          'currentState': 'open',
          'instanceData': <String, Object?>{},
        },
      ],
    };

List<Object?> _legacyProjection(LoomExperienceDefinition experience) =>
    <Object?>[
      experience.displayName,
      experience.workflows
          .map(
            (workflow) => <Object?>[
              workflow.workflowId,
              workflow.title,
              workflow.entryText,
              workflow.actionText,
              workflow.resultText,
            ],
          )
          .toList(),
      experience.personas?.map((persona) => persona.personaId).toList(),
      experience.workflowDefinitions,
      experience.workflowInstances,
    ];

void main() {
  test('1 parses the real Tabletop engine-native package completely', () {
    final experience = experienceForExtensionId(
      'a4-tabletop-real-fixture',
      experienceConfiguration: _tabletopExperience(),
    );
    final definitions = experience.workflowDefinitions;
    final instances = experience.workflowInstances;

    expect(definitions, isNotNull);
    expect(
      definitions!.keys,
      unorderedEquals(<String>[
        'event-rsvp',
        'tournament-event',
        'tournament-ballot',
        'tournament-vote',
        'equipment-loan',
        'equipment-giveaway',
        'tabletop-game-loan',
        'tabletop-club-dues-payment',
        'game-purchase-proposal',
        'tabletop-meetup-announcement',
        'discussion-thread',
      ]),
    );
    expect(instances, isNotNull);
    expect(instances, hasLength(17));
    expect(
      definitions['event-rsvp']!.states.keys,
      containsAll(<String>['open', 'cancelled']),
    );
    expect(
      definitions['event-rsvp']!.transitions.map((t) => t.id),
      contains('rsvp-going'),
    );
    final friday = instances!.singleWhere(
      (instance) => instance.instanceId == 'event-friday-game-night',
    );
    expect(friday.currentState, 'open');
    expect(friday.instanceData['goingPersonaIds'], isA<List<Object?>>());
    expect(
      (friday.instanceData['goingPersonaIds'] as List<Object?>).length,
      12,
    );
  });

  test('2 absent stamp preserves the legacy shallow projection', () {
    final experience = experienceForExtensionId(
      'a4-legacy-absent',
      experienceConfiguration: _legacyExperience(),
    );
    expect(_legacyProjection(experience), <Object?>[
      'Legacy Tabletop',
      <Object?>[
        <Object?>[
          'legacy-roster',
          'Volunteer roster',
          'Choose a shift.',
          'Sign up.',
          'Reserved.',
        ],
      ],
      <String>['legacy-member'],
      null,
      null,
    ]);
  });

  test('3 explicit legacy version matches absent-stamp legacy parsing', () {
    final absent = experienceForExtensionId(
      'a4-legacy-absent-comparison',
      experienceConfiguration: _legacyExperience(),
    );
    final explicit = experienceForExtensionId(
      'a4-legacy-explicit',
      experienceConfiguration: _legacyExperience(version: 1),
    );
    expect(_legacyProjection(explicit), _legacyProjection(absent));
  });

  test('4 unsupported experience version throws FormatException', () {
    final config = _legacyExperience(version: 99);
    expect(
      () => experienceForExtensionId(
        'a4-unsupported-experience',
        experienceConfiguration: config,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('5 unsupported v2 grammar version throws FormatException', () {
    expect(
      () => experienceForExtensionId(
        'a4-unsupported-grammar',
        experienceConfiguration: _v2Experience(grammarVersion: 99),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    '6 malformed v2 definition is skipped while valid definition remains',
    () {
      final config = _v2Experience();
      final definitions = config['workflowDefinitions'] as Map<String, Object?>;
      definitions['malformed'] = <String, Object?>{
        'states': <String, Object?>{},
      };
      final experience = experienceForExtensionId(
        'a4-malformed-definition',
        experienceConfiguration: config,
      );
      expect(experience.workflowDefinitions!.keys, <String>['valid']);
    },
  );

  test(
    '7 v2 ignores absent legacy workflows and returns engine-native content',
    () {
      final config = _v2Experience()..remove('workflows');
      final experience = experienceForExtensionId(
        'a4-no-legacy-workflows',
        experienceConfiguration: config,
      );
      expect(experience.workflowDefinitions, isNotNull);
      expect(experience.workflowDefinitions!.keys, <String>['valid']);
      expect(experience.workflowInstances, hasLength(1));
    },
  );
}
