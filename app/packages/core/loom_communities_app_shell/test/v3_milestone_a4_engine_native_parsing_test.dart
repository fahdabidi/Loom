import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
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

typedef _PackageExperience = ({
  Map<String, Object?> experience,
  int? specVersion,
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
    specVersion: package['specVersion'] as int?,
  );
}

_PackageExperience _legacyPackage() {
  final package =
      jsonDecode(_repositoryFile(_legacyRelativePath).readAsStringSync())
          as Map<String, dynamic>;
  return (
    experience: Map<String, Object?>.from(package['experience'] as Map),
    specVersion: package['specVersion'] as int?,
  );
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

Map<String, Object?> _minimalPackageExperience({required bool v4}) {
  final experience = _v2Experience();
  final identity = <String, Object?>{
    if (v4) 'roleId': 'community-member',
    if (!v4) 'personaId': 'community-member',
    'label': 'Community Member',
    'roleLabel': 'Member',
    'description': 'Uses community workflows.',
  };
  if (v4) {
    experience
      ..remove('experienceSchemaVersion')
      ..remove('workflowGrammarVersion')
      ..['roles'] = <Object?>[identity];
  } else {
    experience['personas'] = <Object?>[identity];
  }
  return experience;
}

_LocalPackagePair _writeLocalPackagePair({required int? specVersion}) {
  final suffix = specVersion == null ? 'legacy' : 'v$specVersion';
  final extensionId = 'a4-local-$suffix';
  final directory = Directory.systemTemp.createTempSync('loom_a4_$suffix');
  final extensionFile = File(
    '${directory.path}/community.loom-extension.zip',
  );
  final initializationFile = File(
    '${directory.path}/community.loom-init.zip',
  );
  extensionFile.writeAsStringSync(
    jsonEncode(<String, Object?>{
      if (specVersion == null) 'schemaVersion': 1,
      if (specVersion != null) 'specVersion': specVersion,
      'extensionId': extensionId,
      'displayName': 'Minimal Community',
      'version': '1.0.0',
      'permissions': <Object?>[],
      'assets': <Object?>[],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode(<String, Object?>{
      if (specVersion == null) 'schemaVersion': 1,
      if (specVersion != null) 'specVersion': specVersion,
      'communityId': 'community-$suffix',
      'displayName': 'Minimal Community',
      'extensionId': extensionId,
      'seedDataFiles': <Object?>[],
      'experience': _minimalPackageExperience(v4: specVersion == 4),
    }),
  );
  return _LocalPackagePair(
    directory: directory,
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}

class _LocalPackagePair {
  const _LocalPackagePair({
    required this.directory,
    required this.extensionPath,
    required this.initializationPath,
  });

  final Directory directory;
  final String extensionPath;
  final String initializationPath;
}

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
  test('legacy and v4 local package pairs load to the same representation', () {
    final legacyFiles = _writeLocalPackagePair(specVersion: null);
    final v4Files = _writeLocalPackagePair(specVersion: 4);
    addTearDown(() {
      legacyFiles.directory.deleteSync(recursive: true);
      v4Files.directory.deleteSync(recursive: true);
    });

    final legacyBackend = LocalInAppBackend();
    final v4Backend = LocalInAppBackend();
    final legacyPlan = legacyBackend.parseLocalPackagePair(
      extensionPackagePath: legacyFiles.extensionPath,
      initializationPackagePath: legacyFiles.initializationPath,
    );
    final v4Plan = v4Backend.parseLocalPackagePair(
      extensionPackagePath: v4Files.extensionPath,
      initializationPackagePath: v4Files.initializationPath,
    );
    final legacyCommunity = legacyBackend
        .installLocalPackagePairFromFiles(
          extensionPackagePath: legacyFiles.extensionPath,
          initializationPackagePath: legacyFiles.initializationPath,
        )
        .community;
    final v4Community = v4Backend
        .installLocalPackagePairFromFiles(
          extensionPackagePath: v4Files.extensionPath,
          initializationPackagePath: v4Files.initializationPath,
        )
        .community;
    final legacy = experienceForExtensionId(
      legacyCommunity.extensionId,
      displayName: legacyCommunity.displayName,
      specVersion: legacyCommunity.specVersion,
      experienceConfiguration: legacyCommunity.experienceConfiguration,
    );
    final v4 = experienceForExtensionId(
      v4Community.extensionId,
      displayName: v4Community.displayName,
      specVersion: v4Community.specVersion,
      experienceConfiguration: v4Community.experienceConfiguration,
    );

    expect(legacyPlan.specVersion, isNull);
    expect(legacyCommunity.specVersion, isNull);
    expect(v4Plan.specVersion, 4);
    expect(v4Community.specVersion, 4);
    expect(legacy.workflowDefinitions!.keys, <String>['valid']);
    expect(v4.workflowDefinitions!.keys, legacy.workflowDefinitions!.keys);
    expect(legacy.workflowInstances, hasLength(1));
    expect(v4.workflowInstances, hasLength(1));
    expect(legacy.personas!.single.personaId, 'community-member');
    expect(v4.personas!.single.personaId, legacy.personas!.single.personaId);
    expect(v4.personas!.single.label, legacy.personas!.single.label);
    expect(v4.personas!.single.roleLabel, legacy.personas!.single.roleLabel);
  });

  test('tab visibility accepts legacy and v4 role keys identically', () {
    final experience = experienceForExtensionId('a4-tab-visibility-alias');
    Map<String, Object?> shell(String visibilityKey) => <String, Object?>{
      'tabs': <Object?>[
        <String, Object?>{
          'tabId': 'role-only',
          'label': 'Role only',
          visibilityKey: <Object?>['community-member'],
        },
      ],
    };

    List<String> tabIdsFor(
      String personaId,
      Map<String, Object?> configuration,
    ) => appShellTabsFor(
      experience: experience,
      personaId: personaId,
      appShellConfiguration: configuration,
    ).map((tab) => tab.tabId).toList();

    final legacyVisible = tabIdsFor(
      'community-member',
      shell('visiblePersonaIds'),
    );
    final v4Visible = tabIdsFor(
      'community-member',
      shell('visibleRoleIds'),
    );
    final legacyHidden = tabIdsFor('other-role', shell('visiblePersonaIds'));
    final v4Hidden = tabIdsFor('other-role', shell('visibleRoleIds'));

    expect(legacyVisible, contains('role-only'));
    expect(v4Visible, legacyVisible);
    expect(legacyHidden, isNot(contains('role-only')));
    expect(v4Hidden, legacyHidden);
  });

  test('1 parses the real Tabletop engine-native package completely', () {
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
    expect(instances, hasLength(33));
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
          .map((entry) => <String?>[
                entry.kind,
                entry.token,
                entry.formula,
                entry.style,
                entry.colorSource,
              ])
          .toList(),
      <List<String?>>[
        <String?>['dateToken', 'weekdayAbbrev', null, 'label', null],
        <String?>[
          'dateToken',
          'dayOfMonth',
          null,
          'circleHighlight',
          'accent',
        ],
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
      experienceConfiguration: _v2Experience()
        ..['notificationPresentation'] = <String, Object?>{'style': 'fab'},
    );
    expect(configured.notificationPresentation?.style, 'fab');
    expect(configured.resolvedNotificationPresentationStyle, 'fab');

    final absent = experienceForExtensionId(
      'a4-notification-presentation-absent',
      experienceConfiguration: _v2Experience(),
    );
    expect(absent.notificationPresentation, isNull);
    expect(absent.resolvedNotificationPresentationStyle, 'bell');
  });

  test('persona accessMode parses all values and defaults to open', () {
    final config = _v2Experience()
      ..['personas'] = <Object?>[
        <String, Object?>{
          'personaId': 'open-persona',
          'label': 'Open',
          'roleLabel': 'Member',
          'description': 'Open access',
          'accessMode': 'open',
        },
        <String, Object?>{
          'personaId': 'approval-persona',
          'label': 'Approval',
          'roleLabel': 'Member',
          'description': 'Approval access',
          'accessMode': 'requiresApproval',
        },
        <String, Object?>{
          'personaId': 'invite-persona',
          'label': 'Invite',
          'roleLabel': 'Member',
          'description': 'Invite access',
          'accessMode': 'requiresInvite',
        },
        <String, Object?>{
          'personaId': 'default-persona',
          'label': 'Default',
          'roleLabel': 'Member',
          'description': 'Default access',
        },
      ];

    final personas = experienceForExtensionId(
      'a4-persona-access-mode',
      experienceConfiguration: config,
    ).personas!;

    expect(
      personas.map((persona) => persona.accessMode),
      <LoomPersonaAccessMode>[
        LoomPersonaAccessMode.open,
        LoomPersonaAccessMode.requiresApproval,
        LoomPersonaAccessMode.requiresInvite,
        LoomPersonaAccessMode.open,
      ],
    );
  });

  test('invalid persona accessMode fails with a clear FormatException', () {
    final config = _v2Experience()
      ..['personas'] = <Object?>[
        <String, Object?>{
          'personaId': 'invalid-persona',
          'label': 'Invalid',
          'roleLabel': 'Member',
          'description': 'Invalid access',
          'accessMode': 'approvalRequired',
        },
      ];

    expect(
      () => experienceForExtensionId(
        'a4-invalid-persona-access-mode',
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

  test('legacy notification presentation parses for both schema paths', () {
    final package = _legacyPackage();
    final experience = experienceForExtensionId(
      'a4-legacy-notification-presentation',
      specVersion: package.specVersion,
      experienceConfiguration: package.experience
        ..['notificationPresentation'] = <String, Object?>{
          'style': 'dedicatedTab',
        },
    );
    expect(experience.notificationPresentation?.style, 'dedicatedTab');
  });

  test('2 absent stamp preserves the legacy shallow projection', () {
    final package = _legacyPackage();
    final experience = experienceForExtensionId(
      'a4-legacy-absent',
      specVersion: package.specVersion,
      experienceConfiguration: package.experience,
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
    final absentPackage = _legacyPackage();
    final absent = experienceForExtensionId(
      'a4-legacy-absent-comparison',
      specVersion: absentPackage.specVersion,
      experienceConfiguration: absentPackage.experience,
    );
    final explicitPackage = _legacyPackage();
    final explicit = experienceForExtensionId(
      'a4-legacy-explicit',
      specVersion: explicitPackage.specVersion,
      experienceConfiguration: explicitPackage.experience
        ..['experienceSchemaVersion'] = 1,
    );
    expect(_legacyProjection(explicit), _legacyProjection(absent));
  });

  test('4 unsupported experience version throws FormatException', () {
    final package = _legacyPackage();
    final config = package.experience..['experienceSchemaVersion'] = 99;
    expect(
      () => experienceForExtensionId(
        'a4-unsupported-experience',
        specVersion: package.specVersion,
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
      expect(experience.calendarDateRailEntries, isNull);
    },
  );
}
