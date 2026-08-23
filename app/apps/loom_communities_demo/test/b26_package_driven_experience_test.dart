import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  group('B26 package-driven experience', () {
    test('wf_package-driven-experience-overrides-fallback', () {
      final fixture = _writeTabletopClubPackagePair();
      final backend = LocalInAppBackend();

      final report = backend.installLocalPackagePairFromFiles(
        extensionPackagePath: fixture.extensionPath,
        initializationPackagePath: fixture.initializationPath,
      );
      final community = report.community;

      expect(community.extensionId, _extensionId);
      expect(
        community.experienceConfiguration,
        isNotEmpty,
        reason:
            'the initialization package experience block must be parsed onto the installed community',
      );

      final experience = experienceForExtensionId(
        community.extensionId,
        displayName: community.displayName,
        specVersion: community.specVersion,
        experienceConfiguration: community.experienceConfiguration,
      );

      // The v4 parser deliberately leaves the removed shallow workflow list
      // empty. Package-driven parsing is proved by real definitions + seeds.
      expect(experience.workflows, isEmpty);
      expect(experience.displayName, 'Tabletop Club');
      expect(experience.tagline, contains('game nights'));

      final definitions = experience.workflowDefinitions;
      final instances = experience.workflowInstances;
      expect(definitions, isNotNull);
      expect(instances, isNotNull);
      expect(definitions, hasLength(4));
      expect(instances, hasLength(4));
      final workflowIds = definitions!.keys.toSet();
      expect(
        workflowIds,
        containsAll(<String>[
          'tabletop-game-night-rsvp',
          'tabletop-game-loan',
          'tabletop-club-dues-payment',
          'tabletop-meetup-announcement',
        ]),
      );
      expect(
        instances!.map((instance) => instance.workflowType).toSet(),
        workflowIds,
      );
    });

    test('wf_package-driven-actorIdentities-and-role-guards', () {
      final fixture = _writeTabletopClubPackagePair();
      final backend = LocalInAppBackend();
      final community = backend
          .installLocalPackagePairFromFiles(
            extensionPackagePath: fixture.extensionPath,
            initializationPackagePath: fixture.initializationPath,
          )
          .community;

      final experience = experienceForExtensionId(
        community.extensionId,
        displayName: community.displayName,
        specVersion: community.specVersion,
        experienceConfiguration: community.experienceConfiguration,
      );

      final actorIdentities = actorIdentitiesForExtensionId(
        community.extensionId,
        experience: experience,
      );
      expect(
        actorIdentities.map((actorIdentity) => actorIdentity.roleId),
        containsAll(<String>['tabletop-organizer', 'tabletop-member']),
      );

      final rsvp = experience.workflowDefinitions!['tabletop-game-night-rsvp']!;
      final reserve = rsvp.transitions.singleWhere(
        (transition) => transition.id == 'reserve-seat',
      );
      final acknowledge = rsvp.transitions.singleWhere(
        (transition) => transition.id == 'acknowledge-rsvp',
      );
      expect(reserve.from, ['open']);
      expect(reserve.to, 'reserved');
      expect(reserve.guard.allowedRoleIds, ['tabletop-member']);
      expect(acknowledge.from, ['reserved']);
      expect(acknowledge.to, 'acknowledged');
      expect(acknowledge.guard.allowedRoleIds, ['tabletop-organizer']);
      expect(rsvp.renderBindings.single.tabId, 'calendar');
      expect(rsvp.renderBindings.single.cardSurfaceFamily, 'event-rsvp');
    });

    test('wf_package-driven-tabs-use-declared-shell-role-visibility', () {
      final fixture = _writeTabletopClubPackagePair();
      final backend = LocalInAppBackend();
      final community = backend
          .installLocalPackagePairFromFiles(
            extensionPackagePath: fixture.extensionPath,
            initializationPackagePath: fixture.initializationPath,
          )
          .community;

      final experience = experienceForExtensionId(
        community.extensionId,
        displayName: community.displayName,
        specVersion: community.specVersion,
        experienceConfiguration: community.experienceConfiguration,
      );

      // Member actorIdentity: the package's Admin declaration excludes this role.
      final memberTabs = appShellTabsFor(
        experience: experience,
        roleId: 'tabletop-member',
        appShellConfiguration: community.appShellConfiguration,
      );
      final memberTabIds = memberTabs.map((tab) => tab.tabId).toSet();
      expect(
        memberTabIds,
        containsAll(<String>[
          'home',
          'calendar',
          'marketplace',
          'giving',
          'messages',
        ]),
      );
      expect(memberTabIds, isNot(contains('admin')));

      // Organizer actorIdentity is explicitly admitted to the package's Admin tab.
      final organizerTabs = appShellTabsFor(
        experience: experience,
        roleId: 'tabletop-organizer',
        appShellConfiguration: community.appShellConfiguration,
      );
      expect(organizerTabs.map((tab) => tab.tabId), contains('admin'));
    });
  });
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}

