import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:test/test.dart';

Map<String, dynamic> _package(Map<String, dynamic> workflow) => {
  'specVersion': 4,
  'experience': {
    'roles': [
      {'roleId': 'board', 'label': 'Board', 'roleLabel': 'Board'},
    ],
    'workflowDefinitions': {'subject': workflow},
  },
};

Map<String, dynamic> _workflow() => {
  'initialState': 'open',
  'states': {
    'open': {'label': 'Open'},
    'done': {'label': 'Done', 'isTerminal': true},
  },
  'transitions': [
    {
      'id': 'finish',
      'label': 'Finish',
      'from': ['open'],
      'to': 'done',
    },
  ],
  'instanceDataSchema': <String, dynamic>{},
};

Map<String, dynamic> _binding({Map<String, dynamic> extra = const {}}) => {
  'states': ['open', 'done'],
  'audience': 'any',
  'tabId': 'home',
  'cardSurfaceFamily': 'default',
  'bindingKind': 'primary',
  ...extra,
};

List<ValidationFinding> _findingsOfType(
  Map<String, dynamic> workflow,
  String type,
) => CommunityPackageValidator()
    .validate(_package(workflow))
    .findings
    .where((finding) => finding.type == type)
    .toList();

List<ValidationFinding> _unknownKeys(Map<String, dynamic> workflow) =>
    _findingsOfType(workflow, 'unknown_key');

