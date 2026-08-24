import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show LoomWorkflowStateMachine;

import 'workflow_ui_test_harness.dart';

void main() {
  group('resolvedRsvpActionIdsForRole', () {
    test('paired event-rsvp resolves member actions from responseTable', () {
      final definitions = <String, LoomWorkflowStateMachine>{
        'club-meeting': _machine('club-meeting', {
          'initialState': 'open',
          'states': {
            'open': {'label': 'Open'},
            'cancelled': {'label': 'Cancelled', 'isTerminal': true},
          },
          'transitions': [
            {
              'id': 'make-recurring',
              'label': 'Repeat this event',
              'from': ['open'],
              'guard': {
                'allowedRoleIds': ['club-organizer'],
              },
            },
            {
              'id': 'cancel-event',
              'label': 'Cancel event',
              'from': ['open'],
              'to': 'cancelled',
              'guard': {
                'allowedRoleIds': ['club-organizer'],
              },
            },
          ],
          'renderBindings': [
            {
              'states': ['open'],
              'audience': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'primary',
              'responseTable': {
                'workflowType': 'club-meeting-response',
                'eventField': 'eventId',
                'pendingStates': ['pending'],
              },
            },
          ],
        }),
        'club-meeting-response': _machine('club-meeting-response', {
          'initialState': 'pending',
          'states': {
            'pending': {'label': 'Pending'},
            'going': {'label': 'Going'},
            'maybe': {'label': 'Maybe'},
            'declined': {'label': 'Declined'},
          },
          'transitions': [
            {
              'id': 'respond-going',
              'label': 'Going',
              'from': ['pending', 'maybe', 'declined'],
              'to': 'going',
              'guard': {
                'allowedRoleIds': ['club-member'],
              },
            },
            {
              'id': 'respond-maybe',
              'label': 'Maybe',
              'from': ['pending', 'going', 'declined'],
              'to': 'maybe',
              'guard': {
                'allowedRoleIds': ['club-member'],
              },
            },
            {
              'id': 'respond-declined',
              'label': 'Not attending',
              'from': ['pending', 'going', 'maybe'],
              'to': 'declined',
              'guard': {
                'allowedRoleIds': ['club-member'],
              },
            },
            {
              'id': 'withdraw-rsvp',
              'label': 'Cancel RSVP',
              'from': ['going'],
              'to': 'pending',
              'guard': {
                'allowedRoleIds': ['club-member'],
              },
            },
          ],
        }),
      };
      final instance = _seedInstance(
        'club-meeting',
        workflowType: 'club-meeting',
        currentState: 'open',
      );

      expect(
        resolvedRsvpActionIdsForRole(
          machine: definitions['club-meeting']!,
          definitions: definitions,
          instance: instance,
          roleId: 'club-member',
        ),
        {'respond-going', 'respond-maybe', 'respond-declined'},
        reason:
            'Member RSVP actions come from the response workflow named by '
            'responseTable.workflowType, never from the organizer-only event '
            'transitions.',
      );

      expect(
        resolvedRsvpActionIdsForRole(
          machine: definitions['club-meeting']!,
          definitions: definitions,
          instance: instance,
          roleId: 'club-organizer',
        ),
        {'make-recurring', 'cancel-event'},
        reason:
            'The organizer still resolves the bound event workflow actions '
            'for the role actually gated to those transitions.',
      );
    });

    test('self event-rsvp resolves member actions from the bound workflow', () {
      final definitions = <String, LoomWorkflowStateMachine>{
        'club-night': _machine('club-night', {
          'initialState': 'open',
          'states': {
            'open': {'label': 'Open'},
            'cancelled': {'label': 'Cancelled', 'isTerminal': true},
          },
          'transitions': [
            {
              'id': 'rsvp-going',
              'label': 'Going',
              'from': ['open'],
              'guard': {
                'allowedRoleIds': ['club-member'],
              },
            },
            {
              'id': 'rsvp-withdraw',
              'label': 'Withdraw',
              'from': ['open'],
              'guard': {
                'allowedRoleIds': ['club-member'],
              },
            },
            {
              'id': 'cancel-club-night',
              'label': 'Cancel club night',
              'from': ['open'],
              'to': 'cancelled',
              'guard': {
                'allowedRoleIds': ['club-organizer'],
              },
            },
          ],
          'renderBindings': [
            {
              'states': ['open'],
              'audience': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'primary',
            },
          ],
        }),
      };
      final instance = _seedInstance(
        'club-night',
        workflowType: 'club-night',
        currentState: 'open',
      );

      expect(
        resolvedRsvpActionIdsForRole(
          machine: definitions['club-night']!,
          definitions: definitions,
          instance: instance,
          roleId: 'club-member',
        ),
        {'rsvp-going', 'rsvp-withdraw'},
        reason:
            'A self-shaped event-rsvp workflow keeps member actions on '
            'the bound workflow itself.',
      );

      expect(
        resolvedRsvpActionIdsForRole(
          machine: definitions['club-night']!,
          definitions: definitions,
          instance: instance,
          roleId: 'club-organizer',
        ),
        {'cancel-club-night'},
        reason:
            'Role gating must not leak organizer actions to members, or '
            'member actions to organizers.',
      );
    });

    test('every shipped RSVP community matches its declared link', () {
      final root = _repositoryRoot();

      final paired = <({String doc, String bound, String memberRoleId})>[
        (
          doc: 'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
          bound: 'garden-event-rsvp',
          memberRoleId: 'garden-member',
        ),
        (
          doc:
              'Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc',
          bound: 'book-meeting-rsvp',
          memberRoleId: 'book-member',
        ),
        (
          doc: 'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
          bound: 'photo-walk-rsvp',
          memberRoleId: 'camera-club-member',
        ),
        (
          doc:
              'Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc',
          bound: 'soccer-practice-schedule',
          memberRoleId: 'soccer-guardian',
        ),
        (
          doc:
              'Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc',
          bound: 'event-rsvp',
          memberRoleId: 'tabletop-member',
        ),
      ];

      for (final row in paired) {
        final experience = _readExperience(
          File('${root.path}/docs/references/communities/${row.doc}'),
        );
        final definitions = _definitions(experience);
        final bound = definitions[row.bound]!;
        final instance = _rawInstance(experience, row.bound);
        final responseWorkflowType = bound.renderBindings
            .firstWhere((binding) => binding.responseTable != null)
            .responseTable!
            .workflowType;
        final responseMachine = definitions[responseWorkflowType]!;

        final expected = <String>{
          ..._roleEligibleIds(bound, instance.currentState, row.memberRoleId),
          ..._roleEligibleIds(
            responseMachine,
            responseMachine.initialState,
            row.memberRoleId,
          ),
        };

        expect(
          resolvedRsvpActionIdsForRole(
            machine: bound,
            definitions: definitions,
            instance: instance,
            roleId: row.memberRoleId,
          ),
          expected,
          reason:
              '${row.bound} must resolve member actions from '
              '$responseWorkflowType, not from ${row.bound}.',
        );
      }

      final selfShaped = <({String doc, String bound, String memberRoleId})>[
        (
          doc: 'Loom_Communities_Workflow_Engine_MasjidNur_Example.jsonc',
          bound: 'mosque-event-rsvp',
          memberRoleId: 'community-member',
        ),
        (
          doc: 'Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc',
          bound: 'hoa-facility-reservation',
          memberRoleId: 'hoa-member',
        ),
        (
          doc:
              'Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc',
          bound: 'tournament-event',
          memberRoleId: 'tabletop-member',
        ),
      ];

      for (final row in selfShaped) {
        final experience = _readExperience(
          File('${root.path}/docs/references/communities/${row.doc}'),
        );
        final definitions = _definitions(experience);
        final bound = definitions[row.bound]!;
        final instance = _rawInstance(experience, row.bound);

        final expected = _roleEligibleIds(
          bound,
          instance.currentState,
          row.memberRoleId,
        );

        expect(
          resolvedRsvpActionIdsForRole(
            machine: bound,
            definitions: definitions,
            instance: instance,
            roleId: row.memberRoleId,
          ),
          expected,
          reason:
              '${row.bound} resolves member actions from its own '
              'transitions because it has no responseTable.',
        );
      }
    });
  });
}

