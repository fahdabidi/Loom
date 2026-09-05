import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:loom_ux_judges/src/validator/generated_capability_baseline.dart';
import 'package:loom_ux_judges/src/validator/generated_skill_version.dart';
import 'package:loom_ux_judges/src/validator/workflow_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;
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

Map<String, dynamic> definitionWithBinding({
  String tabId = 'calendar',
  String cardSurfaceFamily = 'event-rsvp',
  Map<String, dynamic> schema = const {},
}) => <String, dynamic>{
  ...definition(schema: schema),
  'renderBindings': <dynamic>[
    {
      'states': ['open', 'done'],
      'audience': 'any',
      'tabId': tabId,
      'cardSurfaceFamily': cardSurfaceFamily,
      'bindingKind': 'summary',
    },
  ],
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
  'createdByFanId': 'fan-one',
};
Map<String, dynamic> pkg({Map<String, dynamic>? experience}) =>
    <String, dynamic>{
      'specVersion': currentCommunitySpecVersion,
      'skillVersion': currentSkillVersion,
      'experience':
          experience ??
          <String, dynamic>{
            'roles': <Map<String, dynamic>>[
              <String, dynamic>{'roleId': 'member', 'label': 'Member'},
            ],
            'workflowDefinitions': <String, dynamic>{'thing': definition()},
            'workflowInstances': <dynamic>[seed()],
          },
    };

Map<String, dynamic> capabilityPkg() => pkg(
  experience: <String, dynamic>{
    'roles': <Map<String, dynamic>>[
      <String, dynamic>{'roleId': 'member', 'label': 'Member'},
    ],
    'workflowDefinitions': <String, dynamic>{
      'thing': <String, dynamic>{
        ...definitionWithBinding(
          tabId: 'home',
          cardSurfaceFamily: 'statusTimeline',
        ),
        'visibility': <String, dynamic>{'default': 'public'},
      },
    },
    'workflowInstances': <dynamic>[seed()],
  },
);
List<String> findings(Map<String, dynamic> p) => CommunityPackageValidator()
    .validate(p)
    .findings
    .map((f) => f.type)
    .toList();

Map<String, dynamic> specV4Pkg() => pkg();

Map<String, dynamic> mapGetCapabilityPkg() {
  final package = capabilityPkg();
  final experience = package['experience'] as Map<String, dynamic>;
  final thing =
      (experience['workflowDefinitions'] as Map<String, dynamic>)['thing']
          as Map<String, dynamic>;
  thing['instanceDataSchema'] = <String, dynamic>{
    'counts': <String, dynamic>{'type': 'map'},
    'selectedCount': <String, dynamic>{
      'type': 'number',
      'formula': "mapGet(counts, 'selected')",
    },
  };
  experience['workflowInstances'] = <dynamic>[
    seed(
      data: <String, dynamic>{
        'counts': <String, int>{'selected': 1},
      },
    ),
  ];
  return package;
}

Set<String> baselineBefore(String capability) =>
    <String>{...communityCapabilityBaseline}..remove(capability);

List<ValidationFinding> missingCreatorFindings(Map<String, dynamic> package) =>
    CommunityPackageValidator()
        .validate(package)
        .findings
        .where((finding) => finding.type == 'seed_instance_missing_creator')
        .toList();

