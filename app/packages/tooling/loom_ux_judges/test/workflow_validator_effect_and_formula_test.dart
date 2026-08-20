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

Map<String, dynamic> _validRecurringEffect() => {
  'op': 'generateRecurringInstances',
  'workflowType': 'event-rsvp',
  'anchorField': 'eventDate',
  'fields': {
    'title': '{title}',
    'eventDate': '{eventDate}',
    'location': '{location}',
  },
  'recurrenceRule': {
    'freq': 'weekly',
    'interval': 1,
    'count': 12,
    'byDayOfWeek': ['FR'],
  },
};

LoomWorkflowStateMachine _recurringTarget() => _machine(
  'event-rsvp',
  schema: {
    'title': {'type': 'text'},
    'eventDate': {'type': 'date'},
    'location': {'type': 'text'},
    'computed': {'type': 'text', 'formula': '"computed"'},
  },
);

ValidationReport _validateRecurring(Map<String, dynamic> effect) => _validate(
  {},
  effects: [effect],
  extraWorkflows: {'event-rsvp': _recurringTarget()},
);

void main() {
  group('WorkflowValidator effects and transition formulas', () {
    test('reports an undeclared actorEqualsField key', () {
      final report = _validate(
        {},
        guard: {
          'actorEqualsField': {'key': 'recipientFanId'},
        },
      );

      expect(_has(report, 'dangling_actor_equals_field'), isTrue);
      expect(_has(report, 'actor_equals_field_on_list_type'), isFalse);
    });

    test('reports a list-typed actorEqualsField key', () {
      final report = _validate(
        {
          'recipientFanIds': {'type': 'list'},
        },
        guard: {
          'actorEqualsField': {'key': 'recipientFanIds'},
        },
      );

      expect(_has(report, 'dangling_actor_equals_field'), isFalse);
      expect(_has(report, 'actor_equals_field_on_list_type'), isTrue);
    });

    test('accepts a scalar actorEqualsField key', () {
      final report = _validate(
        {
          'recipientFanId': {'type': 'fanId'},
        },
        guard: {
          'actorEqualsField': {'key': 'recipientFanId'},
        },
      );

      expect(report.passed, isTrue, reason: report.findings.join('\n'));
      expect(_has(report, 'dangling_actor_equals_field'), isFalse);
      expect(_has(report, 'actor_equals_field_on_list_type'), isFalse);
    });

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
      expect(_has(badSortKey, 'dangling_transition_related_sort_key'), isTrue);
    });

    test(
      'validates transitionRelated onSuccessEffects against the target schema',
      () {
        final target = _machine(
          'target',
          schema: {
            'targetValue': {'type': 'text'},
          },
        );
        final report = _validate(
          {
            'sourceValue': {'type': 'text'},
          },
          effects: [
            {
              'op': 'transitionRelated',
              'relatedQuery': {
                'workflowType': 'target',
                'filter': <String, dynamic>{},
              },
              'transitionId': 'continue',
              'onSuccessEffects': [
                {'op': 'set', 'key': 'targetValue', 'value': 'updated'},
              ],
            },
          ],
          extraWorkflows: {'target': target},
        );

        expect(report.passed, isTrue, reason: report.findings.join('\n'));
      },
    );

    test('reports an undeclared field in target onSuccessEffects', () {
      final target = _machine(
        'target',
        schema: {
          'targetValue': {'type': 'text'},
        },
      );
      final report = _validate(
        {
          'sourceOnly': {'type': 'text'},
        },
        effects: [
          {
            'op': 'transitionRelated',
            'relatedQuery': {
              'workflowType': 'target',
              'filter': <String, dynamic>{},
            },
            'transitionId': 'continue',
            'onSuccessEffects': [
              {'op': 'set', 'key': 'sourceOnly', 'value': 'wrong'},
            ],
          },
        ],
        extraWorkflows: {'target': target},
      );

      expect(_has(report, 'dangling_instance_data_key'), isTrue);
    });

    test('accepts the documented generateRecurringInstances example', () {
      final report = _validateRecurring(_validRecurringEffect());

      expect(report.passed, isTrue, reason: report.findings.join('\n'));
      expect(_has(report, 'unknown_effect_op'), isFalse);
    });

    test('reports every generateRecurringInstances structural rule', () {
      final cases = <String, Map<String, dynamic>>{
        'dangling_generate_recurring_target': {
          ..._validRecurringEffect(),
          'workflowType': 'missing',
        },
        'dangling_instance_data_key': {
          ..._validRecurringEffect(),
          'fields': {'eventDate': '{eventDate}', 'unknown': 'x'},
        },
        'computed_field_written_by_effect': {
          ..._validRecurringEffect(),
          'fields': {'eventDate': '{eventDate}', 'computed': 'x'},
        },
        'missing_recurrence_anchor_field': {
          ..._validRecurringEffect(),
          'anchorField': '',
        },
        'dangling_recurrence_anchor_field': {
          ..._validRecurringEffect(),
          'anchorField': 'title',
          'fields': {'eventDate': '{eventDate}'},
        },
        'invalid_recurrence_anchor_field_type': {
          ..._validRecurringEffect(),
          'anchorField': 'title',
        },
        'missing_recurrence_rule': {
          ..._validRecurringEffect(),
          'recurrenceRule': null,
        },
      };

      for (final entry in cases.entries) {
        final report = _validateRecurring(entry.value);
        expect(_has(report, entry.key), isTrue, reason: entry.key);

        final corrected = _validateRecurring(_validRecurringEffect());
        expect(_has(corrected, entry.key), isFalse, reason: entry.key);
      }
    });

    test('reports every generateRecurringInstances recurrence rule', () {
      Map<String, dynamic> withRule(Map<String, dynamic> rule) => {
        ..._validRecurringEffect(),
        'recurrenceRule': rule,
      };
      final cases = <String, Map<String, dynamic>>{
        'missing_recurrence_freq': withRule({'count': 1}),
        'invalid_recurrence_freq': withRule({'freq': 'yearly', 'count': 1}),
        'missing_recurrence_count': withRule({'freq': 'weekly'}),
        'invalid_recurrence_count': withRule({'freq': 'weekly', 'count': 367}),
        'invalid_recurrence_interval': withRule({
          'freq': 'weekly',
          'count': 1,
          'interval': 0,
        }),
        'invalid_recurrence_weekday_code': withRule({
          'freq': 'weekly',
          'count': 1,
          'byDayOfWeek': ['XX'],
        }),
        'invalid_recurrence_month_day': withRule({
          'freq': 'monthly',
          'count': 1,
          'byMonthDay': 32,
        }),
        'invalid_recurrence_set_pos_value': withRule({
          'freq': 'monthly',
          'count': 1,
          'bySetPos': 'fifth',
        }),
        'recurrence_field_invalid_for_freq': withRule({
          'freq': 'daily',
          'count': 1,
          'byDayOfWeek': ['MO'],
        }),
        'recurrence_month_day_set_pos_conflict': withRule({
          'freq': 'monthly',
          'count': 1,
          'byMonthDay': 1,
          'bySetPos': 'first',
          'byDayOfWeek': ['MO'],
        }),
        'dangling_recurrence_set_pos_without_weekday': withRule({
          'freq': 'monthly',
          'count': 1,
          'bySetPos': 'first',
        }),
        'invalid_recurrence_set_pos_weekday_count': withRule({
          'freq': 'monthly',
          'count': 1,
          'bySetPos': 'first',
          'byDayOfWeek': ['MO', 'TU'],
        }),
        'recurrence_weekday_without_set_pos': withRule({
          'freq': 'monthly',
          'count': 1,
          'byDayOfWeek': ['MO'],
        }),
      };

      for (final entry in cases.entries) {
        final report = _validateRecurring(entry.value);
        expect(_has(report, entry.key), isTrue, reason: entry.key);

        final corrected = _validateRecurring(_validRecurringEffect());
        expect(_has(corrected, entry.key), isFalse, reason: entry.key);
      }
    });

    test('requires monthly static byDayOfWeek to have static bySetPos', () {
      final missingSetPos = _validateRecurring({
        ..._validRecurringEffect(),
        'recurrenceRule': {
          'freq': 'monthly',
          'count': 1,
          'byDayOfWeek': ['MO'],
        },
      });
      expect(_has(missingSetPos, 'recurrence_weekday_without_set_pos'), isTrue);

      final withSetPos = _validateRecurring({
        ..._validRecurringEffect(),
        'recurrenceRule': {
          'freq': 'monthly',
          'count': 1,
          'byDayOfWeek': ['MO'],
          'bySetPos': 'first',
        },
      });
      expect(_has(withSetPos, 'recurrence_weekday_without_set_pos'), isFalse);

      final tokenWeekday = _validateRecurring({
        ..._validRecurringEffect(),
        'recurrenceRule': {
          'freq': 'monthly',
          'count': 1,
          'byDayOfWeek': '{input.byDayOfWeek}',
        },
      });
      expect(_has(tokenWeekday, 'recurrence_weekday_without_set_pos'), isFalse);
    });

    test('skips static recurrence checks for runtime input tokens', () {
      final report = _validateRecurring({
        ..._validRecurringEffect(),
        'recurrenceRule': {
          'freq': '{input.freq}',
          'count': '{input.count}',
          'interval': '{input.interval}',
          'byDayOfWeek': '{input.byDayOfWeek}',
          'byMonthDay': '{input.byMonthDay}',
          'bySetPos': '{input.bySetPos}',
        },
      });

      expect(report.passed, isTrue, reason: report.findings.join('\n'));
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