LoomWorkflowStateMachine _machine(
  String workflowType,
  Map<String, dynamic> json,
) {
  return LoomWorkflowStateMachine.fromJson(json, workflowType);
}

LoomWorkflowSeedInstance _seedInstance(
  String instanceId, {
  required String workflowType,
  required String currentState,
}) {
  return LoomWorkflowSeedInstance(
    instanceId: instanceId,
    workflowType: workflowType,
    currentState: currentState,
    instanceData: const {},
    createdByFanId: null,
  );
}

Set<String> _roleEligibleIds(
  LoomWorkflowStateMachine machine,
  String state,
  String roleId,
) {
  return machine
      .transitionsFrom(state)
      .where((transition) {
        final allowed = transition.guard.allowedRoleIds;
        return allowed == null || allowed.isEmpty || allowed.contains(roleId);
      })
      .map((transition) => transition.id)
      .toSet();
}

Map<String, dynamic> _readExperience(File file) {
  final root =
      jsonDecode(stripJsonComments(file.readAsStringSync()))
          as Map<String, dynamic>;
  return root['experience'] as Map<String, dynamic>;
}

Map<String, LoomWorkflowStateMachine> _definitions(
  Map<String, dynamic> experience,
) {
  final raw = experience['workflowDefinitions'] as Map<String, dynamic>;
  return raw.map(
    (workflowType, json) => MapEntry(
      workflowType,
      LoomWorkflowStateMachine.fromJson(
        json as Map<String, dynamic>,
        workflowType,
      ),
    ),
  );
}

LoomWorkflowSeedInstance _rawInstance(
  Map<String, dynamic> experience,
  String workflowType,
) {
  final items = experience['workflowInstances'] as List<dynamic>;
  final raw = items.cast<Map<String, dynamic>>().firstWhere(
    (item) => item['workflowType'] == workflowType,
  );
  return LoomWorkflowSeedInstance.fromJson(raw);
}

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory(
      '${directory.path}/docs/references/communities',
    ).existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError('Could not locate the repository root.');
}
