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
    'absent renderer derives the tab-specific contract from all bound families',
    () {
      final experience = _experienceWithBindings(
        'renderer-derivation-marketplace',
        <Map<String, Object?>>[
          _binding('marketplace', 'equipment-loan'),
          _binding('marketplace', 'exchange'),
          _binding('calendar', 'event-rsvp'),
        ],
      );

      final marketplace = _declaredTab(
        experience: experience,
        tabId: 'marketplace',
      );

      // Home also covers both families. The Marketplace contract wins because
      // it is the matching contract that declares this tabId.
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
  });

  test('an unbound absent renderer keeps the generic fallback', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-fallback',
      <Map<String, Object?>>[],
    );

    final customTab = _declaredTab(experience: experience, tabId: 'custom-tab');

    expect(customTab.rendererContractId, 'engine-native-generic-list');
  });

  test('a contract must cover every family bound to the tab', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-complete-coverage',
      <Map<String, Object?>>[
        _binding('marketplace', 'equipment-loan'),
        _binding('marketplace', 'unregistered-family'),
      ],
    );

    final marketplace = _declaredTab(
      experience: experience,
      tabId: 'marketplace',
    );

    expect(marketplace.rendererContractId, 'engine-native-generic-list');
  });
}