void main() {
  group('skill version validation', () {
    test('a package stamped at the current version has no stale finding', () {
      final report = CommunityPackageValidator().validate(pkg());

      expect(
        report.findings.where(
          (finding) => finding.type == 'stale_skill_version',
        ),
        isEmpty,
      );
    });

    test(
      'an absent skillVersion warns without blocking an otherwise valid package',
      () {
        final package = pkg()..remove('skillVersion');
        final report = CommunityPackageValidator().validate(package);
        final staleFindings = report.findings
            .where((finding) => finding.type == 'stale_skill_version')
            .toList();

        expect(staleFindings, hasLength(1));
        expect(staleFindings.single.isWarning, isTrue);
        expect(staleFindings.single.location, 'skillVersion');
        expect(
          staleFindings.single.message,
          contains('docs/references/reference/skill-versioning.md'),
        );
        expect(report.passed, isTrue);
      },
    );
  });

  group('requiresCapabilities', () {
    test('unimplemented capability produces one unsupported error', () {
      final package = capabilityPkg()
        ..['requiresCapabilities'] = <String>['effect.teleport'];

      final report = CommunityPackageValidator().validate(package);

      expect(report.findings, hasLength(1));
      expect(report.findings.single.type, 'unsupported_capability');
      expect(report.findings.single.isWarning, isFalse);
      expect(report.findings.single.message, contains('effect.teleport'));
    });

    test('unknown namespace produces one unsupported error', () {
      final package = capabilityPkg()
        ..['requiresCapabilities'] = <String>['widget.teleport'];

      final report = CommunityPackageValidator().validate(package);

      expect(report.findings, hasLength(1));
      expect(report.findings.single.type, 'unsupported_capability');
      expect(report.findings.single.isWarning, isFalse);
      expect(report.findings.single.message, contains('widget.teleport'));
    });

    test('declared but unused capability produces one unused error', () {
      final package = capabilityPkg()
        ..['requiresCapabilities'] = <String>['effect.transitionRelated'];
      final validator = CommunityPackageValidator(
        capabilityBaseline: baselineBefore('effect.transitionRelated'),
      );

      final report = validator.validate(package);

      expect(report.findings, hasLength(1));
      expect(report.findings.single.type, 'unused_capability');
      expect(report.findings.single.isWarning, isFalse);
      expect(
        report.findings.single.message,
        contains('effect.transitionRelated'),
      );
    });

    test('declared and used post-baseline capability produces no findings', () {
      final package = mapGetCapabilityPkg()
        ..['requiresCapabilities'] = <String>['formula.mapGet'];
      final validator = CommunityPackageValidator(
        capabilityBaseline: baselineBefore('formula.mapGet'),
      );

      expect(validator.validate(package).findings, isEmpty);
    });

    test('used but undeclared post-baseline capability produces an error', () {
      final report = CommunityPackageValidator(
        capabilityBaseline: baselineBefore('formula.mapGet'),
      ).validate(mapGetCapabilityPkg());

      expect(report.findings, hasLength(1));
      expect(report.findings.single.type, 'undeclared_capability');
      expect(report.findings.single.isWarning, isFalse);
      expect(report.findings.single.message, contains('formula.mapGet'));
      expect(report.findings.single.location, 'requiresCapabilities');
    });

    test('used baseline capability needs no declaration', () {
      final package = mapGetCapabilityPkg();

      expect(package, isNot(contains('requiresCapabilities')));
      expect(CommunityPackageValidator().validate(package).findings, isEmpty);
    });

    test('declared baseline capability is rejected as unused', () {
      final package = mapGetCapabilityPkg()
        ..['requiresCapabilities'] = <String>['formula.mapGet'];
      final report = CommunityPackageValidator().validate(package);

      expect(report.findings, hasLength(1));
      expect(report.findings.single.type, 'unused_capability');
      expect(
        report.findings.single.message,
        contains('implied by specVersion'),
      );
    });

    test('absent requiresCapabilities produces no findings', () {
      final package = capabilityPkg();

      expect(package, isNot(contains('requiresCapabilities')));
      expect(CommunityPackageValidator().validate(package).findings, isEmpty);
    });
  });

  group('CommunityPackageValidator Ticket B rules', () {
    test(
      '1 minimal valid v4 package passes',
      () => expect(CommunityPackageValidator().validate(pkg()).passed, isTrue),
    );
    test('2 missing root version stamp', () {
      final package = pkg()..remove('specVersion');
      final report = CommunityPackageValidator().validate(package);
      final missingVersions = report.findings
          .where((finding) => finding.type == 'missing_schema_version')
          .toList();

      expect(missingVersions, hasLength(1));
      expect(missingVersions.single.location, 'specVersion');
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

    test('16 custom tab in appShell.tabs is accepted', () {
      final p = pkg();
      final e = p['experience'] as Map<String, dynamic>;
      e['workflowDefinitions'] = <String, dynamic>{
        'thing': definitionWithBinding(tabId: 'calendar'),
      };
      // appShell is a top-level package field, a sibling of `experience` --
      // matches loom_demo_local_backend's real
      // initialization['appShell']/extension['appShell'] resolution, not
      // nested inside experience.
      p['appShell'] = <String, dynamic>{
        'tabs': [
          {
            'tabId': 'calendar',
            'label': 'Calendar',
            'rendererContractId': 'community-calendar',
          },
        ],
      };

      expect(findings(p), isNot(contains('unknown_tab_id')));
    });

    test('17 fallback to appShellCustomization roleTabs is accepted', () {
      final p = pkg();
      final e = p['experience'] as Map<String, dynamic>;
      e['workflowDefinitions'] = <String, dynamic>{
        'thing': definitionWithBinding(tabId: 'owner-portal'),
      };
      p['appShellCustomization'] = <String, dynamic>{
        'roleTabs': {
          'owner': [
            {
              'tabId': 'owner-portal',
              'label': 'Owner Portal',
              'rendererContractId': 'owner-portal',
            },
          ],
        },
      };

      expect(findings(p), isNot(contains('unknown_tab_id')));
    });

    test('18 unknown custom tabId is rejected when undeclared', () {
      final p = pkg();
      final e = p['experience'] as Map<String, dynamic>;
      e['workflowDefinitions'] = <String, dynamic>{
        'thing': definitionWithBinding(tabId: 'owner-portal'),
      };
      p['appShell'] = <String, dynamic>{
        'tabs': [
          {'tabId': 'calendar', 'label': 'Calendar', 'rendererContractId': 'x'},
        ],
      };

      expect(findings(p), contains('unknown_tab_id'));
    });

    test(
      '19 tab requiredPermission produces one finding and omission produces none',
      () {
        final p = pkg();
        final e = p['experience'] as Map<String, dynamic>;
        e['workflowDefinitions'] = <String, dynamic>{
          'thing': <String, dynamic>{
            ...definitionWithBinding(
              tabId: 'admin',
              cardSurfaceFamily: 'statusTimeline',
            ),
            'visibility': <String, dynamic>{'default': 'public'},
          },
        };
        final tab = <String, dynamic>{
          'tabId': 'admin',
          'label': 'Admin',
          'rendererContractId': 'engine-native-generic-list',
          'requiredPermission': 'community.surface.navigation.configure',
        };
        p['appShell'] = <String, dynamic>{
          'tabs': <dynamic>[tab],
        };

        final report = CommunityPackageValidator().validate(p);
        expect(report.findings, hasLength(1));
        final finding = report.findings.single;
        expect(finding.type, 'tab_declares_permission');
        expect(finding.location, 'appShell/tabs[0]/requiredPermission');
        expect(finding.message, contains('surfaces, not capabilities'));
        expect(finding.message, contains('role guards'));
        expect(finding.message, contains('render-bindings.md'));

        tab.remove('requiredPermission');
        expect(CommunityPackageValidator().validate(p).findings, isEmpty);
      },
    );

    test('20 historical permission alias is rejected in roleTabs', () {
      final p = pkg();
      final e = p['experience'] as Map<String, dynamic>;
      e['workflowDefinitions'] = <String, dynamic>{
        'thing': <String, dynamic>{
          ...definitionWithBinding(
            tabId: 'member-tools',
            cardSurfaceFamily: 'statusTimeline',
          ),
          'visibility': <String, dynamic>{'default': 'public'},
        },
      };
      p['appShell'] = <String, dynamic>{
        'roleTabs': <String, dynamic>{
          'member': <dynamic>[
            <String, dynamic>{
              'tabId': 'member-tools',
              'label': 'Member tools',
              'rendererContractId': 'engine-native-generic-list',
              'permission': 'community.surface.navigation.read',
            },
          ],
        },
      };

      final report = CommunityPackageValidator().validate(p);
      expect(report.findings, hasLength(1));
      expect(report.findings.single.type, 'tab_declares_permission');
      expect(
        report.findings.single.location,
        'appShell/roleTabs/member[0]/permission',
      );
    });
  });

  group('community notification configuration', () {
    Map<String, dynamic> withNotifications(Map<String, dynamic> notifications) {
      final package = capabilityPkg();
      (package['experience'] as Map<String, dynamic>)['notifications'] =
          notifications;
      return package;
    }

    void expectSingleNotificationFinding(
      Map<String, dynamic> package,
      String type,
    ) {
      final report = CommunityPackageValidator().validate(package);
      expect(report.findings, hasLength(1));
      expect(report.findings.single.type, type);
      expect(report.findings.single.isWarning, isFalse);
    }

    test('reports unknown channels in either channel list', () {
      expectSingleNotificationFinding(
        withNotifications(<String, dynamic>{
          'allowedChannels': <String>['inbox', 'email'],
          'default': <String>['inbox'],
        }),
        'unknown_notification_channel',
      );
      expectSingleNotificationFinding(
        withNotifications(<String, dynamic>{
          'allowedChannels': <String>['inbox', 'push'],
          'default': <String>['inbox', 'email'],
        }),
        'unknown_notification_channel',
      );
    });

    test('reports either explicitly empty channel list', () {
      expectSingleNotificationFinding(
        withNotifications(<String, dynamic>{
          'allowedChannels': <String>['inbox'],
          'default': <String>[],
        }),
        'empty_notification_channels',
      );
      expectSingleNotificationFinding(
        withNotifications(<String, dynamic>{
          'allowedChannels': <String>[],
          'default': <String>['inbox'],
        }),
        'empty_notification_channels',
      );
    });

    test('reports a coherent default that is not offered', () {
      expectSingleNotificationFinding(
        withNotifications(<String, dynamic>{
          'allowedChannels': <String>['inbox'],
          'default': <String>['push'],
        }),
        'notification_default_not_offered',
      );
    });

    test('reports muted configurations without an inbox default', () {
      expectSingleNotificationFinding(
        withNotifications(<String, dynamic>{
          'allowedChannels': <String>['push'],
          'default': <String>['push'],
          'muted': true,
        }),
        'notification_muted_without_inbox',
      );
    });

    test('reports keys the notification grammar does not define', () {
      expectSingleNotificationFinding(
        withNotifications(<String, dynamic>{'digest': true}),
        'unknown_notification_key',
      );
    });

    test('omitting notifications is clean and defaults to inbox', () {
      expect(
        CommunityPackageValidator().validate(capabilityPkg()).findings,
        isEmpty,
      );
    });

    test('accepts explicit allowed, default, and unmuted settings', () {
      expect(
        CommunityPackageValidator()
            .validate(
              withNotifications(<String, dynamic>{
                'allowedChannels': <String>['inbox', 'push'],
                'default': <String>['inbox'],
                'muted': false,
              }),
            )
            .findings,
        isEmpty,
      );
    });

    test('accepts muted true when inbox remains the default', () {
      expect(
        CommunityPackageValidator()
            .validate(
              withNotifications(<String, dynamic>{
                'allowedChannels': <String>['inbox'],
                'default': <String>['inbox'],
                'muted': true,
              }),
            )
            .findings,
        isEmpty,
      );
    });

    test('allows duplicate channels because the lists are set-like', () {
      expect(
        CommunityPackageValidator()
            .validate(
              withNotifications(<String, dynamic>{
                'allowedChannels': <String>['inbox', 'inbox', 'push'],
                'default': <String>['inbox', 'inbox'],
              }),
            )
            .findings,
        isEmpty,
      );
    });
  });

  group('seed instance creator validation', () {
    test('seed with createdByFanId has no missing-creator finding', () {
      expect(missingCreatorFindings(specV4Pkg()), isEmpty);
    });

    test('seed with a retired creator key reports the v4 creator error', () {
      final package = specV4Pkg();
      final instance =
          ((package['experience'] as Map<String, dynamic>)['workflowInstances']
                  as List<dynamic>)[0]
              as Map<String, dynamic>;
      instance
        ..remove('createdByFanId')
        ..['createdByPer'
                'sonaId'] =
            'fan-one';

      expect(missingCreatorFindings(package), hasLength(1));
    });

    test('seed with neither creator field reports install-blocking error', () {
      final package = specV4Pkg();
      final instance =
          ((package['experience'] as Map<String, dynamic>)['workflowInstances']
                  as List<dynamic>)[0]
              as Map<String, dynamic>;
      instance.remove('createdByFanId');

      final finding = missingCreatorFindings(package).single;
      expect(finding.isWarning, isFalse);
      expect(
        finding.location,
        'experience/workflowInstances[0]/createdByFanId',
      );
      expect(
        finding.message,
        allOf(
          contains('Seed instance "one"'),
          contains('community fails to install'),
          contains('person (fanId), not a role'),
        ),
      );
    });

    test('seed with empty or whitespace-only creator reports an error', () {
      for (final creator in ['', ' \t ']) {
        final package = specV4Pkg();
        final instance =
            ((package['experience']
                        as Map<String, dynamic>)['workflowInstances']
                    as List<dynamic>)[0]
                as Map<String, dynamic>;
        instance['createdByFanId'] = creator;

        expect(
          missingCreatorFindings(package),
          hasLength(1),
          reason: 'creator "$creator" must be rejected',
        );
      }
    });

    test('seed with non-string creator reports an error', () {
      final package = specV4Pkg();
      final instance =
          ((package['experience'] as Map<String, dynamic>)['workflowInstances']
                  as List<dynamic>)[0]
              as Map<String, dynamic>;
      instance['createdByFanId'] = 42;

      expect(missingCreatorFindings(package), hasLength(1));
    });

    test('several creatorless seeds report one error per seed', () {
      final package = specV4Pkg();
      final experience = package['experience'] as Map<String, dynamic>;
      experience['workflowInstances'] = <dynamic>[
        seed(id: 'missing')..remove('createdByFanId'),
        seed(id: 'valid'),
        seed(id: 'blank')..['createdByFanId'] = '   ',
        seed(id: 'non-string')..['createdByFanId'] = false,
      ];

      final creatorFindings = missingCreatorFindings(package);
      expect(creatorFindings, hasLength(3));
      expect(creatorFindings.map((finding) => finding.location), <String>[
        'experience/workflowInstances[0]/createdByFanId',
        'experience/workflowInstances[2]/createdByFanId',
        'experience/workflowInstances[3]/createdByFanId',
      ]);
      expect(
        creatorFindings.map((finding) => finding.message),
        everyElement(contains('community fails to install')),
      );
      expect(creatorFindings[0].message, contains('"missing"'));
      expect(creatorFindings[1].message, contains('"blank"'));
      expect(creatorFindings[2].message, contains('"non-string"'));
    });

    test(
      'package with no workflowInstances has no missing-creator finding',
      () {
        final package = specV4Pkg();
        (package['experience'] as Map<String, dynamic>).remove(
          'workflowInstances',
        );

        expect(missingCreatorFindings(package), isEmpty);
      },
    );
  });

  group('computed and query-backed field required validation', () {
    List<ValidationFinding> computedFieldRequiredFindings(
      Map<String, dynamic> package,
    ) => CommunityPackageValidator()
        .validate(package)
        .errors
        .where((finding) => finding.type == 'computed_field_cannot_be_required')
        .toList();

    test('formula plus required true produces exactly one error', () {
      final package = pkg();
      final experience = package['experience'] as Map<String, dynamic>;
      experience['workflowDefinitions'] = <String, dynamic>{
        'thing': definition(
          schema: <String, dynamic>{
            'queueLength': <String, dynamic>{
              'type': 'number',
              'required': true,
              'formula': 'size(queuedFanIds)',
            },
            'queuedFanIds': <String, dynamic>{'type': 'list'},
          },
        ),
      };

      final formulaRequired = computedFieldRequiredFindings(package);

      expect(formulaRequired, hasLength(1));
      expect(formulaRequired.single.isWarning, isFalse);
      expect(formulaRequired.single.message, contains("Field 'queueLength'"));
      expect(formulaRequired.single.message, contains("workflow 'thing'"));
      expect(
        formulaRequired.single.message,
        contains("Remove 'required: true' -- the formula supplies the value."),
      );
    });

    test('formula without required produces no error', () {
      final package = pkg();
      final experience = package['experience'] as Map<String, dynamic>;
      experience['workflowDefinitions'] = <String, dynamic>{
        'thing': definition(
          schema: <String, dynamic>{
            'total': <String, dynamic>{'type': 'number', 'formula': '1'},
          },
        ),
      };

      expect(computedFieldRequiredFindings(package), isEmpty);
    });

    test('required without formula produces no error', () {
      final package = pkg();
      final experience = package['experience'] as Map<String, dynamic>;
      experience['workflowDefinitions'] = <String, dynamic>{
        'thing': definition(
          schema: <String, dynamic>{
            'name': <String, dynamic>{'type': 'string', 'required': true},
          },
        ),
      };

      expect(computedFieldRequiredFindings(package), isEmpty);
    });

    test('reports every offending field across different workflows', () {
      final package = pkg();
      final experience = package['experience'] as Map<String, dynamic>;
      experience['workflowDefinitions'] = <String, dynamic>{
        'queue': definition(
          schema: <String, dynamic>{
            'queueLength': <String, dynamic>{
              'type': 'number',
              'required': true,
              'formula': 'size(queuedFanIds)',
            },
            'queuedFanIds': <String, dynamic>{'type': 'list'},
          },
        ),
        'roster': definition(
          schema: <String, dynamic>{
            'memberCount': <String, dynamic>{
              'type': 'number',
              'required': true,
              'formula': 'size(memberFanIds)',
            },
            'memberFanIds': <String, dynamic>{'type': 'list'},
          },
        ),
      };

      final formulaRequired = computedFieldRequiredFindings(package);

      expect(formulaRequired, hasLength(2));
      expect(
        formulaRequired.map((finding) => finding.message),
        containsAll(<Matcher>[
          allOf(contains("workflow 'queue'"), contains("Field 'queueLength'")),
          allOf(contains("workflow 'roster'"), contains("Field 'memberCount'")),
        ]),
      );
    });

    test('source plus required true produces exactly one error', () {
      final package = pkg();
      final experience = package['experience'] as Map<String, dynamic>;
      experience['workflowDefinitions'] = <String, dynamic>{
        'thing': definition(
          schema: <String, dynamic>{
            'responses': <String, dynamic>{
              'type': 'list',
              'required': true,
              'source': 'query(response where thingId == id)',
            },
          },
        ),
        'response': definition(
          schema: <String, dynamic>{
            'thingId': <String, dynamic>{'type': 'string'},
          },
        ),
      };

      final sourceRequired = computedFieldRequiredFindings(package);

      expect(sourceRequired, hasLength(1));
      expect(sourceRequired.single.isWarning, isFalse);
      expect(sourceRequired.single.message, contains("Field 'responses'"));
      expect(sourceRequired.single.message, contains("workflow 'thing'"));
      expect(
        sourceRequired.single.message,
        contains(
          "query-backed field is populated on read from another workflow's rows",
        ),
      );
      expect(
        sourceRequired.single.message,
        contains("Remove 'required: true' -- the query supplies the value."),
      );
    });

    test('source without required produces no error', () {
      final package = pkg();
      final experience = package['experience'] as Map<String, dynamic>;
      experience['workflowDefinitions'] = <String, dynamic>{
        'thing': definition(
          schema: <String, dynamic>{
            'responses': <String, dynamic>{
              'type': 'list',
              'source': 'query(response where thingId == id)',
            },
          },
        ),
        'response': definition(
          schema: <String, dynamic>{
            'thingId': <String, dynamic>{'type': 'string'},
          },
        ),
      };

      expect(computedFieldRequiredFindings(package), isEmpty);
    });

    test('reports formula and source fields with field-specific messages', () {
      final package = pkg();
      final experience = package['experience'] as Map<String, dynamic>;
      experience['workflowDefinitions'] = <String, dynamic>{
        'thing': definition(
          schema: <String, dynamic>{
            'responseCount': <String, dynamic>{
              'type': 'number',
              'required': true,
              'formula': 'size(responses)',
            },
            'responses': <String, dynamic>{
              'type': 'list',
              'required': true,
              'source': 'query(response where thingId == id)',
            },
          },
        ),
        'response': definition(
          schema: <String, dynamic>{
            'thingId': <String, dynamic>{'type': 'string'},
          },
        ),
      };

      final requiredComputedFields = computedFieldRequiredFindings(package);

      expect(requiredComputedFields, hasLength(2));
      expect(
        requiredComputedFields.map((finding) => finding.message),
        containsAll(<Matcher>[
          allOf(
            contains("Field 'responseCount'"),
            contains('formula supplies the value'),
          ),
          allOf(
            contains("Field 'responses'"),
            contains('query supplies the value'),
          ),
        ]),
      );
    });
  });
}

Map<String, dynamic> _ballotPackage(String eventId) {
  final p = pkg();
  final e = p['experience'] as Map<String, dynamic>;
  e['workflowDefinitions'] = <String, dynamic>{
    'event': definition(
      schema: <String, dynamic>{
        'goingFanIds': <String, dynamic>{'type': 'list'},
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
            'relatedListField': 'goingFanIds',
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
