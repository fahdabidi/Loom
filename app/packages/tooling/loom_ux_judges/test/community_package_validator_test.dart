import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:test/test.dart';

Map<String, dynamic> definition({Map<String, dynamic> schema = const {}}) =>
    <String, dynamic>{
      'initialState': 'open',
      'states': <String, dynamic>{
        'open': <String, dynamic>{'label': 'Open'},
        'done': <String, dynamic>{'label': 'Done', 'isTerminal': true},
      },
      'transitions': <dynamic>[
        <String, dynamic>{
          'id': 'finish',
          'label': 'Finish',
          'from': <String>['open'],
          'to': 'done',
        },
      ],
      'instanceDataSchema': schema,
    };
Map<String, dynamic> seed({
  String id = 'one',
  String type = 'thing',
  String state = 'open',
  Map<String, dynamic> data = const {},
}) => <String, dynamic>{
  'instanceId': id,
  'workflowType': type,
  'currentState': state,
  'instanceData': data,
};
Map<String, dynamic> pkg({Map<String, dynamic>? experience}) =>
    <String, dynamic>{
      'schemaVersion': 1,
      'experience':
          experience ??
          <String, dynamic>{
            'experienceSchemaVersion': 2,
            'workflowGrammarVersion': 1,
            'workflowDefinitions': <String, dynamic>{'thing': definition()},
            'workflowInstances': <dynamic>[seed()],
          },
    };
List<String> findings(Map<String, dynamic> p) => CommunityPackageValidator()
    .validate(p)
    .findings
    .map((f) => f.type)
    .toList();

