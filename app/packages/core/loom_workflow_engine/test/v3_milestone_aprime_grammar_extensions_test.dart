import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(String type, Map<String, dynamic> json) =>
    LoomWorkflowStateMachine.fromJson(json, type);

void main() {
  // ── 1. Model round-trip parsing ──────────────────────────────────────
  group('Model parsing', () {
    test('render binding fromJson parses optional styleField', () {
      final styled = RenderBinding.fromJson(<String, dynamic>{
        'states': ['open'],
        'role': 'any',
        'tabId': 'calendar',
        'cardSurfaceFamily': 'event-rsvp',
        'bindingKind': 'primary',
        'styleField': 'cardStyleId',
      });
      final unstyled = RenderBinding.fromJson(<String, dynamic>{
        'states': ['open'],
        'role': 'any',
        'tabId': 'calendar',
        'cardSurfaceFamily': 'event-rsvp',
        'bindingKind': 'primary',
      });

      expect(styled.styleField, 'cardStyleId');
      expect(unstyled.styleField, isNull);
    });

    test('transition fromJson parses inputs from frozen JSON fragment', () {
      final t = LoomWorkflowTransition.fromJson(<String, dynamic>{
        'id': 'cast-vote',
        'label': 'Vote',
        'icon': 'how_to_vote',
        'tone': 'primary',
        'from': ['open'],
        'to': null,
        'guard': <String, dynamic>{
          'allowedPersonaIds': ['tabletop-member', 'tabletop-organizer'],
          'relatedInstanceField': 'eventId',
          'relatedListField': 'goingPersonaIds',
        },
        'inputs': <String, dynamic>{
          'choice': <String, dynamic>{'type': 'text', 'required': true},
        },
        'effects': [
          <String, dynamic>{
            'op': 'createInstance',
            'workflowType': 'tournament-vote',
            'fields': <String, dynamic>{
              'ballotId': '{id}',
              'voterId': r'$actor',
              'choice': '{input.choice}',
            },
          },
        ],
      });
      expect(t.inputs, isNotNull);
      expect(t.inputs!.containsKey('choice'), isTrue);
      expect(t.inputs!['choice']!.type, 'text');
      expect(t.inputs!['choice']!.required, isTrue);
    });

    test('transition fromJson with no inputs yields null', () {
      final t = LoomWorkflowTransition.fromJson(<String, dynamic>{
        'id': 'simple',
        'label': 'Simple',
        'from': ['open'],
        'to': 'closed',
      });
      expect(t.inputs, isNull);
    });

    test('render binding fromJson parses repeater and itemActions', () {
      final b = RenderBinding.fromJson(<String, dynamic>{
        'states': ['open'],
        'role': 'any',
        'tabId': 'home',
        'cardSurfaceFamily': 'votePoll',
        'bindingKind': 'primary',
        'repeater': <String, dynamic>{
          'source': 'candidates',
          'itemActions': [
            <String, dynamic>{
              'transitionId': 'cast-vote',
              'inputs': <String, dynamic>{'choice': '{item.id}'},
            },
          ],
        },
      });
      expect(b.repeater, isNotNull);
      expect(b.repeater!.source, 'candidates');
      expect(b.repeater!.itemActions, hasLength(1));
      expect(b.repeater!.itemActions.first.transitionId, 'cast-vote');
      expect(
        b.repeater!.itemActions.first.inputs,
        {'choice': '{item.id}'},
      );
    });

    test('render binding fromJson parses create action with prefill', () {
      final b = RenderBinding.fromJson(<String, dynamic>{
        'states': ['draft'],
        'role': 'actor',
        'tabId': 'home',
        'cardSurfaceFamily': 'form-entry',
        'bindingKind': 'primary',
        'actions': [
          <String, dynamic>{
            'kind': 'create',
            'byPersonaIds': ['tabletop-member'],
            'label': 'Propose a game',
            'workflowType': 'game-purchase-proposal',
            'scope': 'instance',
            'presentation': 'button',
            'prefill': <String, dynamic>{'title': '{context.gameName}'},
          },
        ],
      });
      expect(b.actions, hasLength(1));
      expect(b.actions.single.byPersonaIds, ['tabletop-member']);
      expect(b.actions.single.label, 'Propose a game');
      expect(b.actions.single.workflowType, 'game-purchase-proposal');
      expect(b.actions.single.scope, 'instance');
      expect(b.actions.single.presentation, 'button');
      expect(b.actions.single.prefill, {'title': '{context.gameName}'});
    });

    test('create action parses without optional prefill', () {
      final b = RenderBinding.fromJson(<String, dynamic>{
        'states': ['draft'],
        'role': 'any',
        'tabId': 'home',
        'cardSurfaceFamily': 'form-entry',
        'bindingKind': 'primary',
        'actions': [
          <String, dynamic>{
            'kind': 'create',
            'byPersonaIds': ['tabletop-member', 'tabletop-organizer'],
            'label': 'Start a new thread',
          },
        ],
      });
      expect(b.actions, hasLength(1));
      expect(b.actions.single.prefill, isNull);
    });

    test('transition action parses all fields without kind-specific validation', () {
      final b = RenderBinding.fromJson(<String, dynamic>{
        'states': ['open'],
        'role': 'any',
        'tabId': 'marketplace',
        'cardSurfaceFamily': 'equipment-loan',
        'bindingKind': 'primary',
        'actions': [
          <String, dynamic>{
            'kind': 'transition',
            'transitionId': 'borrow',
            'label': 'Request loan',
            'byPersonaIds': ['tabletop-member'],
            'workflowType': 'equipment-loan',
            'scope': 'instance',
            'presentation': 'fab',
            'prefill': <String, dynamic>{'equipmentId': '{context.id}'},
            'inputs': <String, dynamic>{'equipmentId': '{context.id}'},
          },
        ],
      });
      final action = b.actions.single;
      expect(action.kind, 'transition');
      expect(action.label, 'Request loan');
      expect(action.transitionId, 'borrow');
      expect(action.byPersonaIds, ['tabletop-member']);
      expect(action.workflowType, 'equipment-loan');
      expect(action.scope, 'instance');
      expect(action.presentation, 'fab');
      expect(action.prefill, {'equipmentId': '{context.id}'});
      expect(action.inputs, {'equipmentId': '{context.id}'});
    });
  });

  // ── 2. {input.x} interpolation resolves correctly ────────────────────
  test('{input.x} creates distinct rows per call via createInstance effect',
      () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'gap1-test',
    );
    api.setPersonaType('voter-1', 'member');

    // Register the vote-row type (the child created by the transition)
    api.registerDefinition(
      _machine('vote-row', {
        'initialState': 'cast',
        'states': {
          'cast': {'label': 'Cast', 'isTerminal': true},
        },
        'transitions': <Map<String, dynamic>>[],
        'instanceDataSchema': {
          'ballotId': {'type': 'string'},
          'voterId': {'type': 'string'},
          'choice': {'type': 'string'},
        },
      }),
    );

    // Register a ballot type whose cast-vote transition takes a `choice` input
    // and writes it into a child vote-row via createInstance.
    api.registerDefinition(
      _machine('ballot', {
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
          'closed': {'label': 'Closed', 'isTerminal': true},
        },
        'transitions': [
          {
            'id': 'cast-vote',
            'label': 'Vote',
            'from': ['open'],
            'to': null,
            'guard': {'allowedPersonaIds': ['member']},
            'inputs': {'choice': {'type': 'text', 'required': true}},
            'effects': [
              {
                'op': 'createInstance',
                'workflowType': 'vote-row',
                'fields': {
                  'ballotId': '{id}',
                  'voterId': r'$actor',
                  'choice': '{input.choice}',
                },
              },
            ],
          },
        ],
        'instanceDataSchema': <String, dynamic>{},
      }),
    );

    final ballotId = await api.createInstance(
      workflowType: 'ballot',
      personaId: 'voter-1',
      initialInstanceData: <String, dynamic>{},
    );

    // First vote: Catan
    await api.applyTransition(
      workflowType: 'ballot',
      instanceId: ballotId,
      transitionId: 'cast-vote',
      personaId: 'voter-1',
      inputs: <String, dynamic>{'choice': 'Catan'},
    );

    // Second vote: Azul (same ballot, different choice)
    await api.applyTransition(
      workflowType: 'ballot',
      instanceId: ballotId,
      transitionId: 'cast-vote',
      personaId: 'voter-1',
      inputs: <String, dynamic>{'choice': 'Azul'},
    );

    // Read back all vote rows
    final page = await api.queryInstances(
      tabId: 'x',
      personaId: 'voter-1',
      limit: 50,
    );
    final votes = page.items
        .where((i) => i.workflowType == 'vote-row')
        .toList();

    expect(votes, hasLength(2));
    expect(
      votes.map((v) => v.instanceData['choice']).toSet(),
      {'Catan', 'Azul'},
    );
  });

  // ── 3. Required input missing ────────────────────────────────────────
  test('applyTransition refuses when required input is missing', () async {
    final api = LocalWorkflowEngineApi(
      db: WorkflowDatabase.memory(),
      communityId: 'gap1-req-test',
    );
    api.setPersonaType('voter-1', 'member');

    api.registerDefinition(
      _machine('ballot', {
        'initialState': 'open',
        'states': {
          'open': {'label': 'Open'},
          'closed': {'label': 'Closed'},
        },
        'transitions': [
          {
            'id': 'cast-vote',
            'label': 'Vote',
            'from': ['open'],
            'to': 'open',
            'guard': {'allowedPersonaIds': ['member']},
            'inputs': {'choice': {'type': 'text', 'required': true}},
            'effects': <Map<String, dynamic>>[],
          },
        ],
        'instanceDataSchema': <String, dynamic>{},
      }),
    );

    final ballotId = await api.createInstance(
      workflowType: 'ballot',
      personaId: 'voter-1',
      initialInstanceData: <String, dynamic>{},
    );

    // Call without inputs at all
    expect(
      () => api.applyTransition(
        workflowType: 'ballot',
        instanceId: ballotId,
        transitionId: 'cast-vote',
        personaId: 'voter-1',
      ),
      throwsStateError,
    );

    // Call with an empty inputs map
    expect(
      () => api.applyTransition(
        workflowType: 'ballot',
        instanceId: ballotId,
        transitionId: 'cast-vote',
        personaId: 'voter-1',
        inputs: <String, dynamic>{},
      ),
      throwsStateError,
    );
  });

  // ── 4. GAP-4 end-to-end: query-backed source fields ──────────────────
  group('GAP-4 query-backed source', () {
    late LocalWorkflowEngineApi api;

    Future<void> _seedBallotAndVotes() async {
      api = LocalWorkflowEngineApi(
        db: WorkflowDatabase.memory(),
        communityId: 'gap4-test',
      );
      api.setPersonaType('member-03', 'tabletop-member');
      api.setPersonaType('member-04', 'tabletop-member');
      api.setPersonaType('member-05', 'tabletop-member');
      api.setPersonaType('member-06', 'tabletop-member');
      api.setPersonaType('organizer', 'tabletop-organizer');

      // Event (needed for related-list guard on cast-vote)
      api.registerDefinition(
        _machine('tournament-event', {
          'initialState': 'open',
          'states': {
            'open': {'label': 'Open', 'editableFields': ['goingPersonaIds']},
          },
          'transitions': <Map<String, dynamic>>[],
          'instanceDataSchema': {
            'goingPersonaIds': {'type': 'list'},
          },
        }),
      );

      // Vote row table
      api.registerDefinition(
        _machine('tournament-vote', {
          'initialState': 'cast',
          'states': {
            'cast': {'label': 'Vote cast', 'isTerminal': true},
          },
          'transitions': <Map<String, dynamic>>[],
          'instanceDataSchema': {
            'ballotId': {'type': 'string'},
            'voterId': {'type': 'string'},
            'choice': {'type': 'string'},
          },
        }),
      );

      // Ballot — matches frozen JSON's tournament-ballot exactly
      api.registerDefinition(
        _machine('tournament-ballot', {
          'initialState': 'open',
          'states': {
            'open': {'label': 'Voting open'},
            'closed': {'label': 'Closed', 'isTerminal': true},
          },
          'transitions': [
            {
              'id': 'cast-vote',
              'label': 'Vote',
              'from': ['open'],
              'to': null,
              'guard': {
                'allowedPersonaIds': ['tabletop-member', 'tabletop-organizer'],
                'relatedInstanceField': 'eventId',
                'relatedListField': 'goingPersonaIds',
              },
              'inputs': {'choice': {'type': 'text', 'required': true}},
              'effects': [
                {
                  'op': 'createInstance',
                  'workflowType': 'tournament-vote',
                  'fields': {
                    'ballotId': '{id}',
                    'voterId': r'$actor',
                    'choice': '{input.choice}',
                  },
                },
              ],
            },
          ],
          'instanceDataSchema': <String, dynamic>{
            'eventId': {'type': 'string'},
            'ballots': {
              'type': 'list',
              'source': 'query(tournament-vote where ballotId == id)',
            },
            'voteCounts': {
              'type': 'map', 'formula': 'groupCount(ballots, choice)',
            },
            'totalVotes': {
              'type': 'number', 'formula': 'size(ballots)',
            },
            'winner': {
              'type': 'string', 'formula': 'argMaxKey(voteCounts)',
            },
            'tiedCandidates': {
              'type': 'list', 'formula': 'topKeys(voteCounts)',
            },
            'isTie': {
              'type': 'bool', 'formula': 'size(tiedCandidates) > 1',
            },
          },
        }),
      );
    }

    setUp(_seedBallotAndVotes);

    test('queryInstances hydrates query-backed source fields', () async {
      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'event-summer',
          workflowType: 'tournament-event',
          currentState: 'open',
          instanceData: <String, dynamic>{
            'goingPersonaIds': [
              'member-03', 'member-04', 'member-05', 'member-06',
            ],
          },
          createdByPersonaId: 'organizer',
        ),
      ]);

      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'ballot-summer',
          workflowType: 'tournament-ballot',
          currentState: 'open',
          instanceData: <String, dynamic>{
            'eventId': 'event-summer',
          },
          createdByPersonaId: 'organizer',
        ),
      ]);

      // Seed the 4 real votes from the frozen JSON
      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'vote-m03-catan',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-03',
            'choice': 'catan',
          },
          createdByPersonaId: 'member-03',
        ),
        WorkflowInstance(
          instanceId: 'vote-m04-wingspan',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-04',
            'choice': 'wingspan',
          },
          createdByPersonaId: 'member-04',
        ),
        WorkflowInstance(
          instanceId: 'vote-m05-catan',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-05',
            'choice': 'catan',
          },
          createdByPersonaId: 'member-05',
        ),
        WorkflowInstance(
          instanceId: 'vote-m06-azul',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-06',
            'choice': 'azul',
          },
          createdByPersonaId: 'member-06',
        ),
      ]);

      final page = await api.queryInstances(
        tabId: 'home',
        personaId: 'organizer',
        limit: 50,
      );
      final ballot = page.items.firstWhere(
        (i) => i.instanceId == 'ballot-summer',
      );
      final data = ballot.instanceData;

      // ballots field should be populated with full vote-row instance data
      expect(data['ballots'], isA<List<dynamic>>());
      final ballots = data['ballots'] as List<dynamic>;
      expect(ballots, hasLength(4));

      // Each row carries its own choice and voterId
      final choices =
          ballots.map((b) => (b as Map)['choice'] as String).toList();
      expect(
        choices..sort(),
        ['azul', 'catan', 'catan', 'wingspan'],
      );
    });

    test('formulas compute over hydrated source data', () async {
      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'event-summer',
          workflowType: 'tournament-event',
          currentState: 'open',
          instanceData: <String, dynamic>{
            'goingPersonaIds': [
              'member-03', 'member-04', 'member-05', 'member-06',
            ],
          },
          createdByPersonaId: 'organizer',
        ),
      ]);

      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'ballot-summer',
          workflowType: 'tournament-ballot',
          currentState: 'open',
          instanceData: <String, dynamic>{
            'eventId': 'event-summer',
          },
          createdByPersonaId: 'organizer',
        ),
        WorkflowInstance(
          instanceId: 'vote-m03-catan',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-03',
            'choice': 'catan',
          },
          createdByPersonaId: 'member-03',
        ),
        WorkflowInstance(
          instanceId: 'vote-m04-wingspan',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-04',
            'choice': 'wingspan',
          },
          createdByPersonaId: 'member-04',
        ),
        WorkflowInstance(
          instanceId: 'vote-m05-catan',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-05',
            'choice': 'catan',
          },
          createdByPersonaId: 'member-05',
        ),
        WorkflowInstance(
          instanceId: 'vote-m06-azul',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-06',
            'choice': 'azul',
          },
          createdByPersonaId: 'member-06',
        ),
      ]);

      final page = await api.queryInstances(
        tabId: 'home',
        personaId: 'organizer',
        limit: 50,
      );
      final ballot = page.items.firstWhere(
        (i) => i.instanceId == 'ballot-summer',
      );
      final data = ballot.instanceData;

      // Frozen JSON seed data: catan x2, wingspan x1, azul x1
      // winner → catan, isTie → false
      expect(data['totalVotes'], 4);
      expect(data['winner'], 'catan');
      expect(data['isTie'], false);
      expect(data['voteCounts'], isA<Map<dynamic, dynamic>>());
      final counts = data['voteCounts'] as Map<dynamic, dynamic>;
      expect(counts['catan'], 2);
      expect(counts['wingspan'], 1);
      expect(counts['azul'], 1);

      // tiedCandidates should contain only 'catan' (the single winner)
      expect(data['tiedCandidates'], isA<List<dynamic>>());
      expect(data['tiedCandidates'], ['catan']);
    });

    test('availableTransitionsAsync hydrates source fields', () async {
      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'event-summer',
          workflowType: 'tournament-event',
          currentState: 'open',
          instanceData: <String, dynamic>{
            'goingPersonaIds': ['member-03'],
          },
          createdByPersonaId: 'organizer',
        ),
      ]);

      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'ballot-summer',
          workflowType: 'tournament-ballot',
          currentState: 'open',
          instanceData: <String, dynamic>{
            'eventId': 'event-summer',
          },
          createdByPersonaId: 'organizer',
        ),
        WorkflowInstance(
          instanceId: 'vote-m03-catan',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-03',
            'choice': 'catan',
          },
          createdByPersonaId: 'member-03',
        ),
      ]);

      // Read instance first so we have computed data
      final page = await api.queryInstances(
        tabId: 'home',
        personaId: 'organizer',
        limit: 50,
      );
      final instance = page.items.firstWhere(
        (i) => i.instanceId == 'ballot-summer',
      );

      final transitions = await api.availableTransitionsAsync(
        workflowType: 'tournament-ballot',
        instanceId: 'ballot-summer',
        currentState: 'open',
        instanceData: instance.instanceData,
        personaId: 'member-03',
      );
      expect(transitions, isNotEmpty);
      expect(
        transitions.any((t) => t.id == 'cast-vote'),
        isTrue,
      );
    });

    test('applyTransition result hydrates source fields', () async {
      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'event-summer',
          workflowType: 'tournament-event',
          currentState: 'open',
          instanceData: <String, dynamic>{
            'goingPersonaIds': ['member-03'],
          },
          createdByPersonaId: 'organizer',
        ),
      ]);

      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'ballot-summer',
          workflowType: 'tournament-ballot',
          currentState: 'open',
          instanceData: <String, dynamic>{
            'eventId': 'event-summer',
          },
          createdByPersonaId: 'organizer',
        ),
      ]);

      // Cast a vote through applyTransition
      final result = await api.applyTransition(
        workflowType: 'tournament-ballot',
        instanceId: 'ballot-summer',
        transitionId: 'cast-vote',
        personaId: 'member-03',
        inputs: <String, dynamic>{'choice': 'catan'},
      );

      // After casting, the result's instanceData should have hydrated ballots
      expect(result.newInstanceData['ballots'], isA<List<dynamic>>());
      final ballots = result.newInstanceData['ballots'] as List<dynamic>;
      expect(ballots, hasLength(1));
      expect((ballots.first as Map<dynamic, dynamic>)['choice'], 'catan');
    });

    test('aggregate API works with source-backed formulas', () async {
      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'event-summer',
          workflowType: 'tournament-event',
          currentState: 'open',
          instanceData: <String, dynamic>{
            'goingPersonaIds': ['member-03'],
          },
          createdByPersonaId: 'organizer',
        ),
      ]);

      await api.seedInstances([
        WorkflowInstance(
          instanceId: 'ballot-summer',
          workflowType: 'tournament-ballot',
          currentState: 'open',
          instanceData: <String, dynamic>{
            'eventId': 'event-summer',
          },
          createdByPersonaId: 'organizer',
        ),
        WorkflowInstance(
          instanceId: 'vote-m03-catan',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-03',
            'choice': 'catan',
          },
          createdByPersonaId: 'member-03',
        ),
        WorkflowInstance(
          instanceId: 'vote-m04-wingspan',
          workflowType: 'tournament-vote',
          currentState: 'cast',
          instanceData: <String, dynamic>{
            'ballotId': 'ballot-summer',
            'voterId': 'member-04',
            'choice': 'wingspan',
          },
          createdByPersonaId: 'member-04',
        ),
      ]);

      final count = await api.aggregate(
        workflowType: 'tournament-vote',
        column: 'choice',
        op: 'count',
      );
      expect(count, 2);
    });
  });
}
