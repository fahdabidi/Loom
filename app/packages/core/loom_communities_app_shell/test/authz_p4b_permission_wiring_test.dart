import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _youthSoccerFixture =
    'docs/references/communities/Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc';

({LocalInstalledCommunity community, LoomExperienceDefinition experience})
_installYouthSoccerFixture() {
  var directory = Directory.current;
  File? fixture;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$_youthSoccerFixture');
    if (candidate.existsSync()) {
      fixture = candidate;
      break;
    }
    directory = directory.parent;
  }
  if (fixture == null) {
    throw StateError('Could not locate fixture: $_youthSoccerFixture');
  }

  final source =
      jsonDecode(stripJsonComments(fixture.readAsStringSync()))
          as Map<String, dynamic>;
  final extensionId = source['extensionId'] as String;
  final temp = Directory.systemTemp.createTempSync('loom-authz-p4b-');
  try {
    final extension = File('${temp.path}/$extensionId.loom-extension.zip');
    final initialization = File('${temp.path}/$extensionId.loom-init.zip');
    extension.writeAsStringSync(
      jsonEncode(<String, Object?>{
        'specVersion': currentCommunitySpecVersion,
        'extensionId': extensionId,
        'displayName': source['displayName'],
        'version': '1.0.0',
        'mode': 'local-demo',
        'permissions': <String>[],
      }),
    );
    initialization.writeAsStringSync(jsonEncode(source));
    final community = LocalInAppBackend()
        .installLocalPackagePairFromFiles(
          extensionPackagePath: extension.path,
          initializationPackagePath: initialization.path,
        )
        .community;
    final experience = experienceForExtensionId(
      community.extensionId,
      displayName: community.displayName,
      specVersion: community.specVersion,
      experienceConfiguration: community.experienceConfiguration,
    );
    return (community: community, experience: experience);
  } finally {
    temp.deleteSync(recursive: true);
  }
}

LoomWorkflowStateMachine _machine({
  required String workflowType,
  required String tabId,
  WorkflowVisibility visibility = const WorkflowVisibility(isDeclared: false),
  WorkflowGuard? readGuard,
  WorkflowGuard? editGuard,
  WorkflowGuard? creationGuard,
  List<LoomWorkflowTransition> transitions = const [],
  List<WorkflowAction> actions = const [],
  Map<String, LoomWorkflowState> additionalStates = const {},
  ResponseTableSpec? responseTable,
  bool bindToTab = true,
}) {
  return LoomWorkflowStateMachine(
    workflowType: workflowType,
    initialState: 'open',
    states: {
      'open': LoomWorkflowState(
        label: 'Open',
        readGuard: readGuard,
        editGuard: editGuard,
        creationGuard: creationGuard,
      ),
      ...additionalStates,
    },
    transitions: transitions,
    renderBindings: bindToTab
        ? [
            RenderBinding(
              states: const ['open'],
              role: 'any',
              tabId: tabId,
              cardSurfaceFamily: 'workflow-status',
              bindingKind: 'primary',
              actions: actions,
              responseTable: responseTable,
            ),
          ]
        : const [],
    visibility: visibility,
  );
}

LoomExperienceDefinition _experience(
  Map<String, LoomWorkflowStateMachine> definitions,
) {
  return LoomExperienceDefinition(
    extensionId: 'authz-p4b-test',
    displayName: 'AuthZ P4b Test Community',
    tagline: 'Permission test fixture',
    accentColor: 0xff246b62,
    workflows: const [],
    personas: const [
      LoomPersonaDefinition(
        personaId: 'member',
        label: 'Member',
        roleLabel: 'Member',
        description: 'Member',
      ),
      LoomPersonaDefinition(
        personaId: 'outsider',
        label: 'Outsider',
        roleLabel: 'Outsider',
        description: 'Outsider',
      ),
    ],
    workflowDefinitions: definitions,
  );
}