void main() {
  group('CommunityPackageValidator Ticket B rules', () {
    test(
      '1 minimal valid v2 package passes',
      () => expect(CommunityPackageValidator().validate(pkg()).passed, isTrue),
    );
    test('2 missing root schemaVersion', () {
      final package = pkg()..remove('schemaVersion');
      final report = CommunityPackageValidator().validate(package);
      final missingVersions = report.findings
          .where((finding) => finding.type == 'missing_schema_version')
          .toList();

      expect(missingVersions, hasLength(1));
      expect(missingVersions.single.location, 'schemaVersion');
    });
    test(
      '3 unsupported experience schema version',
      () => expect(
        findings(
          pkg(experience: <String, dynamic>{'experienceSchemaVersion': 99}),
        ),
        contains('unsupported_schema_version'),
      ),
    );
    test(
      '4 missing experience schema version',
      () => expect(
        findings(pkg(experience: <String, dynamic>{})),
        contains('missing_schema_version'),
      ),
    );
    test('5 v1 short-circuits malformed deep content', () {
      final r = CommunityPackageValidator().validate(
        pkg(
          experience: <String, dynamic>{
            'experienceSchemaVersion': 1,
            'workflowDefinitions': <String, dynamic>{
              'bad': <String, dynamic>{},
            },
          },
        ),
      );
      expect(r.errors, isEmpty);
      expect(r.warnings.map((f) => f.type), <String>[
        'legacy_experience_schema',
      ]);
    });
    test('6 unknown instance workflow type', () {
      final p = pkg();
      (p['experience'] as Map<String, dynamic>)['workflowInstances'] =
          <dynamic>[seed(type: 'nope')];
      expect(findings(p), contains('unknown_instance_workflow_type'));
    });
    test('7 invalid current state', () {
      final p = pkg();
      (p['experience'] as Map<String, dynamic>)['workflowInstances'] =
          <dynamic>[seed(state: 'nope')];
      expect(findings(p), contains('invalid_instance_state'));
    });
    test('8 duplicate instance id', () {
      final p = pkg();
      (p['experience'] as Map<String, dynamic>)['workflowInstances'] =
          <dynamic>[seed(), seed()];
      expect(findings(p), contains('duplicate_instance_id'));
    });
    test('9 unknown instance data key', () {
      final p = pkg();
      (p['experience']
          as Map<String, dynamic>)['workflowInstances'] = <dynamic>[
        seed(data: <String, dynamic>{'nope': 1}),
      ];
      expect(findings(p), contains('unknown_instance_data_key'));
    });
    test('10 missing required non-computed field', () {
      final p = pkg();
      final e = p['experience'] as Map<String, dynamic>;
      e['workflowDefinitions'] = <String, dynamic>{
        'thing': definition(
          schema: <String, dynamic>{
            'name': <String, dynamic>{'type': 'string', 'required': true},
          },
        ),
      };
      expect(findings(p), contains('missing_required_field'));
    });
    test('11 computed field seeded', () {
      final p = pkg();
      final e = p['experience'] as Map<String, dynamic>;
      e['workflowDefinitions'] = <String, dynamic>{
        'thing': definition(
          schema: <String, dynamic>{
            'total': <String, dynamic>{'type': 'number', 'formula': '1'},
          },
        ),
      };
      e['workflowInstances'] = <dynamic>[
        seed(data: <String, dynamic>{'total': 1}),
      ];
      expect(findings(p), contains('computed_field_seeded'));
    });
    test('12 malformed definition is reported without throwing', () {
      final p = pkg();
      (p['experience'] as Map<String, dynamic>)['workflowDefinitions'] =
          <String, dynamic>{'bad': <String, dynamic>{}};
      expect(() => CommunityPackageValidator().validate(p), returnsNormally);
      expect(findings(p), contains('invalid_workflow_definition'));
    });
    test('13 ballot reference to missing event is dangling', () {
      final p = _ballotPackage('missing');
      expect(findings(p), contains('dangling_instance_reference'));
    });
    test('14 ballot reference to event resolves target fields', () {
      final r = CommunityPackageValidator().validate(_ballotPackage('event'));
      expect(
        r.findings.where(
          (f) =>
              f.type == 'dangling_instance_reference' ||
              f.type == 'dangling_related_list_field' ||
              f.type == 'dangling_instance_data_key' ||
              f.type == 'computed_field_written_by_effect',
        ),
        isEmpty,
      );
    });
    test('15 workflow validator finding is delegated', () {
      final p = pkg();
      (p['experience']
          as Map<String, dynamic>)['workflowDefinitions'] = <String, dynamic>{
        'thing': <String, dynamic>{
          'initialState': 'open',
          'states': <String, dynamic>{
            'open': <String, dynamic>{'label': 'Open'},
          },
          'transitions': <dynamic>[],
          'instanceDataSchema': <String, dynamic>{},
        },
      };
      expect(findings(p), contains('stuck_state'));
    });
  });
}

Map<String, dynamic> _ballotPackage(String eventId) {
  final p = pkg();
  final e = p['experience'] as Map<String, dynamic>;
  e['workflowDefinitions'] = <String, dynamic>{
    'event': definition(
      schema: <String, dynamic>{
        'goingPersonaIds': <String, dynamic>{'type': 'list'},
        'selectedGame': <String, dynamic>{'type': 'string'},
      },
    ),
    'ballot': <String, dynamic>{
      ...definition(
        schema: <String, dynamic>{
          'eventId': <String, dynamic>{'type': 'string'},
        },
      ),
      'transitions': <dynamic>[
        <String, dynamic>{
          'id': 'vote',
          'label': 'Vote',
          'from': <String>['open'],
          'to': 'done',
          'guard': <String, dynamic>{
            'relatedInstanceField': 'eventId',
            'relatedListField': 'goingPersonaIds',
          },
          'effects': <dynamic>[
            <String, dynamic>{
              'op': 'set',
              'key': 'selectedGame',
              'relatedInstance': 'eventId',
            },
          ],
        },
      ],
    },
  };
  e['workflowInstances'] = <dynamic>[
    seed(id: 'event', type: 'event'),
    seed(
      id: 'ballot',
      type: 'ballot',
      data: <String, dynamic>{'eventId': eventId},
    ),
  ];
  return p;
}
