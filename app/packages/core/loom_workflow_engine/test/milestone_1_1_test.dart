import 'dart:convert';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Embedded marketplace fixtures (from the worked example JSON)
// ---------------------------------------------------------------------------

String _marketplaceFixtureJson() {
  // ignore: prefer_raw_strings
  return r'''
{
  "workflowDefinitions": {
    "equipment-loan": {
      "renderBindings": [
        { "states": ["draft"], "role": "actor", "tabId": "marketplace",
          "cardSurfaceFamily": "listing-editor", "bindingKind": "primary" },
        { "states": ["pending-review"], "role": "actor", "tabId": "marketplace",
          "cardSurfaceFamily": "listing-status-badge", "bindingKind": "summary" },
        { "states": ["pending-review"], "role": "receiver", "tabId": "admin",
          "cardSurfaceFamily": "listing-review-queue-item", "bindingKind": "primary" },
        { "states": ["published"], "role": "any", "tabId": "marketplace",
          "cardSurfaceFamily": "equipment-loan", "bindingKind": "primary" }
      ],
      "initialState": "draft",
      "instanceDataSchema": {
        "title": {
          "type": "text", "required": true, "maxLength": 80,
          "writableBy": "formEntry", "storage": "inline",
          "searchable": true, "sortable": true,
          "displayIcon": null, "labelTemplate": "{value}", "displayContexts": ["tile","detail"]
        },
        "category": {
          "type": "text", "required": true,
          "writableBy": "formEntry", "storage": "inline",
          "searchable": false, "sortable": true,
          "displayContexts": ["tile","detail"]
        },
        "condition": {
          "type": "text", "required": true,
          "writableBy": "formEntry", "storage": "inline", "sortable": true,
          "displayIcon": "verified_outlined", "labelTemplate": "{value}", "displayContexts": ["detail"]
        },
        "holderPersonaId": {
          "type": "personaId?",
          "writableBy": "effect", "sortable": false,
          "displayIcon": "person_outline", "labelTemplate": "Holder: {value}",
          "displayContexts": ["tile","detail"]
        },
        "queuedPersonaIds": {
          "type": "personaId[]",
          "writableBy": "effect",
          "displayIcon": "groups_outlined", "labelTemplate": "Queue: {value.length}",
          "displayContexts": ["tile","detail"], "hideWhenEmpty": true
        }
      },
      "states": {
        "draft":          { "label": "Draft",
                             "editableFields": ["title","category","condition"] },
        "pending-review": { "label": "Pending review", "tone": "info",
                             "editableFields": [] },
        "published":      { "label": "Published", "tone": "positive" },
        "delisted":       { "label": "Delisted" }
      },
      "transitions": [
        {
          "id": "submit-listing", "label": "Submit for review", "icon": "send", "tone": "primary",
          "from": ["draft"], "to": "pending-review",
          "guard": { "allowedPersonaIds": ["tabletop-member"] }
        },
        {
          "id": "approve-listing", "label": "Approve", "icon": "check_circle", "tone": "primary",
          "from": ["pending-review"], "to": "published",
          "guard": { "allowedPersonaIds": ["tabletop-organizer"] },
          "effects": [{ "op": "set", "key": "availabilityState", "value": "available" }]
        },
        {
          "id": "reject-listing", "label": "Send back", "icon": "undo", "tone": "secondary",
          "from": ["pending-review"], "to": "draft",
          "guard": { "allowedPersonaIds": ["tabletop-organizer"] }
        },
        {
          "id": "borrow",
          "label": "Request loan",
          "icon": "arrow_forward", "tone": "primary",
          "from": ["published"], "to": null,
          "guard": {
            "allowedPersonaIds": ["tabletop-member"],
            "instanceDataEquals": { "key": "availabilityState", "value": "available" }
          },
          "effects": [
            { "op": "set", "key": "availabilityState", "value": "onLoan" },
            { "op": "set", "key": "holderPersonaId", "value": "$actor" }
          ],
          "linkedWorkflowId": "tabletop-game-loan"
        },
        {
          "id": "join-queue",
          "label": "Join queue",
          "icon": "add_circle_outline", "tone": "secondary",
          "from": ["published"], "to": null,
          "guard": {
            "allowedPersonaIds": ["tabletop-member"],
            "actorInList": { "key": "queuedPersonaIds", "present": false }
          },
          "effects": [
            { "op": "appendUnique", "key": "queuedPersonaIds", "value": "$actor" }
          ]
        },
        {
          "id": "leave-queue",
          "label": "Leave queue",
          "icon": "remove_circle_outline", "tone": "secondary",
          "from": ["published"], "to": null,
          "guard": {
            "allowedPersonaIds": ["tabletop-member"],
            "actorInList": { "key": "queuedPersonaIds", "present": true }
          },
          "effects": [
            { "op": "removeValue", "key": "queuedPersonaIds", "value": "$actor" }
          ]
        },
        {
          "id": "return",
          "label": "Return",
          "icon": "keyboard_return", "tone": "primary",
          "from": ["published"], "to": null,
          "guard": {
            "allowedPersonaIds": ["tabletop-member", "tabletop-organizer"],
            "instanceDataEquals": { "key": "availabilityState", "value": "onLoan" }
          },
          "effects": [
            { "op": "set", "key": "availabilityState", "value": "available" },
            { "op": "set", "key": "holderPersonaId", "value": null },
            { "op": "set", "key": "dueDate", "value": null }
          ]
        },
        {
          "id": "delist", "label": "Delist", "icon": "delete_outline", "tone": "destructive",
          "from": ["published"], "to": "delisted",
          "guard": { "allowedPersonaIds": ["tabletop-member-owner", "tabletop-organizer"] }
        }
      ]
    },
    "equipment-giveaway": {
      "renderBindings": [
        { "states": ["available", "claimed"], "role": "any", "tabId": "marketplace",
          "cardSurfaceFamily": "equipment-loan", "bindingKind": "primary" }
      ],
      "initialState": "available",
      "instanceDataSchema": {
        "title": { "type": "text", "required": true, "writableBy": "formEntry", "storage": "inline",
          "searchable": true, "sortable": true, "displayContexts": ["tile","detail"] },
        "claimedByPersonaId": {
          "type": "personaId?", "writableBy": "effect",
          "displayIcon": "person_outline", "labelTemplate": "Claimed by: {value}",
          "displayContexts": ["tile","detail"], "hideWhenEmpty": true
        }
      },
      "states": {
        "available": { "label": "Available", "tone": "positive" },
        "claimed": { "label": "Claimed", "tone": "positive" }
      },
      "transitions": [
        {
          "id": "claim",
          "label": "Claim giveaway",
          "icon": "check_circle", "tone": "primary",
          "from": ["available"],
          "to": "claimed",
          "guard": { "allowedPersonaIds": ["tabletop-member"] },
          "effects": [
            { "op": "set", "key": "claimedByPersonaId", "value": "$actor" }
          ],
          "linkedWorkflowId": "tabletop-game-loan"
        }
      ]
    }
  }
}
''';
}

