import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

const _tabletopRelativePath =
    'docs/references/communities/'
    'Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';
const _legacyRelativePath =
    'docs/Build Plan V2/Skill/examples/verify-tabletop-club/'
    'loom.initialization.json';

File _repositoryFile(String relativePath) {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final file = File('${directory.path}/$relativePath');
    if (file.existsSync()) return file;
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError('Fixture not found: $relativePath');
}

Map<String, Object?> _tabletopExperience() {
  final package =
      jsonDecode(
            stripJsonComments(
              _repositoryFile(_tabletopRelativePath).readAsStringSync(),
            ),
          )
          as Map<String, dynamic>;
  return Map<String, Object?>.from(package['experience'] as Map);
}

Map<String, Object?> _legacyExperience() {
  final package =
      jsonDecode(_repositoryFile(_legacyRelativePath).readAsStringSync())
          as Map<String, dynamic>;
  return Map<String, Object?>.from(package['experience'] as Map);
}

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
    expect(instances, hasLength(20));
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
      'Tabletop Club',
      <Object?>[
        <Object?>[
          'tabletop-game-night-rsvp',
          'RSVP to Friday game night',
          'Friday game night at the community room, 7-10pm. 12 of 20 seats filled.',
          "Reserve a seat at Friday's game night.",
          "You're on the roster for Friday's game night.",
        ],
        <Object?>[
          'tabletop-tournament-rsvp',
          'RSVP to the afternoon tournament',
          'Summer tournament earlier the same day, 1-5pm. 8 of 16 brackets claimed.',
          'Claim a bracket in the summer tournament.',
          'Your bracket is reserved for the summer tournament.',
        ],
        <Object?>[
          'tabletop-committee-decision',
          'Decide on new game purchase',
          'A member proposed buying a copy of Wingspan for the club library.',
          'Decide on the Wingspan purchase proposal.',
          'Decision recorded for the Wingspan proposal.',
        ],
        <Object?>[
          'tabletop-game-loan',
          'Borrow a game from the club library',
          'Catan is available in the club game library.',
          'Request to borrow Catan for two weeks.',
          'Your loan request for Catan was sent to the organizer.',
        ],
        <Object?>[
          'tabletop-club-dues-payment',
          'Pay quarterly club dues',
          'Quarterly dues of \$15 are due by the end of the month.',
          'Pay \$15 in quarterly dues.',
          'Dues payment recorded and receipt saved.',
        ],
        <Object?>[
          'tabletop-meetup-announcement',
          'Publish game night announcement',
          "Draft: 'Friday game night moves to the larger room starting next week.'",
          'Publish the game night announcement to all members.',
          'Announcement published to all Tabletop Club members.',
        ],
      ],
      <String>['tabletop-organizer', 'tabletop-member'],
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
      experienceConfiguration: _legacyExperience()
        ..['experienceSchemaVersion'] = 1,
    );
    expect(_legacyProjection(explicit), _legacyProjection(absent));
  });

  test('4 unsupported experience version throws FormatException', () {
    final config = _legacyExperience()..['experienceSchemaVersion'] = 99;
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