void main() {
  test('personaHasPermission derives visibility from transition roles', () {
    final experience = _experience({
      'calendar-workflow': _machine(
        workflowType: 'calendar-workflow',
        tabId: 'calendar',
        transitions: const [
          LoomWorkflowTransition(
            id: 'publish',
            label: 'Publish',
            from: ['open'],
            to: 'open',
            guard: WorkflowGuard(allowedPersonaIds: ['member']),
          ),
        ],
      ),
    });

    expect(
      personaHasPermission(experience, 'member', tabId: 'calendar'),
      isTrue,
    );
    expect(
      personaHasPermission(experience, 'outsider', tabId: 'calendar'),
      isFalse,
    );
  });

  test('personaHasPermission derives visibility from create-action roles', () {
    final experience = _experience({
      'creatable-workflow': _machine(
        workflowType: 'creatable-workflow',
        tabId: 'calendar',
        actions: const [
          WorkflowAction(kind: 'create', byPersonaIds: ['member']),
        ],
      ),
    });

    expect(
      personaHasPermission(experience, 'member', tabId: 'calendar'),
      isTrue,
    );
    expect(
      personaHasPermission(experience, 'outsider', tabId: 'calendar'),
      isFalse,
    );
  });

  test('personaHasPermission follows responseTable workflow roles', () {
    final experience = _experience({
      'event': _machine(
        workflowType: 'event',
        tabId: 'calendar',
        transitions: const [
          LoomWorkflowTransition(
            id: 'cancel',
            label: 'Cancel',
            from: ['open'],
            to: 'open',
            guard: WorkflowGuard(allowedPersonaIds: ['outsider']),
          ),
        ],
        responseTable: const ResponseTableSpec(
          workflowType: 'event-response',
          eventField: 'eventId',
          pendingStates: ['open'],
        ),
      ),
      'event-response': _machine(
        workflowType: 'event-response',
        tabId: 'not-directly-bound',
        bindToTab: false,
        transitions: const [
          LoomWorkflowTransition(
            id: 'respond',
            label: 'Respond',
            from: ['open'],
            to: 'open',
            guard: WorkflowGuard(allowedPersonaIds: ['member']),
          ),
        ],
      ),
    });

    expect(
      personaHasPermission(experience, 'member', tabId: 'calendar'),
      isTrue,
    );
    expect(
      personaHasPermission(experience, 'outsider', tabId: 'calendar'),
      isTrue,
    );
  });

  test(
    'runtime-only or unguarded transitions prevent other role guards vetoing',
    () {
      final runtimeGuardedExperience = _experience({
        'mixed-workflow': _machine(
          workflowType: 'mixed-workflow',
          tabId: 'mixed',
          transitions: const [
            LoomWorkflowTransition(
              id: 'member-action',
              label: 'Member action',
              from: ['open'],
              to: 'open',
              guard: WorkflowGuard(allowedPersonaIds: ['member']),
            ),
            LoomWorkflowTransition(
              id: 'owned-action',
              label: 'Owned action',
              from: ['open'],
              to: 'open',
              guard: WorkflowGuard(
                actorEqualsField: ActorEqualsFieldGuard(key: 'ownerFanId'),
              ),
            ),
          ],
        ),
      });
      final unguardedExperience = _experience({
        'mixed-workflow': _machine(
          workflowType: 'mixed-workflow',
          tabId: 'mixed',
          transitions: const [
            LoomWorkflowTransition(
              id: 'member-action',
              label: 'Member action',
              from: ['open'],
              to: 'open',
              guard: WorkflowGuard(allowedPersonaIds: ['member']),
            ),
            LoomWorkflowTransition(
              id: 'open-action',
              label: 'Open action',
              from: ['open'],
              to: 'open',
              guard: WorkflowGuard(),
            ),
          ],
        ),
      });

      expect(
        personaHasPermission(
          runtimeGuardedExperience,
          'outsider',
          tabId: 'mixed',
        ),
        isTrue,
      );
      expect(
        personaHasPermission(unguardedExperience, 'outsider', tabId: 'mixed'),
        isTrue,
      );
    },
  );

  test(
    'personaHasPermission ignores read visibility and uses any transition',
    () {
      final experience = _experience({
        'guarded-workflow': _machine(
          workflowType: 'guarded-workflow',
          tabId: 'calendar',
          visibility: const WorkflowVisibility(
            defaultValue: WorkflowVisibilityDefault.guarded,
            readGuard: WorkflowGuard(allowedPersonaIds: ['outsider']),
          ),
          additionalStates: const {
            'not-rendered': LoomWorkflowState(label: 'Not rendered'),
          },
          transitions: const [
            LoomWorkflowTransition(
              id: 'publish',
              label: 'Publish',
              from: ['not-rendered'],
              to: 'not-rendered',
              guard: WorkflowGuard(allowedPersonaIds: ['member']),
            ),
          ],
        ),
      });

      expect(
        personaHasPermission(experience, 'member', tabId: 'calendar'),
        isTrue,
      );
      expect(
        personaHasPermission(experience, 'outsider', tabId: 'calendar'),
        isFalse,
      );
    },
  );

  test('tab visibility enforces derived role guards by default', () {
    final experience = _experience({
      'guarded-workflow': _machine(
        workflowType: 'guarded-workflow',
        tabId: 'private-surface',
        transitions: const [
          LoomWorkflowTransition(
            id: 'publish',
            label: 'Publish',
            from: ['open'],
            to: 'open',
            guard: WorkflowGuard(allowedPersonaIds: ['member']),
          ),
        ],
      ),
    });
    const tab = LoomAppShellTabSpec(
      tabId: 'private-surface',
      label: 'Private surface',
      icon: Icons.folder_open_outlined,
      description: 'Private member content.',
      visiblePersonaIds: ['member', 'outsider'],
    );
    const narrowedTab = LoomAppShellTabSpec(
      tabId: 'private-surface',
      label: 'Narrowed private surface',
      icon: Icons.folder_open_outlined,
      description: 'Explicitly narrowed private member content.',
      visiblePersonaIds: ['outsider'],
    );

    expect(tab.isVisibleFor('member', experience: experience), isTrue);
    expect(tab.isVisibleFor('outsider', experience: experience), isFalse);
    expect(narrowedTab.isVisibleFor('member', experience: experience), isFalse);
    expect(
      tab.isVisibleFor(
        'outsider',
        experience: experience,
        enforceRequiredPermission: false,
      ),
      isTrue,
    );
  });

  test('runtime-only actor guards leave a bound tab visible', () {
    final experience = _experience({
      'party-workflow': _machine(
        workflowType: 'party-workflow',
        tabId: 'owned-items',
        transitions: const [
          LoomWorkflowTransition(
            id: 'update-own-item',
            label: 'Update',
            from: ['open'],
            to: 'open',
            guard: WorkflowGuard(
              actorEqualsField: ActorEqualsFieldGuard(key: 'ownerFanId'),
            ),
          ),
          LoomWorkflowTransition(
            id: 'leave-owned-list',
            label: 'Leave',
            from: ['open'],
            to: 'open',
            guard: WorkflowGuard(
              actorInList: ListMembershipGuard(
                key: 'participantFanIds',
                present: true,
              ),
            ),
          ),
        ],
      ),
    });

    expect(
      personaHasPermission(experience, 'member', tabId: 'owned-items'),
      isTrue,
    );
  });

  test(
    'only transition and create-action role guards derive tab visibility',
    () {
      final experience = _experience({
        'transition-workflow': _machine(
          workflowType: 'transition-workflow',
          tabId: 'admin',
          transitions: [
            const LoomWorkflowTransition(
              id: 'publish',
              label: 'Publish',
              from: const ['open'],
              to: 'published',
              guard: const WorkflowGuard(
                allowedPersonaIds: ['transition-persona'],
                actorEqualsField: ActorEqualsFieldGuard(key: 'ownerFanId'),
              ),
            ),
          ],
        ),
        'edit-workflow': _machine(
          workflowType: 'edit-workflow',
          tabId: 'admin',
          editGuard: const WorkflowGuard(allowedPersonaIds: ['edit-persona']),
        ),
        'creation-workflow': _machine(
          workflowType: 'creation-workflow',
          tabId: 'admin',
          creationGuard: const WorkflowGuard(
            allowedPersonaIds: ['creation-persona'],
          ),
        ),
        'create-action-workflow': _machine(
          workflowType: 'create-action-workflow',
          tabId: 'admin',
          actions: const [
            WorkflowAction(
              kind: 'create',
              byPersonaIds: ['create-action-persona'],
            ),
          ],
        ),
      });

      expect(
        personaHasPermission(experience, 'transition-persona', tabId: 'admin'),
        isTrue,
      );
      expect(
        personaHasPermission(experience, 'edit-persona', tabId: 'admin'),
        isFalse,
      );
      expect(
        personaHasPermission(experience, 'creation-persona', tabId: 'admin'),
        isFalse,
      );
      expect(
        personaHasPermission(
          experience,
          'create-action-persona',
          tabId: 'admin',
        ),
        isTrue,
      );
      expect(
        personaHasPermission(experience, 'outsider', tabId: 'admin'),
        isFalse,
      );
    },
  );

  test(
    'declarative tabs enforce computed permissions and package tabs respect role lists',
    () {
      final declarativeExperience = _experience({
        'private-workflow': _machine(
          workflowType: 'private-workflow',
          tabId: 'private-surface',
          visibility: const WorkflowVisibility(
            defaultValue: WorkflowVisibilityDefault.guarded,
            readGuard: WorkflowGuard(allowedPersonaIds: ['member']),
          ),
          transitions: const [
            LoomWorkflowTransition(
              id: 'publish',
              label: 'Publish',
              from: ['open'],
              to: 'open',
              guard: WorkflowGuard(allowedPersonaIds: ['member']),
            ),
          ],
        ),
      });
      const appShellConfiguration = <String, Object?>{
        'tabs': [
          {
            'tabId': 'private-surface',
            'label': 'Private surface',
            'icon': 'documents',
            'rendererContractId': 'documents-library-detail',
            // Ad-Free still carries this deferred field. The app shell must
            // ignore it rather than parse it or reject the community.
            'requiredPermission': 'deliberately.not.a.real.permission',
            'permission': 'also.deliberately.ignored',
          },
        ],
      };

      final memberTabs = appShellTabsFor(
        experience: declarativeExperience,
        personaId: 'member',
        appShellConfiguration: appShellConfiguration,
      );
      final outsiderTabs = appShellTabsFor(
        experience: declarativeExperience,
        personaId: 'outsider',
        appShellConfiguration: appShellConfiguration,
      );
      expect(memberTabs.map((tab) => tab.tabId), contains('private-surface'));
      expect(
        outsiderTabs.map((tab) => tab.tabId),
        isNot(contains('private-surface')),
      );

      final installed = _installYouthSoccerFixture();
      final guardianTabs = appShellTabsFor(
        experience: installed.experience,
        personaId: 'soccer-guardian',
        appShellConfiguration: installed.community.appShellConfiguration,
      );
      final coachTabs = appShellTabsFor(
        experience: installed.experience,
        personaId: 'soccer-coach',
        appShellConfiguration: installed.community.appShellConfiguration,
      );
      expect(guardianTabs.map((tab) => tab.tabId), contains('giving'));
      expect(guardianTabs.map((tab) => tab.tabId), isNot(contains('admin')));
      expect(coachTabs.map((tab) => tab.tabId), contains('admin'));
    },
  );

  test('home and messages remain present without derivable role guards', () {
    final experience = _experience(const {});

    final tabs = appShellTabsFor(experience: experience, personaId: 'outsider');

    expect(tabs.map((tab) => tab.tabId), ['home', 'messages']);
  });

  test('an unguarded workflow leaves its custom tab visible', () {
    final experience = _experience({
      'unguarded-workflow': _machine(
        workflowType: 'unguarded-workflow',
        tabId: 'unguarded',
      ),
    });
    const appShellConfiguration = <String, Object?>{
      'tabs': [
        {
          'tabId': 'unguarded',
          'label': 'Unguarded',
          'rendererContractId': 'engine-native-generic-list',
        },
      ],
    };

    final tabs = appShellTabsFor(
      experience: experience,
      personaId: 'member',
      appShellConfiguration: appShellConfiguration,
    );

    expect(
      personaHasPermission(experience, 'member', tabId: 'unguarded'),
      isTrue,
    );
    expect(
      personaHasPermission(experience, 'outsider', tabId: 'unguarded'),
      isTrue,
    );
    expect(tabs.map((tab) => tab.tabId), contains('unguarded'));
  });

  test('a declarative tab with no bound workflow stays public', () {
    final experience = _experience(const {});
    const appShellConfiguration = <String, Object?>{
      'tabs': [
        {
          'tabId': 'static-help',
          'label': 'Help',
          'rendererContractId': 'documents-library-detail',
        },
      ],
    };

    final tabs = appShellTabsFor(
      experience: experience,
      personaId: 'member',
      appShellConfiguration: appShellConfiguration,
    );

    expect(
      personaHasPermission(experience, 'member', tabId: 'static-help'),
      isTrue,
    );
    expect(tabs.map((tab) => tab.tabId), contains('static-help'));
  });

  test(
    'engine boundary re-checks query and transition surface access',
    () async {
      final experience = _experience({
        'private-workflow': _machine(
          workflowType: 'private-workflow',
          tabId: 'private-surface',
          visibility: const WorkflowVisibility(
            defaultValue: WorkflowVisibilityDefault.guarded,
            readGuard: WorkflowGuard(allowedPersonaIds: ['member']),
          ),
          transitions: const [
            LoomWorkflowTransition(
              id: 'publish',
              label: 'Publish',
              from: ['open'],
              to: 'open',
              guard: WorkflowGuard(allowedPersonaIds: ['member']),
            ),
          ],
        ),
      });
      final engine = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'authz-p4b-engine-boundary',
        surfacePermissionLookup:
            ({
              required String personaId,
              String? personaTypeId,
              String? tabId,
              String? workflowType,
            }) {
              return personaHasPermission(
                experience,
                personaId,
                tabId: tabId,
                workflowType: workflowType,
                personaTypeId: personaTypeId,
              );
            },
      );
      engine.registerDefinition(experience.workflowDefinitions!.values.single);

      await expectLater(
        engine.queryInstances(tabId: 'private-surface', personaId: 'outsider'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        engine.applyTransition(
          workflowType: 'private-workflow',
          instanceId: 'missing',
          transitionId: 'publish',
          personaId: 'outsider',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}
