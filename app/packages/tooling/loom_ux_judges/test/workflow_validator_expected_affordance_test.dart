// Tests for the "expected affordance" warning class: a workflow type that
// implements one half of a create/edit/cancel pattern but silently omits the
// other half. See workflow_validator.dart's editable_fields_without_edit_guard,
// no_creation_path_for_editable_type, and no_destructive_exit_for_managed_type
// checks.

import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(
  String workflowType, {
  required Map<String, dynamic> states,
  required List<Map<String, dynamic>> transitions,
  Map<String, dynamic> schema = const {},
  List<Map<String, dynamic>> renderBindings = const [],
  Map<String, dynamic>? visibility,
}) => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': states,
  'transitions': transitions,
  'instanceDataSchema': schema,
  if (renderBindings.isNotEmpty) 'renderBindings': renderBindings,
  if (visibility != null) 'visibility': visibility,
}, workflowType);

ValidationReport _validate(Map<String, LoomWorkflowStateMachine> workflows) =>
    WorkflowValidator().validate(workflows);

bool _hasWarning(ValidationReport report, String type) =>
    report.warnings.any((f) => f.type == type);

void main() {
  group('no_render_binding_for_reachable_state', () {
    test('fires for a reachable state not covered by renderBinding states', () {
      final report = _validate({
        'event': _machine(
          'event',
          states: {
            'open': {'label': 'Open'},
            'pending-review': {'label': 'Pending Review'},
          },
          transitions: [
            {
              'id': 'submit',
              'label': 'Submit',
              'from': ['open'],
              'to': 'pending-review',
            },
          ],
          renderBindings: [
            {
              'states': ['open'],
              'role': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'summary',
            },
          ],
          visibility: {'default': 'public'},
        ),
      });

      expect(
        report.warnings.where(
          (finding) =>
              finding.type == 'no_render_binding_for_reachable_state',
        ),
        hasLength(1),
      );
      expect(
        report.warnings.any(
          (finding) =>
              finding.type == 'no_render_binding_for_reachable_state' &&
              finding.location == 'event/states/pending-review',
        ),
        isTrue,
      );
    });

    test('does not fire for an unreachable state lacking renderBinding coverage', () {
      final report = _validate({
        'event': _machine(
          'event',
          states: {
            'open': {'label': 'Open'},
            'under-review': {'label': 'Under Review'},
            'orphan': {'label': 'Orphan', 'isTerminal': true},
          },
          transitions: [
            {
              'id': 'submit',
              'label': 'Submit',
              'from': ['open'],
              'to': 'under-review',
            },
          ],
          renderBindings: [
            {
              'states': ['open', 'under-review'],
              'role': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'summary',
            },
          ],
          visibility: {'default': 'public'},
        ),
      });

      expect(report.errors, isNotEmpty, reason: 'unreachable_state should remain');
      expect(
        report.errors.any(
          (finding) => finding.type == 'unreachable_state',
        ),
        isTrue,
      );
      expect(
        report.warnings.any(
          (finding) => finding.type == 'no_render_binding_for_reachable_state',
        ),
        isFalse,
      );
    });
  });

  group('no_read_visibility_declared', () {
    test('fires exactly once when a workflow omits visibility', () {
      final report = _validate({
        'event': _machine(
          'event',
          states: {
            'open': {'label': 'Open'},
          },
          transitions: [
            {
              'id': 'noop',
              'label': 'Noop',
              'from': ['open'],
              'to': null,
            },
          ],
          renderBindings: [
            {
              'states': ['open'],
              'role': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'summary',
            },
          ],
        ),
      });

      expect(
        report.warnings.where(
          (finding) => finding.type == 'no_read_visibility_declared',
        ),
        hasLength(1),
      );
      expect(report.warnings, hasLength(1));
      expect(report.passed, isTrue, reason: 'warnings never block pass');
    });

    test('does not fire when visibility is declared', () {
      final report = _validate({
        'event': _machine(
          'event',
          states: {
            'open': {'label': 'Open'},
          },
          transitions: [
            {
              'id': 'noop',
              'label': 'Noop',
              'from': ['open'],
              'to': null,
            },
          ],
          renderBindings: [
            {
              'states': ['open'],
              'role': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'summary',
            },
          ],
          visibility: {'default': 'public'},
        ),
      });

      expect(_hasWarning(report, 'no_read_visibility_declared'), isFalse);
      expect(report.warnings, isEmpty);
    });
  });

  group('editable_fields_without_edit_guard', () {
    test('fires when editableFields is set with no editGuard', () {
      final machine = _machine(
        'event',
        states: {
          'open': {
            'label': 'Open',
            'editableFields': ['title'],
          },
        },
        transitions: [
          {
            'id': 'noop',
            'label': 'Noop',
            'from': ['open'],
            'to': null,
          },
        ],
        schema: {
          'title': {'type': 'text', 'writableBy': 'formEntry'},
        },
      );

      final report = _validate({'event': machine});

      expect(_hasWarning(report, 'editable_fields_without_edit_guard'), isTrue);
      expect(report.passed, isTrue, reason: 'warnings never block pass');
    });

    test('does not fire when editGuard is present', () {
      final machine = _machine(
        'event',
        states: {
          'open': {
            'label': 'Open',
            'editableFields': ['title'],
            'editGuard': {
              'allowedPersonaIds': ['organizer'],
            },
          },
        },
        transitions: [
          {
            'id': 'noop',
            'label': 'Noop',
            'from': ['open'],
            'to': null,
          },
        ],
        schema: {
          'title': {'type': 'text', 'writableBy': 'formEntry'},
        },
      );

      final report = _validate({'event': machine});

      expect(_hasWarning(report, 'editable_fields_without_edit_guard'), isFalse);
    });

    test('does not fire when editableFields is absent', () {
      final machine = _machine(
        'event',
        states: {
          'open': {'label': 'Open'},
        },
        transitions: [
          {
            'id': 'noop',
            'label': 'Noop',
            'from': ['open'],
            'to': null,
          },
        ],
      );

      final report = _validate({'event': machine});

      expect(_hasWarning(report, 'editable_fields_without_edit_guard'), isFalse);
    });
  });

  group('no_creation_path_for_editable_type', () {
    LoomWorkflowStateMachine editableType({
      List<Map<String, dynamic>> renderBindings = const [],
    }) => _machine(
      'event',
      states: {
        'open': {
          'label': 'Open',
          'editableFields': ['title'],
          'editGuard': {
            'allowedPersonaIds': ['organizer'],
          },
        },
      },
      transitions: [
        {
          'id': 'noop',
          'label': 'Noop',
          'from': ['open'],
          'to': null,
        },
      ],
      schema: {
        'title': {'type': 'text', 'writableBy': 'formEntry'},
      },
      renderBindings: renderBindings,
    );

    test('fires when no create action and no creation effect target the type', () {
      final report = _validate({'event': editableType()});

      expect(_hasWarning(report, 'no_creation_path_for_editable_type'), isTrue);
    });

    test('does not fire when a create action targets the type', () {
      final machine = editableType(
        renderBindings: [
          {
            'states': ['open'],
            'role': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'primary',
            'actions': [
              {
                'kind': 'create',
                'label': 'New event',
                'scope': 'tab',
                'presentation': 'fab',
              },
            ],
          },
        ],
      );

      final report = _validate({'event': machine});

      expect(_hasWarning(report, 'no_creation_path_for_editable_type'), isFalse);
    });

    test('does not fire when another type\'s effect creates it via createInstance', () {
      final creator = _machine(
        'trigger',
        states: {
          'open': {'label': 'Open'},
        },
        transitions: [
          {
            'id': 'spawn',
            'label': 'Spawn',
            'from': ['open'],
            'to': null,
            'effects': [
              {
                'op': 'createInstance',
                'workflowType': 'event',
                'fields': {'title': 'x'},
              },
            ],
          },
        ],
      );

      final report = _validate({'event': editableType(), 'trigger': creator});

      expect(_hasWarning(report, 'no_creation_path_for_editable_type'), isFalse);
    });

    test('fires for a type with only effect-written fields and no creation path', () {
      final machine = _machine(
        'event-rsvp-response',
        states: {
          'pending': {'label': 'Pending'},
        },
        transitions: [
          {
            'id': 'go',
            'label': 'Going',
            'from': ['pending'],
            'to': null,
          },
        ],
        schema: {
          'eventId': {'type': 'text', 'writableBy': 'effect'},
        },
      );

      final report = _validate({'event-rsvp-response': machine});

      expect(_hasWarning(report, 'no_creation_path_for_editable_type'), isTrue);
    });

    test('does not fire when fields are purely computed/formula', () {
      final machine = _machine(
        'event-rsvp-response',
        states: {
          'pending': {'label': 'Pending'},
        },
        transitions: [
          {
            'id': 'noop',
            'label': 'Noop',
            'from': ['pending'],
            'to': null,
          },
        ],
        schema: {
          'computed': {'type': 'text', 'formula': '""'},
        },
        renderBindings: [
          {
            'states': ['pending'],
            'role': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'summary',
          },
        ],
      );

      final report = _validate({'event-rsvp-response': machine});

      expect(
        _hasWarning(report, 'no_creation_path_for_editable_type'),
        isFalse,
      );
    });
  });

  group('destructive_transition_ignores_availability_field', () {
    LoomWorkflowStateMachine machine({
      bool destructiveGuardsAvailability = false,
      bool siblingGuardsAvailability = true,
    }) =>
        _machine(
          'event',
          states: {
            'open': {'label': 'Open'},
            'delisted': {'label': 'Delisted', 'isTerminal': true},
            'cancelled': {'label': 'Cancelled'},
          },
          transitions: [
            {
              'id': 'cancel',
              'label': 'Cancel',
              'from': ['open'],
              'to': 'cancelled',
              if (siblingGuardsAvailability)
                'guard': {
                  'instanceDataEquals': {
                    'key': 'availabilityState',
                    'value': 'listed',
                  },
                },
            },
            {
              'id': 'delist',
              'label': 'Delist',
              'from': ['open'],
              'to': 'delisted',
              if (destructiveGuardsAvailability)
                'guard': {
                  'instanceDataEquals': {
                    'key': 'availabilityState',
                    'value': 'listed',
                  },
                },
            },
          ],
          schema: {
            'availabilityState': {'type': 'text', 'writableBy': 'formEntry'},
          },
          renderBindings: [
            {
              'states': ['open', 'cancelled', 'delisted'],
              'role': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'primary',
            },
            {
              'states': ['open', 'cancelled', 'delisted'],
              'role': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'summary',
              'actions': [
                {
                  'kind': 'create',
                  'label': 'New event',
                  'scope': 'tab',
                  'presentation': 'fab',
                },
              ],
            },
          ],
          visibility: {'default': 'public'},
        );

    test(
      'fires when destructive terminal transition lacks availability guard on this workflow',
      () {
        final report = _validate({'event': machine()});

        expect(
          report.warnings.any(
            (f) =>
                f.type == 'destructive_transition_ignores_availability_field' &&
                f.location == 'event/transitions/delist',
          ),
          isTrue,
        );
      },
    );

    test(
      'does not fire when destructive transition checks availability like its sibling',
      () {
        final report = _validate({
          'event': machine(destructiveGuardsAvailability: true),
        });

        expect(
          report.warnings.any(
            (f) => f.type == 'destructive_transition_ignores_availability_field',
          ),
          isFalse,
        );
      },
    );

    // Regression test: the sibling-match helper's formula check must actually
    // substitute the field name into its word-boundary regex (a prior version
    // built the pattern from a raw string literal, which cannot interpolate
    // ${...} at all, so the formula branch silently never matched anything).
    LoomWorkflowStateMachine formulaGuardedMachine({
      bool destructiveGuardsAvailability = false,
    }) =>
        _machine(
          'listing',
          states: {
            'open': {'label': 'Open'},
            'delisted': {'label': 'Delisted', 'isTerminal': true},
            'cancelled': {'label': 'Cancelled'},
          },
          transitions: [
            {
              'id': 'cancel',
              'label': 'Cancel',
              'from': ['open'],
              'to': 'cancelled',
              'guard': {'formula': 'availabilityState == "available"'},
            },
            {
              'id': 'delist',
              'label': 'Delist',
              'from': ['open'],
              'to': 'delisted',
              if (destructiveGuardsAvailability)
                'guard': {'formula': 'availabilityState == "available"'},
            },
          ],
          schema: {
            'availabilityState': {'type': 'text', 'writableBy': 'formEntry'},
          },
          renderBindings: [
            {
              'states': ['open', 'cancelled', 'delisted'],
              'role': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'primary',
            },
          ],
          visibility: {'default': 'public'},
        );

    test(
      'fires when the sibling guards availability via formula, not instanceDataEquals',
      () {
        final report = _validate({'listing': formulaGuardedMachine()});

        expect(
          report.warnings.any(
            (f) =>
                f.type == 'destructive_transition_ignores_availability_field' &&
                f.location == 'listing/transitions/delist',
          ),
          isTrue,
        );
      },
    );

    test(
      'does not fire when the destructive transition itself guards availability via formula',
      () {
        final report = _validate({
          'listing': formulaGuardedMachine(destructiveGuardsAvailability: true),
        });

        expect(
          report.warnings.any(
            (f) => f.type == 'destructive_transition_ignores_availability_field',
          ),
          isFalse,
        );
      },
    );
  });

  group('possible_fabricated_identifier', () {
    test('fires when hardcoded identifier-like value is set by set effect', () {
      final report = _validate({
        'event': _machine(
          'event',
          states: {
            'open': {'label': 'Open'},
          },
          transitions: [
            {
              'id': 'complete',
              'label': 'Complete',
              'from': ['open'],
              'to': null,
              'effects': [
                {
                  'op': 'branch',
                  'if': 'true',
                  'then': [
                    {
                      'op': 'set',
                      'key': 'checksum',
                      'value': 'sha256-chess-2026',
                    },
                  ],
                },
              ],
            },
          ],
          schema: {
            'checksum': {'type': 'text'},
          },
          renderBindings: [
            {
              'states': ['open'],
              'role': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'primary',
            },
          ],
          visibility: {'default': 'public'},
        ),
      });

      expect(
        report.warnings.where(
          (f) => f.type == 'possible_fabricated_identifier',
        ),
        hasLength(1),
      );
      expect(
        report.warnings.any(
              (f) =>
                  f.type == 'possible_fabricated_identifier' &&
                  f.message.contains('sha256-chess-2026') &&
              f.location.startsWith('event/'),
        ),
        isTrue,
      );
    });

    test('does not fire when identifier fields are set from templates', () {
      final report = _validate({
        'event': _machine(
          'event',
          states: {
            'open': {'label': 'Open'},
          },
          transitions: [
            {
              'id': 'complete',
              'label': 'Complete',
              'from': ['open'],
              'to': null,
              'effects': [
                {
                  'op': 'set',
                  'key': 'checksum',
                  'value': '{checksumValue}',
                },
              ],
            },
          ],
          schema: {
            'checksum': {'type': 'text'},
          },
          renderBindings: [
            {
              'states': ['open'],
              'role': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'primary',
              'actions': [
                {
                  'kind': 'create',
                  'label': 'New event',
                  'scope': 'tab',
                  'presentation': 'fab',
                },
              ],
            },
          ],
          visibility: {'default': 'public'},
        ),
      });

      expect(
        report.warnings.any(
          (f) => f.type == 'possible_fabricated_identifier',
        ),
        isFalse,
      );
    });
  });

  group('no_destructive_exit_for_managed_type', () {
    test('fires for a primary-bound, editGuard-managed type with no destructive transition', () {
      final machine = _machine(
        'event',
        states: {
          'open': {
            'label': 'Open',
            'editGuard': {
              'allowedPersonaIds': ['organizer'],
            },
          },
        },
        transitions: [
          {
            'id': 'noop',
            'label': 'Noop',
            'tone': 'primary',
            'from': ['open'],
            'to': null,
          },
        ],
        renderBindings: [
          {
            'states': ['open'],
            'role': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'primary',
          },
        ],
      );

      final report = _validate({'event': machine});

      expect(_hasWarning(report, 'no_destructive_exit_for_managed_type'), isTrue);
    });

    test('does not fire when a destructive-toned transition exists', () {
      final machine = _machine(
        'event',
        states: {
          'open': {
            'label': 'Open',
            'editGuard': {
              'allowedPersonaIds': ['organizer'],
            },
          },
          'cancelled': {'label': 'Cancelled', 'isTerminal': true},
        },
        transitions: [
          {
            'id': 'cancel',
            'label': 'Cancel',
            'tone': 'destructive',
            'from': ['open'],
            'to': 'cancelled',
          },
        ],
        renderBindings: [
          {
            'states': ['open'],
            'role': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'primary',
          },
        ],
      );

      final report = _validate({'event': machine});

      expect(_hasWarning(report, 'no_destructive_exit_for_managed_type'), isFalse);
    });

    test('does not fire when the type has no primary binding', () {
      final machine = _machine(
        'event',
        states: {
          'open': {
            'label': 'Open',
            'editGuard': {
              'allowedPersonaIds': ['organizer'],
            },
          },
        },
        transitions: [
          {
            'id': 'noop',
            'label': 'Noop',
            'from': ['open'],
            'to': null,
          },
        ],
        renderBindings: [
          {
            'states': ['open'],
            'role': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'summary',
          },
        ],
      );

      final report = _validate({'event': machine});

      expect(_hasWarning(report, 'no_destructive_exit_for_managed_type'), isFalse);
    });

    test('does not fire when no state declares an editGuard', () {
      final machine = _machine(
        'event',
        states: {
          'open': {'label': 'Open'},
        },
        transitions: [
          {
            'id': 'noop',
            'label': 'Noop',
            'from': ['open'],
            'to': null,
          },
        ],
        renderBindings: [
          {
            'states': ['open'],
            'role': 'any',
            'tabId': 'calendar',
            'cardSurfaceFamily': 'event-rsvp',
            'bindingKind': 'primary',
          },
        ],
      );

      final report = _validate({'event': machine});

      expect(_hasWarning(report, 'no_destructive_exit_for_managed_type'), isFalse);
    });
  });

  group('dead_role_binding', () {
    test(
      'fires for receiver role on non-admin tab without audienceMemberField',
      () {
        final report = _validate({
          'event': _machine(
            'event',
            states: {'open': {'label': 'Open'}},
            transitions: [
              {
                'id': 'noop',
                'label': 'Noop',
                'from': ['open'],
                'to': null,
              },
            ],
            visibility: {'default': 'public'},
            renderBindings: [
              {
                'states': ['open'],
                'role': 'receiver',
                'tabId': 'messages',
                'cardSurfaceFamily': 'event-rsvp',
                'bindingKind': 'summary',
              },
            ],
          ),
        });

        expect(
          report.warnings.where(
            (finding) => finding.type == 'dead_role_binding',
          ),
          hasLength(1),
        );
      },
    );

    test(
      'does not fire for receiver role on non-admin tab with audienceMemberField',
      () {
        final report = _validate({
          'event': _machine(
            'event',
            states: {'open': {'label': 'Open'}},
            transitions: [
              {
                'id': 'noop',
                'label': 'Noop',
                'from': ['open'],
                'to': null,
              },
            ],
            visibility: {'default': 'public'},
            renderBindings: [
              {
                'states': ['open'],
                'role': 'receiver',
                'tabId': 'messages',
                'cardSurfaceFamily': 'event-rsvp',
                'bindingKind': 'summary',
                'audienceMemberField': 'recipientPersonaId',
              },
            ],
          ),
        });

        expect(
          report.warnings.where(
            (finding) => finding.type == 'dead_role_binding',
          ),
          isEmpty,
        );
      },
    );

    test('does not fire for receiver role on admin tab', () {
      final report = _validate({
        'event': _machine(
          'event',
          states: {'open': {'label': 'Open'}},
          transitions: [
            {
              'id': 'noop',
              'label': 'Noop',
              'from': ['open'],
              'to': null,
            },
          ],
          visibility: {'default': 'public'},
          renderBindings: [
            {
              'states': ['open'],
              'role': 'receiver',
              'tabId': 'admin',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'summary',
            },
          ],
        ),
      });

      expect(
        report.warnings.where(
          (finding) => finding.type == 'dead_role_binding',
        ),
        isEmpty,
      );
    });

    test('fires for actor role on calendar tab', () {
      final report = _validate({
        'event': _machine(
          'event',
          states: {'open': {'label': 'Open'}},
          transitions: [
            {
              'id': 'noop',
              'label': 'Noop',
              'from': ['open'],
              'to': null,
            },
          ],
          visibility: {'default': 'public'},
          renderBindings: [
            {
              'states': ['open'],
              'role': 'actor',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'summary',
            },
          ],
        ),
      });

      expect(
        report.warnings.where(
          (finding) => finding.type == 'dead_role_binding',
        ),
        hasLength(1),
      );
    });

    test('does not fire for any role on calendar tab', () {
      final report = _validate({
        'event': _machine(
          'event',
          states: {'open': {'label': 'Open'}},
          transitions: [
            {
              'id': 'noop',
              'label': 'Noop',
              'from': ['open'],
              'to': null,
            },
          ],
          visibility: {'default': 'public'},
          renderBindings: [
            {
              'states': ['open'],
              'role': 'any',
              'tabId': 'calendar',
              'cardSurfaceFamily': 'event-rsvp',
              'bindingKind': 'summary',
            },
          ],
        ),
      });

      expect(
        report.warnings.where(
          (finding) => finding.type == 'dead_role_binding',
        ),
        isEmpty,
      );
    });
  });
}
