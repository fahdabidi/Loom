import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;
import 'package:test/test.dart';

const _findingType = 'noop_affordance';
const _findingLocation =
    'experience/workflowDefinitions/subject/transitions/perform-action';

Map<String, dynamic> _package({
  required Object? to,
  List<Map<String, dynamic>>? effects,
}) => <String, dynamic>{
  'specVersion': currentCommunitySpecVersion,
  'experience': <String, dynamic>{
    'roles': <Map<String, dynamic>>[
      <String, dynamic>{'roleId': 'member', 'label': 'Member'},
    ],
    'workflowDefinitions': <String, dynamic>{
      'subject': <String, dynamic>{
        'initialState': 'active',
        'states': <String, dynamic>{
          'active': <String, dynamic>{'label': 'Active'},
          'done': <String, dynamic>{'label': 'Done', 'isTerminal': true},
        },
        'transitions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'perform-action',
            'label': 'Perform action',
            'from': <String>['active'],
            'to': to,
            if (effects != null) 'effects': effects,
          },
        ],
        'instanceDataSchema': <String, dynamic>{
          'memberIds': <String, dynamic>{'type': 'fanId[]'},
        },
        'renderBindings': <Map<String, dynamic>>[
          <String, dynamic>{
            'states': <String>['active', 'done'],
            'audience': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'statusTimeline',
            'bindingKind': 'primary',
          },
        ],
      },
    },
    'workflowInstances': <dynamic>[],
  },
};

List<ValidationFinding> _findings(Map<String, dynamic> package) =>
    CommunityPackageValidator()
        .validate(package)
        .findings
        .where((finding) => finding.type == _findingType)
        .toList();

void main() {
  group('noop_affordance', () {
    test('warns exactly once at a to:null transition with no effects', () {
      final findings = _findings(_package(to: null));

      expect(findings, hasLength(1));
      expect(findings.single.isWarning, isTrue);
      expect(findings.single.location, _findingLocation);
    });

    test('also warns when the effects list is explicitly empty', () {
      expect(_findings(_package(to: null, effects: const [])), hasLength(1));
    });

    test('does not warn when a to:null transition has an effect', () {
      final findings = _findings(
        _package(
          to: null,
          effects: const [
            <String, dynamic>{
              'op': 'appendUnique',
              'key': 'memberIds',
              'value': r'$actor',
            },
          ],
        ),
      );

      expect(findings, isEmpty);
    });

    test('does not warn when an effectless transition changes state', () {
      expect(_findings(_package(to: 'done')), isEmpty);
    });
  });
}