void main() {
  group('unknown_key structural validation', () {
    test(
      'visibility owner model key is unknown and sharedWith remains missing',
      () {
        final workflow = <String, dynamic>{
          'initialState': 'done',
          'states': {
            'done': {'label': 'Done', 'isTerminal': true},
          },
          'transitions': <dynamic>[],
          'instanceDataSchema': {
            'documentOwnerFanId': {'type': 'fanId'},
          },
          'visibility': {
            'default': 'guarded',
            'readGuard': {
              'allowedRoleIds': ['board'],
            },
            'fields': {'owner': 'documentOwnerFanId'},
          },
          'renderBindings': [
            {
              'states': ['done'],
              'audience': 'any',
              'tabId': 'home',
              'cardSurfaceFamily': 'documentLibrary',
              'bindingKind': 'primary',
            },
          ],
        };
        final report = CommunityPackageValidator().validate(_package(workflow));
        final unknown = report.findings
            .where((finding) => finding.type == 'unknown_key')
            .toList();

        expect(unknown, hasLength(1));
        expect(unknown.single.isWarning, isFalse);
        expect(
          unknown.single.location,
          'experience/workflowDefinitions/subject/visibility/fields/owner',
        );
        expect(unknown.single.message, contains('The parser ignores it.'));
        expect(unknown.single.message, contains('`sharedWith`'));
        expect(unknown.single.message, contains('visibility model value'));
        expect(
          report.findings.where(
            (finding) => finding.type == 'missing_visibility_fields',
          ),
          hasLength(1),
        );
      },
    );

    test('misspelled state key is reported at the state path', () {
      final workflow = _workflow();
      (workflow['states'] as Map<String, dynamic>)['open'] = {
        'label': 'Open',
        'isTerminated': false,
      };

      final unknown = _unknownKeys(workflow);
      expect(unknown, hasLength(1));
      expect(
        unknown.single.location,
        'experience/workflowDefinitions/subject/states/open/isTerminated',
      );
      expect(unknown.single.message, contains('`isTerminal`'));
    });

    test('misspelled transition key is reported at the array element', () {
      final workflow = _workflow();
      final transition = (workflow['transitions'] as List).single as Map;
      transition['guards'] = <String, dynamic>{};

      final unknown = _unknownKeys(workflow);
      expect(unknown, hasLength(1));
      expect(
        unknown.single.location,
        'experience/workflowDefinitions/subject/transitions[0]/guards',
      );
      expect(unknown.single.message, contains('`guard`'));
    });

    test('misspelled render binding key is reported at the binding', () {
      final workflow = _workflow()
        ..['renderBindings'] = [
          _binding(extra: {'cardSurface': 'default'}),
        ];

      final unknown = _unknownKeys(workflow);
      expect(unknown, hasLength(1));
      expect(
        unknown.single.location,
        'experience/workflowDefinitions/subject/renderBindings[0]/cardSurface',
      );
      expect(unknown.single.message, contains('`cardSurfaceFamily`'));
    });

    test(
      'responseTable filterableFacets and styleField remain legal binding keys',
      () {
        final workflow = _workflow()
          ..['instanceDataSchema'] = {
            'eventId': {'type': 'text'},
            'status': {'type': 'text'},
            'style': {'type': 'text'},
          }
          ..['renderBindings'] = [
            _binding(
              extra: {
                'responseTable': {
                  'workflowType': 'response',
                  'eventField': 'eventId',
                  'pendingStates': ['pending'],
                },
                'filterableFacets': [
                  {'field': 'status', 'label': 'Status'},
                ],
                'styleField': 'style',
              },
            ),
          ];

        expect(_unknownKeys(workflow), isEmpty);
      },
    );

    test('fully legal workflow produces no unknown_key finding', () {
      final workflow = _workflow()
        ..['visibility'] = {
          'default': 'membersOnly',
          'readGuard': {
            'allowedRoleIds': ['board'],
          },
          'fields': {
            'participants': ['participantFanId'],
          },
        }
        ..['instanceDataSchema'] = {
          'participantFanId': {
            'type': 'fanId',
            'required': true,
            'searchable': true,
            'itemSchema': {
              'name': {'type': 'text', 'required': true},
            },
          },
        }
        ..['renderBindings'] = [_binding()];
      final transition = (workflow['transitions'] as List).single as Map;
      transition['inputs'] = {
        'comment': {
          'type': 'text',
          'required': false,
          'visibleWhen': 'true',
          'options': ['one'],
          'modeGroup': 'mode',
          'modeValue': 'one',
          'maxSelections': 1,
          'writesTo': 'participantFanId',
        },
      };
      transition['guard'] = {
        'allowedRoleIds': ['board'],
        'actorInList': {'key': 'participantFanId', 'present': false},
      };
      transition['effects'] = [
        {
          'op': 'branch',
          'if': 'true',
          'then': [
            {'op': 'set', 'key': 'participantFanId', 'value': r'$actor'},
          ],
          'else': <dynamic>[],
        },
      ];

      expect(_unknownKeys(workflow), isEmpty);
    });

    test('two unknown keys produce two findings with distinct full paths', () {
      final workflow = _workflow()
        ..['initialStates'] = 'open'
        ..['instanceDataSchema'] = {
          'title': {'type': 'text', 'searchible': true},
        };

      final unknown = _unknownKeys(workflow);
      expect(unknown, hasLength(2));
      expect(unknown.map((finding) => finding.location).toSet(), {
        'experience/workflowDefinitions/subject/initialStates',
        'experience/workflowDefinitions/subject/instanceDataSchema/title/searchible',
      });
      expect(unknown.every((finding) => !finding.isWarning), isTrue);
    });

    test('bindingKind value used as a key is called out explicitly', () {
      final workflow = _workflow()
        ..['renderBindings'] = [
          _binding(extra: {'summary': true}),
        ];

      final unknown = _unknownKeys(workflow);
      expect(unknown, hasLength(1));
      expect(unknown.single.message, contains('`bindingKind` value'));
      expect(unknown.single.message, contains('`summary`'));
    });

    test('nested parser objects each report their own unknown key', () {
      final workflow = _workflow()
        ..['instanceDataSchema'] = {
          'title': {'type': 'text', 'searchible': true},
        }
        ..['renderBindings'] = [
          _binding(
            extra: {
              'actions': [
                {'kind': 'create', 'kinds': 'create'},
              ],
              'responseTable': {
                'workflowType': 'response',
                'eventField': 'eventId',
                'pendingStates': ['pending'],
                'workflow': 'response',
              },
              'repeater': {
                'source': 'rows',
                'itemActions': [
                  {'transitionId': 'finish', 'transition': 'finish'},
                ],
                'items': 'rows',
              },
              'filterableFacets': [
                {'field': 'status', 'label': 'Status', 'labels': 'Status'},
              ],
            },
          ),
        ];
      final transition = (workflow['transitions'] as List).single as Map;
      transition['inputs'] = {
        'comment': {'type': 'text', 'require': true},
      };
      transition['guard'] = {'formula': 'true', 'formulas': 'true'};
      transition['effects'] = [
        {
          'op': 'set',
          'key': 'title',
          'value': 'Done',
          'operation': 'set',
          'recurrenceRule': {'freq': 'daily', 'count': 1, 'frequency': 'daily'},
        },
      ];

      final unknown = _unknownKeys(workflow);
      expect(unknown, hasLength(10));
      expect(
        unknown.map((finding) => finding.location),
        containsAll(<String>[
          'experience/workflowDefinitions/subject/transitions[0]/guard/formulas',
          'experience/workflowDefinitions/subject/transitions[0]/inputs/comment/require',
          'experience/workflowDefinitions/subject/transitions[0]/effects[0]/operation',
          'experience/workflowDefinitions/subject/transitions[0]/effects[0]/recurrenceRule/frequency',
          'experience/workflowDefinitions/subject/renderBindings[0]/actions[0]/kinds',
          'experience/workflowDefinitions/subject/renderBindings[0]/responseTable/workflow',
          'experience/workflowDefinitions/subject/renderBindings[0]/repeater/items',
          'experience/workflowDefinitions/subject/renderBindings[0]/repeater/itemActions[0]/transition',
          'experience/workflowDefinitions/subject/renderBindings[0]/filterableFacets[0]/labels',
          'experience/workflowDefinitions/subject/instanceDataSchema/title/searchible',
        ]),
      );
    });

    test('dynamic payload maps are not mistaken for grammar objects', () {
      final workflow = _workflow()
        ..['renderBindings'] = [
          _binding(
            extra: {
              'actions': [
                {
                  'kind': 'create',
                  'prefill': {'communityDefinedField': 'value'},
                  'inputs': {'communityDefinedInput': 'value'},
                },
              ],
              'repeater': {
                'source': 'rows',
                'itemActions': [
                  {
                    'transitionId': 'finish',
                    'inputs': {'communityDefinedInput': 'value'},
                  },
                ],
              },
            },
          ),
        ];
      final transition = (workflow['transitions'] as List).single as Map;
      transition['effects'] = [
        {
          'op': 'createInstance',
          'workflowType': 'target',
          'fields': {'communityDefinedField': 'value'},
          'relatedQuery': {
            'workflowType': 'target',
            'filter': {'communityDefinedField': 'value'},
          },
        },
      ];

      expect(_unknownKeys(workflow), isEmpty);
    });
  });
}
