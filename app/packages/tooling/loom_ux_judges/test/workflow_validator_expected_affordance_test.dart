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

    test('does not fire for a type with only effect-written fields (e.g. a response row)', () {
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

      expect(_hasWarning(report, 'no_creation_path_for_editable_type'), isFalse);
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
}
