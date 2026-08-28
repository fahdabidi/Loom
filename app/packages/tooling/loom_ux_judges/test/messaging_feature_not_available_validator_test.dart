import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

const _findingType = 'messaging_feature_not_available';

LoomWorkflowStateMachine _machine({
  String workflowType = 'discussion-message',
  String family = 'discussionThread',
  required List<Map<String, dynamic>> transitions,
  Map<String, dynamic> schema = const {},
}) => LoomWorkflowStateMachine.fromJson({
  'initialState': 'active',
  'states': {
    'active': {'label': 'Active'},
    'archived': {'label': 'Archived', 'isTerminal': true},
  },
  'transitions': transitions,
  'instanceDataSchema': schema,
  'renderBindings': [
    {
      'states': ['active', 'archived'],
      'audience': 'any',
      'tabId': 'messages',
      'cardSurfaceFamily': family,
      'bindingKind': 'primary',
    },
  ],
}, workflowType);

List<ValidationFinding> _findings(ValidationReport report) =>
    report.findings.where((finding) => finding.type == _findingType).toList();

ValidationReport _validate({
  String workflowType = 'discussion-message',
  String family = 'discussionThread',
  required List<Map<String, dynamic>> transitions,
  Map<String, dynamic> schema = const {},
}) => WorkflowValidator().validate({
  workflowType: _machine(
    workflowType: workflowType,
    family: family,
    transitions: transitions,
    schema: schema,
  ),
});

Map<String, dynamic> _transition(
  String id, {
  String? label,
  String? to,
  List<Map<String, dynamic>> effects = const [],
}) => {
  'id': id,
  'label': label ?? id,
  'from': ['active'],
  'to': to,
  if (effects.isNotEmpty) 'effects': effects,
};

void main() {
  group('messaging_feature_not_available', () {
    test('warns for a no-op mute transition on a discussion thread', () {
      final findings = _findings(
        _validate(transitions: [_transition('mute-thread', label: 'Mute')]),
      );

      expect(findings, hasLength(1));
      expect(findings.single.isWarning, isTrue);
      expect(
        findings.single.location,
        equals(
          'experience/workflowDefinitions/discussion-message/transitions/'
          'mute-thread',
        ),
      );
      for (final phrase in [
        'mute-thread',
        'discussion-message',
        'per-member thread state',
        'messaging tab, which is not implemented',
        'Gaps',
        'messaging_feature_not_available',
        'docs/API/OpenAPI/community-surfaces/messaging-api.openapi.yaml',
        'messages themselves stay a workflow',
      ]) {
        expect(findings.single.message, contains(phrase));
      }
    });

    test('warns for unmute without mistaking it for a mute substring', () {
      final findings = _findings(
        _validate(transitions: [_transition('unmute-thread', label: 'Unmute')]),
      );

      expect(findings, hasLength(1));
      expect(findings.single.location, endsWith('transitions/unmute-thread'));
    });

    test('does not match mute inside an unrelated word', () {
      expect(
        _findings(
          _validate(
            transitions: [
              _transition('commute-thread', label: 'Commute thread'),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('warns for both mark-thread-read and mark-thread-unread', () {
      final findings = _findings(
        _validate(
          transitions: [
            _transition('mark-thread-read', label: 'Mark read'),
            _transition('mark-thread-unread', label: 'Mark unread'),
          ],
        ),
      );

      expect(findings, hasLength(2));
      expect(
        findings.map((finding) => finding.location),
        containsAll([
          endsWith('transitions/mark-thread-read'),
          endsWith('transitions/mark-thread-unread'),
        ]),
      );
    });

    test('warns for a read-position transition', () {
      expect(
        _findings(
          _validate(
            transitions: [_transition('update', label: 'Update read position')],
          ),
        ),
        hasLength(1),
      );
    });

    test('is silent for posting and replying on a discussion thread', () {
      final findings = _findings(
        _validate(
          transitions: [
            _transition('post-message', label: 'Post message'),
            _transition('reply', label: 'Reply'),
          ],
        ),
      );

      expect(findings, isEmpty);
    });

    test('is silent for archiving a discussion thread', () {
      expect(
        _findings(
          _validate(transitions: [_transition('archive', label: 'Archive')]),
        ),
        isEmpty,
      );
    });

    test(
      'is silent when a mute transition changes state or carries effects',
      () {
        final stateChange = _findings(
          _validate(
            transitions: [
              _transition('mute-thread', label: 'Mute', to: 'archived'),
            ],
          ),
        );
        final effect = _findings(
          _validate(
            schema: {
              'muted': {'type': 'bool'},
            },
            transitions: [
              _transition(
                'mute-thread',
                label: 'Mute',
                effects: [
                  {'op': 'set', 'key': 'muted', 'value': true},
                ],
              ),
            ],
          ),
        );

        expect(stateChange, isEmpty);
        expect(effect, isEmpty);
      },
    );

    test('is silent for mute-notifications outside a thread workflow', () {
      expect(
        _findings(
          _validate(
            workflowType: 'notification-preferences',
            family: 'notificationInbox',
            transitions: [
              _transition('mute-notifications', label: 'Mute notifications'),
            ],
          ),
        ),
        isEmpty,
      );
    });
  });
}
