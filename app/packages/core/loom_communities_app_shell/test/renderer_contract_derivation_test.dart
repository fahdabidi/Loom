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
  test('a sole tab-native archetype derives its dedicated tab surface', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-tab-native',
      <Map<String, Object?>>[
        _binding('scheduling', 'event-rsvp'),
        _binding('borrowing', 'equipment-loan'),
      ],
    );

    expect(
      _declaredTab(
        experience: experience,
        tabId: 'scheduling',
      ).rendererContractId,
      'calendar-agenda-event-detail',
    );
    expect(
      _declaredTab(
        experience: experience,
        tabId: 'borrowing',
      ).rendererContractId,
      'marketplace-browse-listing-detail',
    );
  });

  test('tab names do not affect the derived surface', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-open-tab-vocabulary',
      <Map<String, Object?>>[
        _binding('calendar', 'event-rsvp'),
        _binding('events', 'event-rsvp'),
      ],
    );

    for (final tabId in const <String>['calendar', 'events']) {
      expect(
        _declaredTab(experience: experience, tabId: tabId).rendererContractId,
        'calendar-agenda-event-detail',
        reason: tabId,
      );
    }
  });

  test('repeated bindings of one archetype still derive one tab surface', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-repeated-family',
      <Map<String, Object?>>[
        _binding('schedule', 'event-rsvp'),
        _binding('schedule', 'event-rsvp'),
      ],
    );

    expect(
      _declaredTab(
        experience: experience,
        tabId: 'schedule',
      ).rendererContractId,
      'calendar-agenda-event-detail',
    );
  });

  test('mixed archetypes always use the generic tab list', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-mixed',
      <Map<String, Object?>>[
        _binding('organize', 'event-rsvp'),
        _binding('organize', 'equipment-loan'),
      ],
    );

    expect(
      _declaredTab(
        experience: experience,
        tabId: 'organize',
      ).rendererContractId,
      'engine-native-generic-list',
    );
  });

  test('no bindings use the generic list regardless of the tab name', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-unbound',
      <Map<String, Object?>>[],
    );

    for (final tabId in const <String>['custom-tab', 'marketplace']) {
      expect(
        _declaredTab(experience: experience, tabId: tabId).rendererContractId,
        'engine-native-generic-list',
        reason: tabId,
      );
    }
  });

  test('card-only archetypes use the generic tab list', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-card-only',
      <Map<String, Object?>>[
        _binding('care', 'formEntry'),
        _binding('documents', 'exportWizard'),
        _binding('messages', 'discussionThread'),
        _binding('giving', 'paymentCheckout'),
      ],
    );

    for (final tabId in const <String>[
      'care',
      'documents',
      'messages',
      'giving',
    ]) {
      expect(
        _declaredTab(experience: experience, tabId: tabId).rendererContractId,
        'engine-native-generic-list',
        reason: tabId,
      );
    }
  });

  test('an unclaimed archetype uses the generic tab list', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-unclaimed',
      <Map<String, Object?>>[_binding('answers', 'unregistered-family')],
    );

    expect(
      _declaredTab(experience: experience, tabId: 'answers').rendererContractId,
      'engine-native-generic-list',
    );
  });

  test('the documented generic default behaves exactly like omission', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-default-equivalence',
      <Map<String, Object?>>[
        _binding('omitted', 'event-rsvp'),
        _binding('declared-default', 'event-rsvp'),
      ],
    );

    final omitted = _declaredTab(experience: experience, tabId: 'omitted');
    final declaredDefault = _declaredTab(
      experience: experience,
      tabId: 'declared-default',
      rendererContractId: 'engine-native-generic-list',
    );

    expect(declaredDefault.rendererContractId, omitted.rendererContractId);
    expect(declaredDefault.rendererContractId, 'calendar-agenda-event-detail');
  });

  test('an explicitly declared non-default renderer always wins', () {
    final experience = _experienceWithBindings(
      'renderer-derivation-explicit',
      <Map<String, Object?>>[_binding('schedule', 'event-rsvp')],
    );

    expect(
      _declaredTab(
        experience: experience,
        tabId: 'schedule',
        rendererContractId: 'documents-library-detail',
      ).rendererContractId,
      'documents-library-detail',
    );
  });

  test('each tab-native archetype names exactly one dedicated contract', () {
    expect(
      appShellTabNativeRendererContractIdsByArchetype,
      const <String, String>{
        'event-rsvp': 'calendar-agenda-event-detail',
        'equipment-loan': 'marketplace-browse-listing-detail',
      },
    );
    expect(
      appShellTabNativeRendererContractIdsByArchetype.values.toSet(),
      hasLength(appShellTabNativeRendererContractIdsByArchetype.length),
    );
    for (final entry
        in appShellTabNativeRendererContractIdsByArchetype.entries) {
      expect(
        tabRendererContractFor(entry.value).supportsSurfaceFamily(entry.key),
        isTrue,
        reason: '${entry.key} must be hosted by ${entry.value}',
      );
    }
  });

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