LoomWorkflowStateMachine _parseFixture(String workflowType) {
  final root = jsonDecode(_marketplaceFixtureJson()) as Map<String, dynamic>;
  final defs = root['workflowDefinitions'] as Map<String, dynamic>;
  return LoomWorkflowStateMachine.fromJson(
      defs[workflowType] as Map<String, dynamic>, workflowType);
}

// ---------------------------------------------------------------------------
// 1. Guard operator tests
// ---------------------------------------------------------------------------

void main() {
  group('Guard operators', () {
    test('allowedPersonaIds: match', () {
      final guard = const WorkflowGuard(allowedPersonaIds: ['admin', 'member']);
      expect(evaluateGuard(guard, 'member', {}), isTrue);
    });

    test('allowedPersonaIds: deny', () {
      final guard = const WorkflowGuard(allowedPersonaIds: ['admin']);
      expect(evaluateGuard(guard, 'member', {}), isFalse);
    });

    test('allowedPersonaIds: null list allows anyone', () {
      final guard = const WorkflowGuard(allowedPersonaIds: null);
      expect(evaluateGuard(guard, 'anyone', {}), isTrue);
    });

    test('allowedPersonaIds: empty list allows anyone', () {
      final guard = const WorkflowGuard(allowedPersonaIds: []);
      expect(evaluateGuard(guard, 'anyone', {}), isTrue);
    });

    test('actorInList: present=true and persona IS in list → passes', () {
      final guard = const WorkflowGuard(
        actorInList: ListMembershipGuard(
            key: 'queuedPersonaIds', present: true),
      );
      expect(
        evaluateGuard(
          guard,
          'bob',
          {'queuedPersonaIds': ['alice', 'bob']},
        ),
        isTrue,
      );
    });

    test('actorInList: present=true and persona NOT in list → fails', () {
      final guard = const WorkflowGuard(
        actorInList: ListMembershipGuard(
            key: 'queuedPersonaIds', present: true),
      );
      expect(
        evaluateGuard(
          guard,
          'charlie',
          {'queuedPersonaIds': ['alice', 'bob']},
        ),
        isFalse,
      );
    });

    test('actorInList: present=false and persona NOT in list → passes', () {
      final guard = const WorkflowGuard(
        actorInList: ListMembershipGuard(
            key: 'queuedPersonaIds', present: false),
      );
      expect(
        evaluateGuard(
          guard,
          'charlie',
          {'queuedPersonaIds': ['alice', 'bob']},
        ),
        isTrue,
      );
    });

    test('actorInList: present=false and persona IS in list → fails', () {
      final guard = const WorkflowGuard(
        actorInList: ListMembershipGuard(
            key: 'queuedPersonaIds', present: false),
      );
      expect(
        evaluateGuard(
          guard,
          'bob',
          {'queuedPersonaIds': ['alice', 'bob']},
        ),
        isFalse,
      );
    });

    test('actorInList: key absent from instanceData with present=true → fails', () {
      final guard = const WorkflowGuard(
        actorInList:
            ListMembershipGuard(key: 'missing', present: true),
      );
      expect(
        evaluateGuard(guard, 'bob', {'other': 'value'}),
        isFalse,
      );
    });

    test('actorInList: key absent from instanceData with present=false → passes', () {
      final guard = const WorkflowGuard(
        actorInList:
            ListMembershipGuard(key: 'missing', present: false),
      );
      expect(
        evaluateGuard(guard, 'bob', {'other': 'value'}),
        isTrue,
      );
    });

    test('instanceDataEquals: value matches → passes', () {
      final guard = const WorkflowGuard(
        instanceDataEquals:
            KeyValueGuard(key: 'availabilityState', value: 'available'),
      );
      expect(
        evaluateGuard(guard, 'bob', {'availabilityState': 'available'}),
        isTrue,
      );
    });

    test('instanceDataEquals: value differs → fails', () {
      final guard = const WorkflowGuard(
        instanceDataEquals:
            KeyValueGuard(key: 'availabilityState', value: 'available'),
      );
      expect(
        evaluateGuard(guard, 'bob', {'availabilityState': 'onLoan'}),
        isFalse,
      );
    });

    test('instanceDataEquals: key absent → fails', () {
      final guard = const WorkflowGuard(
        instanceDataEquals:
            KeyValueGuard(key: 'missing', value: 'anything'),
      );
      expect(
        evaluateGuard(guard, 'bob', {'other': 'value'}),
        isFalse,
      );
    });

    test(
        'compound guard: both conditions true → passes (allowedPersonaIds AND instanceDataEquals)',
        () {
      final guard = const WorkflowGuard(
        allowedPersonaIds: ['member'],
        instanceDataEquals: KeyValueGuard(
            key: 'availabilityState', value: 'available'),
      );
      expect(
        evaluateGuard(
            guard, 'member', {'availabilityState': 'available'}),
        isTrue,
      );
    });

    test(
        'compound guard: allowedPersonaIds true, instanceDataEquals false → transition unavailable',
        () {
      final guard = const WorkflowGuard(
        allowedPersonaIds: ['member'],
        instanceDataEquals: KeyValueGuard(
            key: 'availabilityState', value: 'available'),
      );
      expect(
        evaluateGuard(
            guard, 'member', {'availabilityState': 'onLoan'}),
        isFalse,
      );
    });

    test(
        'compound guard: allowedPersonaIds false, instanceDataEquals true → transition unavailable',
        () {
      final guard = const WorkflowGuard(
        allowedPersonaIds: ['admin'],
        instanceDataEquals: KeyValueGuard(
            key: 'availabilityState', value: 'available'),
      );
      expect(
        evaluateGuard(
            guard, 'member', {'availabilityState': 'available'}),
        isFalse,
      );
    });

    test('empty guard (all null) → always passes', () {
      expect(evaluateGuard(const WorkflowGuard(), 'anyone', {}), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // 2. Effect operator tests
  // -------------------------------------------------------------------------

  group('Effect operators', () {
    test('set: writes a string value', () {
      final effects = [
        const WorkflowEffect(
            op: 'set', key: 'availabilityState', value: 'onLoan'),
      ];
      final result = applyEffects(effects, 'bob', {});
      expect(result, {'availabilityState': 'onLoan'});
    });

    test('set: resolves \$actor to personaId', () {
      final effects = [
        const WorkflowEffect(
            op: 'set', key: 'holderPersonaId', value: r'$actor'),
      ];
      final result = applyEffects(effects, 'bob-42', {});
      expect(result, {'holderPersonaId': 'bob-42'});
    });

    test('set: writes null (key set to null)', () {
      final effects = [
        const WorkflowEffect(
            op: 'set', key: 'holderPersonaId', value: null),
      ];
      final result = applyEffects(
          effects, 'bob', {'holderPersonaId': 'alice'});
      expect(result, {'holderPersonaId': null});
    });

    test('set: overwrites existing value', () {
      final effects = [
        const WorkflowEffect(
            op: 'set', key: 'counter', value: 42),
      ];
      final result = applyEffects(effects, 'bob', {'counter': 1});
      expect(result, {'counter': 42});
    });

    test('appendUnique: on an empty list → adds value', () {
      final effects = [
        const WorkflowEffect(
            op: 'appendUnique', key: 'queue', value: 'alpha'),
      ];
      final result =
          applyEffects(effects, 'bob', {'queue': <String>[]});
      expect(result['queue'], ['alpha']);
    });

    test('appendUnique: on a list NOT containing value → appends', () {
      final effects = [
        const WorkflowEffect(
            op: 'appendUnique', key: 'queue', value: 'beta'),
      ];
      final result = applyEffects(
          effects, 'bob', {'queue': ['alpha']});
      expect(result['queue'], ['alpha', 'beta']);
    });

    test('appendUnique: on a list ALREADY containing value → idempotent', () {
      final effects = [
        const WorkflowEffect(
            op: 'appendUnique', key: 'queue', value: 'alpha'),
      ];
      final result = applyEffects(
          effects, 'bob', {'queue': ['alpha']});
      expect(result['queue'], ['alpha'],
          reason: 'duplicate must not be appended');
    });

    test('appendUnique: key absent → creates new list', () {
      final effects = [
        const WorkflowEffect(
            op: 'appendUnique', key: 'newKey', value: 'first'),
      ];
      final result = applyEffects(effects, 'bob', {});
      expect(result['newKey'], ['first']);
    });

    test('appendUnique: resolves \$actor', () {
      final effects = [
        const WorkflowEffect(
            op: 'appendUnique', key: 'queue', value: r'$actor'),
      ];
      final result =
          applyEffects(effects, 'charlie', {'queue': <String>[]});
      expect(result['queue'], ['charlie']);
    });

    test('removeValue: value present → removes it', () {
      final effects = [
        const WorkflowEffect(
            op: 'removeValue', key: 'queue', value: 'alpha'),
      ];
      final result = applyEffects(
          effects, 'bob', {'queue': ['alpha', 'beta']});
      expect(result['queue'], ['beta']);
    });

    test('removeValue: value absent → no-op, list unchanged', () {
      final effects = [
        const WorkflowEffect(
            op: 'removeValue', key: 'queue', value: 'gamma'),
      ];
      final result = applyEffects(
          effects, 'bob', {'queue': ['alpha', 'beta']});
      expect(result['queue'], ['alpha', 'beta']);
    });

    test('removeValue: key absent → no-op', () {
      final effects = [
        const WorkflowEffect(
            op: 'removeValue', key: 'nonexistent', value: 'x'),
      ];
      final result = applyEffects(effects, 'bob', {});
      expect(result, <String, dynamic>{});
    });

    test('increment: from 0 (key absent) → 1', () {
      final effects = [
        const WorkflowEffect(op: 'increment', key: 'counter', value: 1),
      ];
      final result = applyEffects(effects, 'bob', {});
      expect(result['counter'], 1);
    });

    test('increment: from 5 → 6', () {
      final effects = [
        const WorkflowEffect(op: 'increment', key: 'counter', value: 1),
      ];
      final result =
          applyEffects(effects, 'bob', {'counter': 5});
      expect(result['counter'], 6);
    });

    test('increment: from non-numeric (string) → resets to 1', () {
      final effects = [
        const WorkflowEffect(op: 'increment', key: 'counter', value: 1),
      ];
      final result =
          applyEffects(effects, 'bob', {'counter': 'not-a-number'});
      expect(result['counter'], 1);
    });

    test('decrement: from 3 → 2', () {
      final effects = [
        const WorkflowEffect(op: 'decrement', key: 'counter', value: 1),
      ];
      final result =
          applyEffects(effects, 'bob', {'counter': 3});
      expect(result['counter'], 2);
    });

    test('decrement: from 0 → clamps at 0', () {
      final effects = [
        const WorkflowEffect(op: 'decrement', key: 'counter', value: 1),
      ];
      final result =
          applyEffects(effects, 'bob', {'counter': 0});
      expect(result['counter'], 0);
    });

    test('decrement: key absent → 0 (clamped)', () {
      final effects = [
        const WorkflowEffect(op: 'decrement', key: 'counter', value: 1),
      ];
      final result = applyEffects(effects, 'bob', {});
      expect(result['counter'], 0);
    });

    test('multiple effects applied in order', () {
      final effects = [
        const WorkflowEffect(
            op: 'set', key: 'a', value: 'one'),
        const WorkflowEffect(
            op: 'set', key: 'b', value: 'two'),
        const WorkflowEffect(
            op: 'appendUnique', key: 'list', value: 'x'),
      ];
      final result =
          applyEffects(effects, 'bob', {'list': <String>[]});
      expect(result['a'], 'one');
      expect(result['b'], 'two');
      expect(result['list'], ['x']);
    });

    test('original instanceData is not mutated', () {
      final original = {'counter': 5};
      final effects = [
        const WorkflowEffect(op: 'increment', key: 'counter', value: 1),
      ];
      final result = applyEffects(effects, 'bob', original);
      expect(original['counter'], 5); // unchanged
      expect(result['counter'], 6); // new map has incremented value
      expect(identical(original, result), isFalse);
    });

    test('unknown op is silently ignored (removeFromTileGrid passes through)', () {
      final effects = [
        const WorkflowEffect(
            op: 'removeFromTileGrid', key: 'n/a', value: null),
        const WorkflowEffect(
            op: 'set', key: 'survived', value: true),
      ];
      final result = applyEffects(effects, 'bob', {});
      expect(result, {'survived': true});
      // Engine must not crash or throw on unknown ops.
    });
  });

  // -------------------------------------------------------------------------
  // 3. Stuck-state regression test
  // -------------------------------------------------------------------------

  group('Stuck-state regression (original marketplace bug)', () {
    test(
        'a state with zero outgoing transitions parses successfully in engine',
        () {
      // Build a machine where state "delisted" has no outgoing transitions.
      // This is valid — the validator catches it later (Milestone 1.3), not
      // the engine.
      final machine = const LoomWorkflowStateMachine(
        workflowType: 'test',
        initialState: 'available',
        states: {
          'available': LoomWorkflowState(label: 'Available'),
          'done': LoomWorkflowState(label: 'Done'),
        },
        transitions: [
          LoomWorkflowTransition(
            id: 'finish',
            label: 'Finish',
            from: ['available'],
            to: 'done',
          ),
          // No transition from "done" — this is the stuck state.
        ],
      );

      // Engine must parse this without error.
      expect(machine.transitionsFrom('done'), isEmpty);
    });

    test('availableTransitions on a stuck state returns empty list', () {
      final machine = const LoomWorkflowStateMachine(
        workflowType: 'test',
        initialState: 'available',
        states: {
          'available': LoomWorkflowState(label: 'Available'),
          'done': LoomWorkflowState(label: 'Done'),
        },
        transitions: [
          LoomWorkflowTransition(
            id: 'finish',
            label: 'Finish',
            from: ['available'],
            to: 'done',
          ),
        ],
      );

      final actions = availableTransitions(
        machine,
        'done', // stuck state
        'bob',
        {},
      );
      expect(actions, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // 4. §2d orthogonal-lifecycle drive-through
  // -------------------------------------------------------------------------

  group('§2d orthogonal-lifecycle: equipment-loan full drive-through', () {
    late LoomWorkflowStateMachine machine;

    setUp(() {
      machine = _parseFixture('equipment-loan');
    });

    test('parse succeeds and returns correct workflow type', () {
      expect(machine.workflowType, 'equipment-loan');
      expect(machine.initialState, 'draft');
      expect(machine.states.length, 4);
      expect(machine.transitions.length, 8);
    });

    test('draft → submit-listing → pending-review', () {
      var state = 'draft';
      var data = <String, dynamic>{
        'title': 'Catan',
        'category': 'Board Games',
        'condition': 'Like new',
        'holderPersonaId': null,
        'queuedPersonaIds': <String>[],
      };

      // Member submits for review.
      final actions = availableTransitions(
          machine, state, 'tabletop-member', data);
      final submit = actions.firstWhere((a) => a.id == 'submit-listing');
      expect(submit.label, 'Submit for review');

      // Apply to: pending-review.
      state = submit.to!;
      data = applyEffects(submit.effects, 'tabletop-member', data);
      expect(state, 'pending-review');
    });

    test('pending-review → approve-listing → published', () {
      var state = 'pending-review';
      var data = <String, dynamic>{
        'title': 'Catan',
        'category': 'Board Games',
        'condition': 'Like new',
      };

      // Only organizer can approve.
      var actions = availableTransitions(
          machine, state, 'tabletop-member', data);
      expect(actions.where((a) => a.id == 'approve-listing'), isEmpty,
          reason: 'member cannot approve');

      actions =
          availableTransitions(machine, state, 'tabletop-organizer', data);
      final approve =
          actions.firstWhere((a) => a.id == 'approve-listing');
      expect(approve.label, 'Approve');

      // Apply to: published, data gets availabilityState: "available".
      state = approve.to!;
      data = applyEffects(approve.effects, 'tabletop-organizer', data);
      expect(state, 'published');
      expect(data['availabilityState'], 'available');
    });

    test('published + available → borrow → top-level state stays published', () {
      final state = 'published';
      final data = <String, dynamic>{
        'title': 'Catan',
        'availabilityState': 'available',
        'holderPersonaId': null,
        'queuedPersonaIds': <String>[],
      };

      final actions =
          availableTransitions(machine, state, 'tabletop-member', data);
      final borrow = actions.firstWhere((a) => a.id == 'borrow');
      expect(borrow.to, isNull); // orthogonal: top-level state doesn't change

      // Apply effects.
      final newState = borrow.to ?? state; // null → stays published
      final newData =
          applyEffects(borrow.effects, 'tabletop-member', data);

      expect(newState, 'published',
          reason: 'top-level state must remain published');
      expect(newData['availabilityState'], 'onLoan',
          reason:
              'availabilityState changed independently from currentState');
      expect(newData['holderPersonaId'], 'tabletop-member');
    });

    test(
        'published + onLoan → return → availabilityState back to available',
        () {
      final state = 'published';
      final data = <String, dynamic>{
        'availabilityState': 'onLoan',
        'holderPersonaId': 'tabletop-member',
        'queuedPersonaIds': <String>[],
        'dueDate': '2026-07-17',
      };

      final actions =
          availableTransitions(machine, state, 'tabletop-member', data);
      final returnT = actions.firstWhere((a) => a.id == 'return');
      expect(returnT.label, 'Return');

      final newState = returnT.to ?? state;
      final newData =
          applyEffects(returnT.effects, 'tabletop-member', data);

      expect(newState, 'published');
      expect(newData['availabilityState'], 'available');
      expect(newData['holderPersonaId'], isNull);
      expect(newData['dueDate'], isNull);
    });

    test('published → delist → delisted', () {
      var state = 'published';
      final data = <String, dynamic>{
        'availabilityState': 'available',
        'holderPersonaId': null,
        'queuedPersonaIds': <String>[],
      };

      // Only owners/organizers can delist.
      var actions =
          availableTransitions(machine, state, 'tabletop-member', data);
      expect(actions.where((a) => a.id == 'delist'), isEmpty);

      actions =
          availableTransitions(machine, state, 'tabletop-member-owner', data);
      final delist = actions.firstWhere((a) => a.id == 'delist');
      expect(delist.label, 'Delist');

      state = delist.to!;
      expect(state, 'delisted');
    });

    test(
        'full drive: draft → published → borrow → return → delist, proving axes are independent',
        () {
      var state = machine.initialState; // draft
      var data = <String, dynamic>{
        'title': 'Catan',
        'category': 'Board Games',
        'condition': 'Like new',
        'holderPersonaId': null,
        'queuedPersonaIds': <String>[],
      };

      // Step 1: draft → pending-review (submit-listing).
      var actions =
          availableTransitions(machine, state, 'tabletop-member', data);
      var t = actions.firstWhere((a) => a.id == 'submit-listing');
      state = t.to!;
      data = applyEffects(t.effects, 'tabletop-member', data);
      expect(state, 'pending-review');

      // Step 2: pending-review → published (approve-listing).
      actions =
          availableTransitions(machine, state, 'tabletop-organizer', data);
      t = actions.firstWhere((a) => a.id == 'approve-listing');
      state = t.to!;
      data = applyEffects(t.effects, 'tabletop-organizer', data);
      expect(state, 'published');
      expect(data['availabilityState'], 'available');

      // Step 3: published → borrow (orthogonal: state stays published).
      actions =
          availableTransitions(machine, state, 'tabletop-member', data);
      t = actions.firstWhere((a) => a.id == 'borrow');
      state = t.to ?? state;
      data = applyEffects(t.effects, 'tabletop-member', data);
      expect(state, 'published',
          reason: 'top-level state axis unchanged by borrow');
      expect(data['availabilityState'], 'onLoan',
          reason: 'orthogonal axis changed independently');

      // Step 4: published → return (orthogonal again).
      actions =
          availableTransitions(machine, state, 'tabletop-member', data);
      t = actions.firstWhere((a) => a.id == 'return');
      state = t.to ?? state;
      data = applyEffects(t.effects, 'tabletop-member', data);
      expect(state, 'published');
      expect(data['availabilityState'], 'available');

      // Step 5: published → delist.
      actions =
          availableTransitions(machine, state, 'tabletop-member-owner', data);
      t = actions.firstWhere((a) => a.id == 'delist');
      state = t.to!;
      data = applyEffects(t.effects, 'tabletop-member-owner', data);
      expect(state, 'delisted');

      // Prove the two axes: at every borrow/return step, top-level state
      // was "published" while availabilityState toggled independently.
      // This is the proof — no test needed at the end because each step
      // already asserts it.
    });
  });

  // -------------------------------------------------------------------------
  // 5. §2a renderBindings role resolution
  // -------------------------------------------------------------------------

  group('§2a renderBindings role resolution', () {
    late LoomWorkflowStateMachine machine;

    setUp(() {
      machine = _parseFixture('equipment-loan');
    });

    test('role "any" matches regardless of persona roles', () {
      // published state has one binding: role = "any".
      final bindings = resolveBindings(
        machine,
        'published',
        [], // persona with no roles
      );
      expect(bindings.length, 1);
      expect(bindings.first.role, 'any');
      expect(bindings.first.tabId, 'marketplace');
    });

    test('actor role matches on draft state', () {
      final bindings = resolveBindings(
        machine,
        'draft',
        {'actor'}, // persona holding the actor role
      );
      expect(bindings.length, 1);
      expect(bindings.first.role, 'actor');
      expect(bindings.first.cardSurfaceFamily, 'listing-editor');
    });

    test('actor role does NOT match if persona only holds receiver role on draft', () {
      final bindings = resolveBindings(
        machine,
        'draft',
        {'receiver'},
      );
      // draft binding is role: "actor" only — receiver doesn't match.
      expect(bindings, isEmpty);
    });

    test(
        'persona holding TWO roles on pending-review resolves BOTH matching bindings',
        () {
      // pending-review has two bindings:
      //   role: "actor"   → listing-status-badge (summary)
      //   role: "receiver" → listing-review-queue-item (primary)
      final bindings = resolveBindings(
        machine,
        'pending-review',
        {'actor', 'receiver'},
      );
      expect(bindings.length, 2,
          reason: 'both actor and receiver bindings must resolve');

      final families =
          bindings.map((b) => b.cardSurfaceFamily).toSet();
      expect(families,
          contains('listing-status-badge'));
      expect(families,
          contains('listing-review-queue-item'));
    });

    test('persona holding only one of the two roles gets only that binding', () {
      final bindings = resolveBindings(
        machine,
        'pending-review',
        {'receiver'},
      );
      expect(bindings.length, 1);
      expect(bindings.first.cardSurfaceFamily,
          'listing-review-queue-item');
    });

    test('state not listed in any binding returns empty', () {
      final bindings = resolveBindings(
        machine,
        'nonexistent-state',
        {'any'},
      );
      expect(bindings, isEmpty);
    });
  });
}