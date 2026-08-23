import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _tabletopRelativePath =
    'docs/references/communities/'
    'Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

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

typedef _PackageExperience = ({
  Map<String, Object?> experience,
  int specVersion,
});

_PackageExperience _tabletopPackage() {
  final package =
      jsonDecode(
            stripJsonComments(
              _repositoryFile(_tabletopRelativePath).readAsStringSync(),
            ),
          )
          as Map<String, dynamic>;
  return (
    experience: Map<String, Object?>.from(package['experience'] as Map),
    specVersion: package['specVersion'] as int,
  );
}

Map<String, Object?> _v4Experience() => <String, Object?>{
  'roles': <Object?>[
    <String, Object?>{
      'roleId': 'community-member',
      'label': 'Community Member',
      'roleLabel': 'Member',
      'description': 'Uses community workflows.',
    },
  ],
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
      'createdByFanId': 'fan-one',
      'instanceData': <String, Object?>{},
    },
  ],
};

void main() {
  test('parses the real Tabletop engine-native package completely', () {
    final package = _tabletopPackage();
    final experience = experienceForExtensionId(
      'a4-tabletop-real-fixture',
      specVersion: package.specVersion,
      experienceConfiguration: package.experience,
    );
    final definitions = experience.workflowDefinitions;
    final instances = experience.workflowInstances;

    expect(definitions, isNotNull);
    expect(experience.notificationPresentation?.style, 'bell');
    expect(experience.resolvedNotificationPresentationStyle, 'bell');
    expect(
      definitions!.keys,
      unorderedEquals(<String>[
        'event-rsvp',
        'event-rsvp-response',
        'tournament-event',
        'tournament-ballot',
        'tournament-vote',
        'notification',
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
    expect(instances, hasLength(34));
    expect(
      definitions['event-rsvp']!.states.keys,
      containsAll(<String>['open', 'cancelled']),
    );
    expect(definitions['event-rsvp']!.transitions.map((t) => t.id), <String>[
      'cancel-event',
      'make-recurring',
    ]);
    final friday = instances!.singleWhere(
      (instance) => instance.instanceId == 'event-friday-game-night',
    );
    expect(friday.currentState, 'open');
    expect(experience.calendarDateRailEntries, hasLength(3));
    expect(
      experience.calendarDateRailEntries!
          .map(
            (entry) => <String?>[
              entry.kind,
              entry.token,
              entry.formula,
              entry.style,
              entry.colorSource,
            ],
          )
          .toList(),
      <List<String?>>[
        <String?>['dateToken', 'weekdayAbbrev', null, 'label', null],
        <String?>['dateToken', 'dayOfMonth', null, 'circleHighlight', 'accent'],
        <String?>[
          'formula',
          null,
          'count(dayInstances)',
          'badge',
          'styleField',
        ],
      ],
    );
  });

  test('engine-native notification presentation parses and defaults', () {
    final configured = experienceForExtensionId(
      'a4-notification-presentation-fab',
      specVersion: currentCommunitySpecVersion,
      experienceConfiguration: _v4Experience()
        ..['notificationPresentation'] = <String, Object?>{'style': 'fab'},
    );
    expect(configured.notificationPresentation?.style, 'fab');
    expect(configured.resolvedNotificationPresentationStyle, 'fab');

    final absent = experienceForExtensionId(
      'a4-notification-presentation-absent',
      specVersion: currentCommunitySpecVersion,
      experienceConfiguration: _v4Experience(),
    );
    expect(absent.notificationPresentation, isNull);
    expect(absent.resolvedNotificationPresentationStyle, 'bell');
  });

  test('role accessMode parses all values and defaults to open', () {
    final config = _v4Experience()
      ..['roles'] = <Object?>[
        <String, Object?>{
          'roleId': 'open-role',
          'label': 'Open',
          'roleLabel': 'Member',
          'description': 'Open access',
          'accessMode': 'open',
        },
        <String, Object?>{
          'roleId': 'approval-role',
          'label': 'Approval',
          'roleLabel': 'Member',
          'description': 'Approval access',
          'accessMode': 'requiresApproval',
        },
        <String, Object?>{
          'roleId': 'invite-role',
          'label': 'Invite',
          'roleLabel': 'Member',
          'description': 'Invite access',
          'accessMode': 'requiresInvite',
        },
        <String, Object?>{
          'roleId': 'default-role',
          'label': 'Default',
          'roleLabel': 'Member',
          'description': 'Default access',
        },
      ];

    final roles = experienceForExtensionId(
      'a4-role-access-mode',
      specVersion: currentCommunitySpecVersion,
      experienceConfiguration: config,
    ).actorIdentities!;

    expect(roles.map((role) => role.accessMode), <LoomActorIdentityAccessMode>[
      LoomActorIdentityAccessMode.open,
      LoomActorIdentityAccessMode.requiresApproval,
      LoomActorIdentityAccessMode.requiresInvite,
      LoomActorIdentityAccessMode.open,
    ]);
  });

  test('invalid role accessMode fails with a clear FormatException', () {
    final config = _v4Experience()
      ..['roles'] = <Object?>[
        <String, Object?>{
          'roleId': 'invalid-role',
          'label': 'Invalid',
          'roleLabel': 'Member',
          'description': 'Invalid access',
          'accessMode': 'approvalRequired',
        },
      ];

    expect(
      () => experienceForExtensionId(
        'a4-invalid-role-access-mode',
        specVersion: currentCommunitySpecVersion,
        experienceConfiguration: config,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(contains('accessMode'), contains('requiresInvite')),
        ),
      ),
    );
  });

  test('malformed v4 definition is skipped while valid definition remains', () {
    final config = _v4Experience();
    final definitions = config['workflowDefinitions'] as Map<String, Object?>;
    definitions['malformed'] = <String, Object?>{'states': <String, Object?>{}};
    final experience = experienceForExtensionId(
      'a4-malformed-definition',
      specVersion: currentCommunitySpecVersion,
      experienceConfiguration: config,
    );
    expect(experience.workflowDefinitions!.keys, <String>['valid']);
  });

  test('v4 ignores absent shallow workflows and returns engine content', () {
    final config = _v4Experience()..remove('workflows');
    final experience = experienceForExtensionId(
      'a4-no-shallow-workflows',
      specVersion: currentCommunitySpecVersion,
      experienceConfiguration: config,
    );
    expect(experience.workflowDefinitions, isNotNull);
    expect(experience.workflowDefinitions!.keys, <String>['valid']);
    expect(experience.workflowInstances, hasLength(1));
    expect(experience.calendarDateRailEntries, isNull);
  });

  test('missing or unsupported specVersion is rejected', () {
    expect(
      () => experienceForExtensionId(
        'a4-missing-version',
        specVersion: null,
        experienceConfiguration: _v4Experience(),
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => experienceForExtensionId(
        'a4-unsupported-version',
        specVersion: currentCommunitySpecVersion - 1,
        experienceConfiguration: _v4Experience(),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
