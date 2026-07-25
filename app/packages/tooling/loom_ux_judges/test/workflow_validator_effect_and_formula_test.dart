import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

LoomWorkflowStateMachine _machine(
  String workflowType, {
  Map<String, dynamic> schema = const {},
  Map<String, dynamic> guard = const {},
  List<Map<String, dynamic>> effects = const [],
}) => LoomWorkflowStateMachine.fromJson({
  'initialState': 'start',
  'states': {
    'start': {'label': 'Start'},
    'done': {'label': 'Done', 'isTerminal': true},
  },
  'transitions': [
    {
      'id': 'continue',
      'label': 'Continue',
      'from': ['start'],
      'to': 'done',
      if (guard.isNotEmpty) 'guard': guard,
      if (effects.isNotEmpty) 'effects': effects,
    },
  ],
  'instanceDataSchema': schema,
}, workflowType);

ValidationReport _validate(
  Map<String, dynamic> sourceSchema, {
  Map<String, dynamic> guard = const {},
  List<Map<String, dynamic>> effects = const [],
  Map<String, LoomWorkflowStateMachine> extraWorkflows = const {},
}) {
  final source = _machine(
    'source',
    schema: sourceSchema,
    guard: guard,
    effects: effects,
  );
  return WorkflowValidator().validate({'source': source, ...extraWorkflows});
}

bool _has(ValidationReport report, String type) =>
    report.errors.any((finding) => finding.type == type);

void main() {
  group('WorkflowValidator effects and transition formulas', () {
    test('catches an undeclared key in a nested branch effect', () {
      final report = _validate(
        {
          'x': {'type': 'string'},
        },
        effects: [
          {
            'op': 'branch',
            'if': 'x == "yes"',
            'then': [
              {'op': 'set', 'key': 'notDeclared', 'value': true},
            ],
          },
        ],
      );

      expect(_has(report, 'dangling_instance_data_key'), isTrue);
    });

    test('allows a cross-instance set whose target key is not local', () {
      final report = _validate(
        {
          'eventId': {'type': 'string'},
        },
        effects: [
          {
            'op': 'set',
            'key': 'selectedGame',
            'relatedInstance': 'eventId',
            'value': '{winner}',
          },
        ],
      );

      expect(
        report.errors.where(
          (finding) =>
              finding.type == 'dangling_instance_data_key' &&
              finding.message.contains('selectedGame'),
        ),
        isEmpty,
      );
    });

    test('catches an undeclared cross-instance field', () {
      final report = _validate(
        {
          'eventId': {'type': 'string'},
        },
        effects: [
          {
            'op': 'set',
            'key': 'selectedGame',
            'relatedInstance': 'noSuchField',
          },
        ],
      );

      expect(_has(report, 'dangling_related_instance_field'), isTrue);
    });

    test('catches createInstance with an unknown target', () {
      final report = _validate(
        {},
        effects: [
          {'op': 'createInstance', 'workflowType': 'nope'},
        ],
      );

      expect(_has(report, 'dangling_create_instance_target'), isTrue);
    });

    test('catches createInstance fields absent from its target schema', () {
      final report = _validate(
        {},
        effects: [
          {
            'op': 'createInstance',
            'workflowType': 'target',
            'fields': {'notOnTarget': 1},
          },
        ],
        extraWorkflows: {'target': _machine('target')},
      );

      expect(_has(report, 'dangling_instance_data_key'), isTrue);
    });

    test('catches createInstance writing a computed target field', () {
      final report = _validate(
        {},
        effects: [
          {
            'op': 'createInstance',
            'workflowType': 'target',
            'fields': {'computed': 1},
          },
        ],
        extraWorkflows: {
          'target': _machine(
            'target',
            schema: {
              'computed': {'type': 'number', 'formula': '1'},
            },
          ),
        },
      );

      expect(_has(report, 'computed_field_written_by_effect'), isTrue);
    });

    test('catches an unknown effect operation', () {
      final report = _validate(
        {},
        effects: [
          {'op': 'frobnicate'},
        ],
      );

      expect(_has(report, 'unknown_effect_op'), isTrue);
    });

    test('validates transitionRelated references and recognizes the op', () {
      final target = _machine(
        'target',
        schema: {
          'createdAt': {'type': 'text'},
        },
      );
      final wellFormed = _validate(
        {},
        effects: [
          {
            'op': 'transitionRelated',
            'relatedQuery': {
              'workflowType': 'target',
              'filter': {r'$state': 'open'},
              'sortKey': 'createdAt',
              'limit': 1,
            },
            'transitionId': 'continue',
          },
        ],
        extraWorkflows: {'target': target},
      );
      expect(_has(wellFormed, 'unknown_effect_op'), isFalse);
      expect(wellFormed.passed, isTrue, reason: wellFormed.findings.join('\n'));

      final missingType = _validate(
        {},
        effects: [
          {
            'op': 'transitionRelated',
            'relatedQuery': {
              'workflowType': 'missing',
              'filter': <String, dynamic>{},
            },
            'transitionId': 'continue',
          },
        ],
      );
      expect(
        _has(missingType, 'dangling_transition_related_workflow_type'),
        isTrue,
      );

      final badTransition = _validate(
        {},
        effects: [
          {
            'op': 'transitionRelated',
            'relatedQuery': {
              'workflowType': 'target',
              'filter': <String, dynamic>{},
            },
            'transitionId': 'missing',
          },
        ],
        extraWorkflows: {'target': target},
      );
      expect(
        _has(badTransition, 'dangling_transition_related_transition_id'),
        isTrue,
      );

      final badSortKey = _validate(
        {},
        effects: [
          {
            'op': 'transitionRelated',
            'relatedQuery': {
              'workflowType': 'target',
              'filter': <String, dynamic>{},
              'sortKey': 'missing',
            },
            'transitionId': 'continue',
          },
        ],
        extraWorkflows: {'target': target},
      );
      expect(
        _has(badSortKey, 'dangling_transition_related_sort_key'),
        isTrue,
      );
    });

    test('catches an unknown field in a guard formula', () {
      final report = _validate({}, guard: {'formula': 'size(nope) > 1'});

      expect(_has(report, 'unknown_formula_field'), isTrue);
    });

    test('catches an unknown function in a branch condition', () {
      final report = _validate(
        {
          'x': {'type': 'number'},
        },
        effects: [
          {'op': 'branch', 'if': 'bogusFn(x)'},
        ],
      );

      expect(_has(report, 'unknown_formula_function'), isTrue);
    });

    test('a valid effect and formula definition stays clean', () {
      final report = _validate(
        {
          'eventId': {'type': 'string'},
          'x': {'type': 'number'},
          'total': {'type': 'number', 'formula': 'x + 1'},
        },
        guard: {
          'formula': 'x > 0',
          'relatedInstanceField': 'eventId',
          'relatedListField': 'participants',
        },
        effects: [
          {
            'op': 'branch',
            'if': 'x > 1',
            'then': [
              {'op': 'set', 'key': 'x', 'value': 2},
            ],
          },
          {'op': 'set', 'key': 'selectedGame', 'relatedInstance': 'eventId'},
        ],
      );

      expect(report.passed, isTrue, reason: report.findings.join('\n'));
    });
  });
}
