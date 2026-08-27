import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';
import 'package:test/test.dart';

const _findingType = 'prefill_written_field_not_platform';
const _workflowType = 'equipment-loan';
const _fieldName = 'ownerFanId';

LoomWorkflowStateMachine _machine({
  String? writableBy,
  bool isEditable = false,
  bool hasFormula = false,
}) => LoomWorkflowStateMachine.fromJson({
  'initialState': 'open',
  'states': {
    'open': {
      'label': 'Open',
      if (isEditable) 'editableFields': [_fieldName],
      if (isEditable)
        'editGuard': {
          'allowedRoleIds': ['member'],
        },
    },
    'closed': {'label': 'Closed', 'isTerminal': true},
  },
  'transitions': [
    {
      'id': 'close',
      'label': 'Close',
      'from': ['open'],
      'to': 'closed',
    },
  ],
  'renderBindings': [
    {
      'states': ['open'],
      'audience': 'any',
      'tabId': 'marketplace',
      'cardSurfaceFamily': 'equipment-loan',
      'bindingKind': 'primary',
      'actions': [
        {
          'kind': 'create',
          'label': 'List equipment',
          'scope': 'tab',
          'presentation': 'fab',
          'prefill': {_fieldName: r'$actor'},
        },
      ],
    },
  ],
  'instanceDataSchema': {
    _fieldName: {
      'type': 'fanId',
      if (writableBy != null) 'writableBy': writableBy,
      if (hasFormula) 'formula': '"platform-owner"',
    },
  },
}, _workflowType);

ValidationReport _validate({
  String? writableBy,
  bool isEditable = false,
  bool hasFormula = false,
}) => WorkflowValidator().validate({
  _workflowType: _machine(
    writableBy: writableBy,
    isEditable: isEditable,
    hasFormula: hasFormula,
  ),
});

List<ValidationFinding> _findings(ValidationReport report) => report.findings
    .where((finding) => finding.type == _findingType)
    .toList(growable: false);

void main() {
  group('prefill-written non-editable field platform writer', () {
    test(
      'effect declaration fires a warning with the schema writableBy path',
      () {
        final findings = _findings(_validate(writableBy: 'effect'));

        expect(findings, hasLength(1));
        final finding = findings.single;
        expect(finding.isWarning, isTrue);
        expect(
          finding.location,
          'experience/workflowDefinitions/$_workflowType/'
          'instanceDataSchema/$_fieldName/writableBy',
        );
        expect(finding.message, contains(_fieldName));
        expect(finding.message, contains(_workflowType));
        expect(finding.message, contains('create-action prefill'));
        expect(finding.message, contains('writableBy: "platform"'));
        expect(finding.message, contains('prefill is not an effect'));
        expect(finding.message, contains('omitting writableBy'));
      },
    );

    test('formEntry declaration fires a warning', () {
      expect(_findings(_validate(writableBy: 'formEntry')), hasLength(1));
    });

    test('omitted writableBy fires a warning', () {
      expect(_findings(_validate()), hasLength(1));
    });

    test('platform declaration stays silent', () {
      expect(_findings(_validate(writableBy: 'platform')), isEmpty);
    });

    test('member-editable prefill default stays silent', () {
      expect(
        _findings(_validate(writableBy: 'formEntry', isEditable: true)),
        isEmpty,
      );
    });

    test('formula field stays silent', () {
      expect(
        _findings(_validate(writableBy: 'effect', hasFormula: true)),
        isEmpty,
      );
    });
  });
}
