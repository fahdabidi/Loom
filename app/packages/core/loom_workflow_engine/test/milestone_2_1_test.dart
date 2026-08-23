import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _calendarInviteMachine() {
  return const LoomWorkflowStateMachine(
    workflowType: 'calendar-invite',
    initialState: 'scheduled',
    states: {'scheduled': LoomWorkflowState(label: 'Scheduled')},
    transitions: [
      LoomWorkflowTransition(
        id: 'rsvp-going',
        label: 'Going',
        from: ['scheduled'],
        to: null,
        guard: WorkflowGuard(allowedRoleIds: ['member']),
        effects: [
          WorkflowEffect(op: 'set', key: 'rsvpByFan.\$actor', value: 'going'),
        ],
      ),
      LoomWorkflowTransition(
        id: 'rsvp-maybe',
        label: 'Maybe',
        from: ['scheduled'],
        to: null,
        guard: WorkflowGuard(allowedRoleIds: ['member']),
        effects: [
          WorkflowEffect(op: 'set', key: 'rsvpByFan.\$actor', value: 'maybe'),
        ],
      ),
      LoomWorkflowTransition(
        id: 'rsvp-not-going',
        label: 'Not going',
        from: ['scheduled'],
        to: null,
        guard: WorkflowGuard(allowedRoleIds: ['member']),
        effects: [
          WorkflowEffect(
            op: 'set',
            key: 'rsvpByFan.\$actor',
            value: 'not-going',
          ),
        ],
      ),
    ],
    renderBindings: [
      RenderBinding(
        states: ['scheduled'],
        role: 'actor',
        tabId: 'calendar',
        cardSurfaceFamily: 'event-host',
        bindingKind: 'primary',
      ),
      RenderBinding(
        states: ['scheduled'],
        role: 'receiver',
        tabId: 'calendar',
        cardSurfaceFamily: 'event-invite',
        bindingKind: 'primary',
        audienceMemberField: 'invitedFanIds',
      ),
    ],
    instanceDataSchema: {
      'title': InstanceDataField(type: 'text', required: true),
      'audienceScope': InstanceDataField(type: 'audienceSelector'),
      'invitedFanIds': InstanceDataField(type: 'fanId[]'),
      'rsvpByFan': InstanceDataField(type: 'fanResponseMap'),
    },
  );
}

LocalWorkflowEngineApi _makeApi() {
  final db = WorkflowDatabase.memory();
  final api = LocalWorkflowEngineApi(db: db, communityId: 'calendar');
  for (final fanId in const [
    'creator',
    'alice',
    'bob',
    'cora',
    'drew',
    'erin',
  ]) {
    api.setRoleForFan(fanId, 'member');
  }
  api.registerDefinition(_calendarInviteMachine());
  return api;
}

void main() {
  group('Milestone 2.1 audience/distribution primitive', () {
    test('audience cardinalities resolve receiver role correctly', () {
      final machine = _calendarInviteMachine();

      final allBindings = resolveBindings(
        machine,
        'scheduled',
        ['receiver'],
        instanceData: {'audienceScope': 'all', 'invitedFanIds': <String>[]},
        fanId: 'alice',
      );
      expect(allBindings.map((binding) => binding.role), contains('receiver'));

      final selectedMatches = ['alice', 'bob', 'cora'].where((fanId) {
        return resolveBindings(
          machine,
          'scheduled',
          const [],
          instanceData: {
            'audienceScope': 'selected',
            'invitedFanIds': ['alice', 'bob', 'cora'],
          },
          fanId: fanId,
        ).any((binding) => binding.role == 'receiver');
      }).toList();
      expect(selectedMatches, ['alice', 'bob', 'cora']);

      final selectedNonMember = resolveBindings(
        machine,
        'scheduled',
        const [],
        instanceData: {
          'audienceScope': 'selected',
          'invitedFanIds': ['alice', 'bob', 'cora'],
        },
        fanId: 'drew',
      );
      expect(
        selectedNonMember.any((binding) => binding.role == 'receiver'),
        isFalse,
      );

      final individualMatches = ['alice', 'bob'].where((fanId) {
        return resolveBindings(
          machine,
          'scheduled',
          const [],
          instanceData: {
            'audienceScope': 'individual',
            'invitedFanIds': ['bob'],
          },
          fanId: fanId,
        ).any((binding) => binding.role == 'receiver');
      }).toList();
      expect(individualMatches, ['bob']);
    });

    test('selected audience excludes non-invited fan receiver binding', () {
      final bindings = resolveBindings(
        _calendarInviteMachine(),
        'scheduled',
        const [],
        instanceData: {
          'audienceScope': 'selected',
          'invitedFanIds': ['alice', 'bob'],
        },
        fanId: 'cora',
      );

      expect(bindings.where((binding) => binding.role == 'receiver'), isEmpty);
    });

    test(
      'queryInstances fans out on read for fan audience membership',
      () async {
        final api = _makeApi();
        for (var index = 0; index < 5; index += 1) {
          await api.createInstance(
            workflowType: 'calendar-invite',
            fanId: 'creator',
            initialInstanceData: {
              'title': 'Invite $index',
              'audienceScope': 'selected',
              'invitedFanIds': index == 1 || index == 3
                  ? ['alice', 'bob']
                  : ['bob', 'cora'],
              'rsvpByFan': <String, String>{},
            },
          );
        }

        final page = await api.queryInstances(
          tabId: 'calendar',
          fanId: 'alice',
          query: const SurfaceQuery(audienceMemberField: 'invitedFanIds'),
        );

        expect(page.items, hasLength(2));
        expect(page.items.map((item) => item.instanceData['title']).toSet(), {
          'Invite 1',
          'Invite 3',
        });
      },
    );

    test('selected invitees can RSVP and creator sees responses', () async {
      final api = _makeApi();
      final instanceId = await api.createInstance(
        workflowType: 'calendar-invite',
        fanId: 'creator',
        initialInstanceData: {
          'title': 'Game night',
          'audienceScope': 'selected',
          'invitedFanIds': ['alice', 'bob'],
          'rsvpByFan': <String, String>{},
        },
      );

      for (final invitee in ['alice', 'bob']) {
        final receiveBindings = resolveBindings(
          _calendarInviteMachine(),
          'scheduled',
          const [],
          instanceData: {
            'audienceScope': 'selected',
            'invitedFanIds': ['alice', 'bob'],
          },
          fanId: invitee,
        );
        expect(
          receiveBindings.any((binding) => binding.role == 'receiver'),
          isTrue,
        );
      }

      await api.applyTransition(
        workflowType: 'calendar-invite',
        instanceId: instanceId,
        transitionId: 'rsvp-going',
        fanId: 'alice',
      );
      await api.applyTransition(
        workflowType: 'calendar-invite',
        instanceId: instanceId,
        transitionId: 'rsvp-maybe',
        fanId: 'bob',
      );

      final creatorPage = await api.queryInstances(
        tabId: 'calendar',
        fanId: 'creator',
      );
      final instance = creatorPage.items.singleWhere(
        (item) => item.instanceId == instanceId,
      );

      expect(instance.instanceData['rsvpByFan'], {
        'alice': 'going',
        'bob': 'maybe',
      });
    });
  });
}
