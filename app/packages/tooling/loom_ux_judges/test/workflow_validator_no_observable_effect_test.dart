import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

const _findingType = 'transition_has_no_observable_effect';

LoomWorkflowStateMachine _machine({
  String action = 'acknowledge',
  String? to,
  List<String> from = const ['active'],
  List<Map<String, dynamic>> effects = const [],
  Map<String, dynamic> schema = const {},
}) => LoomWorkflowStateMachine.fromJson({
  'initialState': 'active',
  'states': {
    'active': {'label': 'Active'},
    if (to == 'done') 'done': {'label': 'Done', 'isTerminal': true},
  },
  'transitions': [
    {
      'id': 'acknowledge-item',
      'label': 'Acknowledge',
      'action': action,
      'from': from,
      'to': to,
      if (effects.isNotEmpty) 'effects': effects,
    },
  ],
  'instanceDataSchema': schema,
  'renderBindings': [
    {
      'states': ['active', if (to == 'done') 'done'],
      'audience': 'any',
      'tabId': 'home',
      'cardSurfaceFamily': 'statusTimeline',
      'bindingKind': 'primary',
    },
  ],
}, 'subject');

ValidationReport _validate({
  String action = 'acknowledge',
  String? to,
  List<String> from = const ['active'],
  List<Map<String, dynamic>> effects = const [],
  Map<String, dynamic> schema = const {},
  Map<String, LoomWorkflowStateMachine> additionalWorkflows = const {},
}) => WorkflowValidator().validate({
  'subject': _machine(
    action: action,
    to: to,
    from: from,
    effects: effects,
    schema: schema,
  ),
  ...additionalWorkflows,
});

List<ValidationFinding> _findings(ValidationReport report) =>
    report.findings.where((finding) => finding.type == _findingType).toList();

void main() {
  group('transition_has_no_observable_effect', () {
    test('warns for an acknowledge with no state change or effects', () {
      final findings = _findings(_validate());

      expect(findings, hasLength(1));
      expect(findings.single.isWarning, isTrue);
      expect(
        findings.single.location,
        equals(
          'experience/workflowDefinitions/subject/transitions/acknowledge-item',
        ),
      );
      for (final phrase in [
        'acknowledge-item',
        'subject',
        'leaves the instance unchanged',
        'nothing records that the action happened',
        r'append $actor',
        'set a status',
        'Gaps',
        _findingType,
      ]) {
        expect(findings.single.message, contains(phrase));
      }
    });

    test('is silent when an effect records the action', () {
      final findings = _findings(
        _validate(
          schema: {
            'acknowledged': {'type': 'bool'},
          },
          effects: [
            {'op': 'set', 'key': 'acknowledged', 'value': true},
          ],
        ),
      );

      expect(findings, isEmpty);
    });

    test('is silent when the transition changes state', () {
      expect(_findings(_validate(to: 'done')), isEmpty);
    });

    test('warns for a no-effect self-loop with one source state', () {
      expect(_findings(_validate(to: 'active')), hasLength(1));
    });

    test('is silent for client-performed actions with no JSON effect', () {
      for (final action in const ['download', 'open', 'share', 'preview']) {
        expect(
          _findings(_validate(action: action)),
          isEmpty,
          reason: '$action is completed by the client.',
        );
      }
    });

    test('is silent for a platform-completed upload', () {
      expect(_findings(_validate(action: 'upload')), isEmpty);
    });

    test('is silent when the only write is under onSuccessEffects', () {
      final target = LoomWorkflowStateMachine.fromJson({
        'initialState': 'active',
        'states': {
          'active': {'label': 'Active'},
        },
        'transitions': [
          {
            'id': 'record',
            'label': 'Record',
            'action': 'open',
            'from': ['active'],
            'to': null,
          },
        ],
        'instanceDataSchema': {
          'recorded': {'type': 'bool'},
        },
        'renderBindings': [
          {
            'states': ['active'],
            'audience': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'statusTimeline',
            'bindingKind': 'primary',
          },
        ],
      }, 'target');

      final findings = _findings(
        _validate(
          effects: [
            {
              'op': 'transitionRelated',
              'relatedQuery': {
                'workflowType': 'target',
                'filter': <String, dynamic>{},
              },
              'transitionId': 'record',
              'onSuccessEffects': [
                {'op': 'set', 'key': 'recorded', 'value': true},
              ],
            },
          ],
          additionalWorkflows: {'target': target},
        ),
      );

      expect(findings, isEmpty);
    });
  });
}
