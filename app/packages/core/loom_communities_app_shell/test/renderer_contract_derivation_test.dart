import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

LoomExperienceDefinition _experienceWithBindings(
  String extensionId,
  List<Map<String, Object?>> bindings,
) {
  return experienceForExtensionId(
    extensionId,
    specVersion: currentCommunitySpecVersion,
    experienceConfiguration: <String, Object?>{
      'workflowDefinitions': <String, Object?>{
        'test-workflow': <String, Object?>{
          'workflowId': 'test-workflow',
          'initialState': 'open',
          'states': <String, Object?>{
            'open': <String, Object?>{'label': 'Open'},
          },
          'transitions': <Object?>[],
          'renderBindings': bindings,
        },
      },
    },
  );
}

Map<String, Object?> _binding(String tabId, String cardSurfaceFamily) =>
    <String, Object?>{
      'tabId': tabId,
      'states': <String>['open'],
      'audience': 'any',
      'cardSurfaceFamily': cardSurfaceFamily,
      'bindingKind': 'primary',
    };

LoomAppShellTabSpec _declaredTab({
  required LoomExperienceDefinition experience,
  required String tabId,
  String? rendererContractId,
}) {
  final tab = <String, Object?>{'tabId': tabId, 'label': 'Test tab'};
  if (rendererContractId != null) {
    tab['rendererContractId'] = rendererContractId;
  }
  return appShellTabsFor(
    experience: experience,
    personaId: 'local-member',
    appShellConfiguration: <String, Object?>{
      'tabs': <Object?>[tab],
    },
  ).singleWhere((candidate) => candidate.tabId == tabId);
}

void main() {
  test(
    'absent renderer derives the tab-specific contract before bound families',
    () {
      final experience = _experienceWithBindings(
        'renderer-derivation-marketplace',
        <Map<String, Object?>>[
          _binding('marketplace', 'equipment-loan'),
          _binding('marketplace', 'unregistered-family'),
          _binding('calendar', 'event-rsvp'),
        ],
      );

      final marketplace = _declaredTab(
        experience: experience,
        tabId: 'marketplace',
      );

      expect(
        marketplace.rendererContractId,
        'marketplace-browse-listing-detail',
      );
    },
  );

  test('an explicitly declared renderer always wins', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-explicit',
      <Map<String, Object?>>[_binding('marketplace', 'equipment-loan')],
    );

    final marketplace = _declaredTab(
      experience: experience,
      tabId: 'marketplace',
      rendererContractId: 'engine-native-generic-list',
    );

    expect(marketplace.rendererContractId, 'engine-native-generic-list');

    final home = _declaredTab(
      experience: experience,
      tabId: 'home',
      rendererContractId: 'engine-native-generic-list',
    );

    expect(home.rendererContractId, 'engine-native-generic-list');
  });

  test('an unbound absent renderer keeps the generic fallback', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-fallback',
      <Map<String, Object?>>[],
    );

    final customTab = _declaredTab(experience: experience, tabId: 'custom-tab');

    expect(customTab.rendererContractId, 'engine-native-generic-list');
  });

  test('a named tab does not need a binding to derive its contract', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-named-unbound',
      <Map<String, Object?>>[],
    );

    final marketplace = _declaredTab(
      experience: experience,
      tabId: 'marketplace',
    );

    expect(marketplace.rendererContractId, 'marketplace-browse-listing-detail');
  });

  test('a single-tab contract is more specific than a multi-tab contract', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-specificity',
      <Map<String, Object?>>[
        _binding('admin', 'statusTimeline'),
        _binding('documents', 'statusTimeline'),
      ],
    );

    expect(
      _declaredTab(experience: experience, tabId: 'admin').rendererContractId,
      'admin-review-compose-queue',
    );
    expect(
      _declaredTab(
        experience: experience,
        tabId: 'documents',
      ).rendererContractId,
      'documents-library-detail',
    );
  });

  test('every current tabId overlap has one most-specific contract', () {
    final contracts = allTabRendererContracts();
    final claimedTabIds = <String>{
      for (final contract in contracts) ...contract.tabIds,
    };

    for (final tabId in claimedTabIds) {
      final claimants = contracts
          .where((contract) => contract.tabIds.contains(tabId))
          .toList(growable: false);
      final mostSpecificTabIdCount = claimants
          .map((contract) => contract.tabIds.length)
          .reduce((left, right) => left < right ? left : right);

      expect(
        claimants.where(
          (contract) => contract.tabIds.length == mostSpecificTabIdCount,
        ),
        hasLength(1),
        reason: '$tabId must not resolve arbitrarily',
      );
    }
  });

  test('an unnamed tab falls back to complete family coverage', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-family-fallback',
      <Map<String, Object?>>[_binding('answers', 'searchAiAnswer')],
    );

    final answers = _declaredTab(experience: experience, tabId: 'answers');

    expect(answers.rendererContractId, 'ai-search');
  });

  test(
    'a family fallback contract must cover every family bound to the tab',
    () {
      final experience = _experienceWithBindings(
        'renderer-derivation-complete-coverage',
        <Map<String, Object?>>[
          _binding('answers', 'searchAiAnswer'),
          _binding('answers', 'unregistered-family'),
        ],
      );

      final answers = _declaredTab(experience: experience, tabId: 'answers');

      expect(answers.rendererContractId, 'engine-native-generic-list');
    },
  );

  test('verified predecessor families use canonical archetype names', () {
    final claimedFamilies = <String>{
      for (final contract in allTabRendererContracts())
        ...contract.surfaceFamilies,
    };

    expect(
      claimedFamilies,
      containsAll(const <String>{
        'approvalQueueItem',
        'statusTimeline',
        'formEntry',
        'documentLibrary',
        'discussionThread',
        'notificationInbox',
        'paymentCheckout',
      }),
    );
    expect(
      claimedFamilies.intersection(const <String>{
        'approval',
        'workflow-status',
        'form',
        'documents',
        'thread',
        'notification',
        'payment',
      }),
      isEmpty,
    );
  });
}