_PackagePairFixture _writeTabletopClubPackagePair() {
  final definitions = <String, Object?>{
    'tabletop-game-night-rsvp': engineNativeTestWorkflowDefinition(
      initialState: 'open',
      states: <String, Object?>{
        'open': <String, Object?>{'label': 'RSVP open'},
        'reserved': <String, Object?>{'label': 'Seat reserved'},
        'acknowledged': <String, Object?>{
          'label': 'RSVP acknowledged',
          'isTerminal': true,
        },
      },
      transitions: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'reserve-seat',
          'label': 'Reserve seat',
          'from': <String>['open'],
          'to': 'reserved',
          'guard': <String, Object?>{
            'allowedRoleIds': <String>['tabletop-member'],
          },
        },
        <String, Object?>{
          'id': 'acknowledge-rsvp',
          'label': 'Acknowledge RSVP',
          'from': <String>['reserved'],
          'to': 'acknowledged',
          'guard': <String, Object?>{
            'allowedRoleIds': <String>['tabletop-organizer'],
          },
        },
      ],
      renderBindings: <Map<String, Object?>>[
        engineNativeTestRenderBinding(
          states: <String>['open', 'reserved', 'acknowledged'],
          tabId: 'calendar',
          cardSurfaceFamily: 'event-rsvp',
        ),
      ],
      instanceDataSchema: <String, Object?>{
        'title': <String, Object?>{'type': 'text', 'storage': 'inline'},
        'eventDate': <String, Object?>{'type': 'date', 'storage': 'inline'},
        'eventTime': <String, Object?>{'type': 'time', 'storage': 'inline'},
        'location': <String, Object?>{'type': 'text', 'storage': 'inline'},
      },
    ),
    'tabletop-game-loan': engineNativeTestWorkflowDefinition(
      initialState: 'available',
      states: <String, Object?>{
        'available': <String, Object?>{'label': 'Available'},
        'requested': <String, Object?>{
          'label': 'Loan requested',
          'isTerminal': true,
        },
      },
      transitions: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'request-loan',
          'label': 'Request loan',
          'from': <String>['available'],
          'to': 'requested',
          'guard': <String, Object?>{
            'allowedRoleIds': <String>['tabletop-member'],
          },
        },
      ],
      renderBindings: <Map<String, Object?>>[
        engineNativeTestRenderBinding(
          states: <String>['available', 'requested'],
          tabId: 'marketplace',
          cardSurfaceFamily: 'equipment-loan',
        ),
      ],
      instanceDataSchema: <String, Object?>{
        'title': <String, Object?>{'type': 'text', 'storage': 'inline'},
        'category': <String, Object?>{'type': 'text', 'storage': 'inline'},
        'condition': <String, Object?>{'type': 'text', 'storage': 'inline'},
        'availabilityState': <String, Object?>{
          'type': 'text',
          'storage': 'inline',
        },
      },
    ),
    'tabletop-club-dues-payment': engineNativeTestWorkflowDefinition(
      initialState: 'due',
      states: <String, Object?>{
        'due': <String, Object?>{'label': 'Payment due'},
        'paid': <String, Object?>{'label': 'Paid', 'isTerminal': true},
      },
      transitions: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'pay-dues',
          'label': 'Pay \$15',
          'from': <String>['due'],
          'to': 'paid',
          'guard': <String, Object?>{
            'allowedRoleIds': <String>['tabletop-member'],
          },
        },
      ],
      renderBindings: <Map<String, Object?>>[
        engineNativeTestRenderBinding(
          states: <String>['due', 'paid'],
          tabId: 'giving',
          cardSurfaceFamily: 'paymentCheckout',
        ),
      ],
      instanceDataSchema: <String, Object?>{
        'title': <String, Object?>{'type': 'text', 'storage': 'inline'},
        'amount': <String, Object?>{'type': 'number', 'storage': 'inline'},
      },
    ),
    'tabletop-meetup-announcement': engineNativeTestWorkflowDefinition(
      initialState: 'draft',
      states: <String, Object?>{
        'draft': <String, Object?>{'label': 'Draft'},
        'published': <String, Object?>{
          'label': 'Published',
          'isTerminal': true,
        },
      },
      transitions: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'publish-announcement',
          'label': 'Publish announcement',
          'from': <String>['draft'],
          'to': 'published',
          'guard': <String, Object?>{
            'allowedRoleIds': <String>['tabletop-organizer'],
          },
        },
      ],
      renderBindings: <Map<String, Object?>>[
        engineNativeTestRenderBinding(
          states: <String>['draft', 'published'],
          tabId: 'admin',
          cardSurfaceFamily: 'notificationInbox',
        ),
      ],
      instanceDataSchema: <String, Object?>{
        'title': <String, Object?>{'type': 'text', 'storage': 'inline'},
        'body': <String, Object?>{'type': 'textarea', 'storage': 'inline'},
      },
    ),
  };
  final instances = <Map<String, Object?>>[
    engineNativeTestWorkflowInstance(
      instanceId: 'tabletop-game-night-rsvp',
      workflowType: 'tabletop-game-night-rsvp',
      currentState: 'open',
      createdByFanId: 'tabletop-organizer',
      instanceData: <String, Object?>{
        'title': 'RSVP to Friday game night',
        'eventDate': '2026-07-10',
        'eventTime': '19:00',
        'location': 'Community room',
      },
    ),
    engineNativeTestWorkflowInstance(
      instanceId: 'tabletop-game-loan',
      workflowType: 'tabletop-game-loan',
      currentState: 'available',
      createdByFanId: 'tabletop-organizer',
      instanceData: <String, Object?>{
        'title': 'Catan',
        'category': 'Board Games',
        'condition': 'Like new',
        'availabilityState': 'available',
      },
    ),
    engineNativeTestWorkflowInstance(
      instanceId: 'tabletop-club-dues-payment',
      workflowType: 'tabletop-club-dues-payment',
      currentState: 'due',
      createdByFanId: 'tabletop-organizer',
      instanceData: <String, Object?>{
        'title': 'Quarterly club dues',
        'amount': 15,
      },
    ),
    engineNativeTestWorkflowInstance(
      instanceId: 'tabletop-meetup-announcement',
      workflowType: 'tabletop-meetup-announcement',
      currentState: 'draft',
      createdByFanId: 'tabletop-organizer',
      instanceData: <String, Object?>{
        'title': 'Friday game night room change',
        'body': 'Friday game night moves to the larger room next week.',
      },
    ),
  ];
  final fixture = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_b26_tabletop_',
    extensionId: _extensionId,
    communityId: 'community_verify_tabletop_club',
    displayName: 'Tabletop Club',
    experience: <String, Object?>{
      'displayName': 'Tabletop Club',
      'tagline':
          'Board game nights, loaner games, and dues for local tabletop fans.',
      'accentColor': '#C4703F',
      'theme': {
        'accent': '#C4703F',
        'tabThemes': {
          'giving': {'accent': '#8A5A34'},
        },
      },
      'roles': [
        {
          'roleId': 'tabletop-organizer',
          'label': 'Organizer',
          'roleLabel': 'Organizer',
          'description':
              'Plans game nights, manages the game library, and collects dues.',
        },
        {
          'roleId': 'tabletop-member',
          'label': 'Member',
          'roleLabel': 'Member',
          'description': 'RSVPs to game nights, borrows games, and pays dues.',
        },
      ],
      'workflowDefinitions': definitions,
      'workflowInstances': instances,
    },
    appShell: <String, Object?>{
      'tabs': <Object?>[
        <String, Object?>{
          'tabId': 'calendar',
          'label': 'Calendar',
          'iconKey': 'calendar',
        },
        <String, Object?>{
          'tabId': 'marketplace',
          'label': 'Marketplace',
          'iconKey': 'marketplace',
        },
        <String, Object?>{
          'tabId': 'giving',
          'label': 'Giving',
          'iconKey': 'payment',
        },
        <String, Object?>{
          'tabId': 'admin',
          'label': 'Admin',
          'iconKey': 'admin',
          'visibleRoleIds': <String>['tabletop-organizer'],
        },
      ],
    },
  );
  return _PackagePairFixture(
    extensionPath: fixture.extensionPath,
    initializationPath: fixture.initializationPath,
  );
}
