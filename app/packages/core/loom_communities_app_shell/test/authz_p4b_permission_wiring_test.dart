import 'dart:convert';
import 'dart:io';

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
        'schemaVersion': 1,
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
    },
    transitions: transitions,
    renderBindings: [
      RenderBinding(
        states: const ['open'],
        role: 'any',
        tabId: tabId,
        cardSurfaceFamily: 'workflow-status',
        bindingKind: 'primary',
      ),
    ],
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
  test('personaHasPermission allows public read permissions', () {
    final experience = _experience({
      'public-workflow': _machine(
        workflowType: 'public-workflow',
        tabId: 'calendar',
        visibility: const WorkflowVisibility(isDeclared: false),
      ),
    });

    expect(
      personaHasPermission(
        experience,
        'outsider',
        'community.surface.calendar.read',
        tabId: 'calendar',
      ),
      isTrue,
    );
  });

  test('personaHasPermissionAsync reuses active membership lookup', () async {
    final experience = _experience({
      'members-workflow': _machine(
        workflowType: 'members-workflow',
        tabId: 'calendar',
        visibility: const WorkflowVisibility(
          defaultValue: WorkflowVisibilityDefault.membersOnly,
        ),
      ),
    });

    expect(
      await personaHasPermissionAsync(
        experience,
        'member',
        'community.surface.calendar.read',
        tabId: 'calendar',
        activeMembershipLookup: (_) => true,
      ),
      isTrue,
    );
    expect(
      await personaHasPermissionAsync(
        experience,
        'outsider',
        'community.surface.calendar.read',
        tabId: 'calendar',
        activeMembershipLookup: (_) => false,
      ),
      isFalse,
    );
  });

  test('personaHasPermission evaluates guarded read admissibility', () {
    final experience = _experience({
      'guarded-workflow': _machine(
        workflowType: 'guarded-workflow',
        tabId: 'calendar',
        visibility: const WorkflowVisibility(
          defaultValue: WorkflowVisibilityDefault.guarded,
          readGuard: WorkflowGuard(allowedPersonaIds: ['member']),
        ),
      ),
    });

    expect(
      personaHasPermission(
        experience,
        'member',
        'community.surface.calendar.read',
        tabId: 'calendar',
      ),
      isTrue,
    );
    expect(
      personaHasPermission(
        experience,
        'outsider',
        'community.surface.calendar.read',
        tabId: 'calendar',
      ),
      isFalse,
    );
  });

  test('guarded field principals admit potentially owned rows', () {
    final experience = _experience({
      'party-workflow': _machine(
        workflowType: 'party-workflow',
        tabId: 'home',
        visibility: const WorkflowVisibility(
          defaultValue: WorkflowVisibilityDefault.guarded,
          readGuard: WorkflowGuard(allowedPersonaIds: ['organizer']),
          fields: WorkflowVisibilityFields(
            parties: [
              WorkflowVisibilityFieldPrincipal(fieldName: 'ownerFanId'),
              WorkflowVisibilityRolePrincipal(roleId: 'organizer'),
            ],
          ),
        ),
      ),
    });

    expect(
      personaHasPermission(
        experience,
        'member',
        'community.surface.navigation.read',
        workflowType: 'party-workflow',
      ),
      isTrue,
    );
  });

  test(
    'personaHasPermission derives configure access from transition, edit, and creation guards',
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
      });

      expect(
        personaHasPermission(
          experience,
          'transition-persona',
          'community.surface.navigation.configure',
          tabId: 'admin',
        ),
        isTrue,
      );
      expect(
        personaHasPermission(
          experience,
          'edit-persona',
          'community.surface.navigation.configure',
          tabId: 'admin',
        ),
        isTrue,
      );
      expect(
        personaHasPermission(
          experience,
          'creation-persona',
          'community.surface.navigation.configure',
          tabId: 'admin',
        ),
        isTrue,
      );
      expect(
        personaHasPermission(
          experience,
          'outsider',
          'community.surface.navigation.configure',
          tabId: 'admin',
        ),
        isFalse,
      );
    },
  );

  test(
    'declarative tabs use computed permission fallback while package tabs keep explicit role lists',
    () {
      final declarativeExperience = _experience({
        'private-workflow': _machine(
          workflowType: 'private-workflow',
          tabId: 'private-surface',
          visibility: const WorkflowVisibility(
            defaultValue: WorkflowVisibilityDefault.guarded,
            readGuard: WorkflowGuard(allowedPersonaIds: ['member']),
          ),
        ),
      });
      const appShellConfiguration = <String, Object?>{
        'tabs': [
          {
            'tabId': 'private-surface',
            'label': 'Private surface',
            'icon': 'documents',
            'rendererContractId': 'documents-library-detail',
            'requiredPermission': 'community.surface.workflow.read',
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
                'community.surface.workflow.read',
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
