import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _engineNativeTabIds = {
  'home',
  'calendar',
  'marketplace',
  'giving',
  'admin',
  'messages',
};

const _fixturesByExtension = {
  'ext_camera_club':
      'docs/references/communities/Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
  'ext_book_club':
      'docs/references/communities/Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc',
  'ext_garden_club':
      'docs/references/communities/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
  'ext_chess_club':
      'docs/references/communities/Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
  'ext_mosque':
      'docs/references/communities/Loom_Communities_Workflow_Engine_MasjidNur_Example.jsonc',
  'ext_youth_soccer':
      'docs/references/communities/Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc',
};

const _personasByExtension = {
  'ext_camera_club': ['camera-club-organizer', 'camera-club-member'],
  'ext_book_club': ['book-organizer', 'book-member'],
  'ext_garden_club': ['garden-coordinator', 'garden-member'],
  'ext_chess_club': ['chess-organizer', 'chess-member'],
  'ext_mosque': ['masjid-admin', 'community-member'],
  'ext_youth_soccer': ['soccer-coach', 'soccer-guardian'],
};

const _obsoleteIdsByExtension = {
  'ext_camera_club': ['critique'],
  'ext_book_club': ['books', 'documents', 'search'],
  'ext_garden_club': ['care'],
  'ext_chess_club': ['matches', 'rankings', 'documents'],
  'ext_mosque': ['care', 'search'],
  'ext_youth_soccer': ['registration', 'team', 'documents'],
};

class _EngineNativeCommunityFixture {
  _EngineNativeCommunityFixture({
    required this.experience,
    required this.engine,
    required this.declaredTabIds,
  });

  final LoomExperienceDefinition experience;
  final WorkflowEngineApi engine;
  final Set<String> declaredTabIds;
}

Set<String> _declaredTabIdsFromShell(Object? value) {
  if (value is! Map<String, Object?>) {
    return const {};
  }
  final ids = <String>{};
  final appTabs = _readStringValuesFromList(value['tabs']);
  final personaTabs = value['roleTabs'];
  ids.addAll(appTabs);
  if (personaTabs is Map<String, Object?>) {
    for (final tabList in personaTabs.values) {
      ids.addAll(_readStringValuesFromList(tabList));
    }
  }
  return ids;
}

Set<String> _readStringValuesFromList(Object? value) {
  if (value is! List<Object?>) {
    return const {};
  }
  return {
    for (final item in value)
      if (item is Map<String, Object?>)
        if (item['tabId'] is String &&
            (item['tabId'] as String).trim().isNotEmpty)
          (item['tabId'] as String).trim(),
  };
}

class _SeededInstanceFixtureCheck {
  const _SeededInstanceFixtureCheck({
    required this.extensionId,
    required this.personaId,
    required this.tabId,
    required this.instanceId,
  });

  final String extensionId;
  final String personaId;
  final String tabId;
  final String instanceId;
}

File _fixtureFile(String relativePath) {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${directory.path}/$relativePath');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Could not locate fixture file: $relativePath');
}

Future<_EngineNativeCommunityFixture> _installFixture(
  String extensionId,
) async {
  final sourcePath = _fixturesByExtension[extensionId];
  if (sourcePath == null) {
    throw StateError('No fixture mapping for extensionId "$extensionId"');
  }
  final source =
      jsonDecode(stripJsonComments(_fixtureFile(sourcePath).readAsStringSync()))
          as Map<String, dynamic>;
  final experienceRaw = source['experience'] as Map<String, Object?>?;
  final declaredTabIds = {
    ..._declaredTabIdsFromShell(source['appShell']),
    ..._declaredTabIdsFromShell(experienceRaw?['appShell']),
  };
  final experience = experienceForExtensionId(
    extensionId,
    displayName: source['displayName'] as String?,
    specVersion: source['specVersion'] as int?,
    experienceConfiguration: experienceRaw ?? const <String, Object?>{},
  );
  // These fixtures model someone already inside their own community, so
  // membership has to be established through the same hook production uses.
  // `_isActiveMember` returns false whenever no lookup is set, which makes
  // every `membersOnly` workflow invisible -- not an "unknown, allow" default.
  // Communities whose workflows are all `public` (Camera Club) never notice;
  // Garden Club, whose marketplace and volunteer surfaces are `membersOnly`,
  // is where it shows.
  configureEngineAuthorizationForExtensionId(
    extensionId: extensionId,
    appShellConfiguration: const <String, Object?>{},
    activeMembershipLookup: (_) async => true,
  );
  final engine = await workflowEngineForExtensionId(extensionId);
  return _EngineNativeCommunityFixture(
    experience: experience,
    engine: engine,
    declaredTabIds: declaredTabIds,
  );
}

Future<bool> _tabRendersSeededInstance({
  required _EngineNativeCommunityFixture fixture,
  required String tabId,
  required String personaId,
  required String instanceId,
}) async {
  final page = await fixture.engine.queryInstances(
    tabId: tabId,
    personaId: personaId,
    limit: 200,
  );
  return page.items.any((instance) => instance.instanceId == instanceId);
}

void main() {
  test(
    'engine-native communities keep only allowed appShell/open canonical tab IDs',
    () async {
      for (final extensionId in _fixturesByExtension.keys) {
        final fixture = await _installFixture(extensionId);
        final personas = _personasByExtension[extensionId]!;
        final obsolete = _obsoleteIdsByExtension[extensionId]!;
        final allowedTabIds = {
          ..._engineNativeTabIds,
          ...fixture.declaredTabIds,
        };
        for (final personaId in personas) {
          final tabIds = [
            for (final tab in appShellTabsFor(
              experience: fixture.experience,
              personaId: personaId,
            ))
              tab.tabId,
          ];

          expect(
            tabIds.toSet().difference(allowedTabIds),
            isEmpty,
            reason:
                'Extension $extensionId persona $personaId has tabs outside home/messages/special + community-declared set: $tabIds',
          );

          for (final obsoleteId in obsolete) {
            expect(
              tabIds,
              isNot(contains(obsoleteId)),
              reason:
                  'Extension $extensionId persona $personaId still includes obsolete tab "$obsoleteId".',
            );
          }
        }
      }
    },
  );

  test('engine-native label overrides for real tab IDs remain', () async {
    final camera = await _installFixture('ext_camera_club');
    final garden = await _installFixture('ext_garden_club');

    // Both of these model a *member* reading the shell, so both must supply
    // membership the way the app does. `appShellTabsFor` gates `membersOnly`
    // workflows on `hasActiveMembership == true`, and omitting it is not
    // "unknown, allow" -- a null fails closed and hides the tab. All three
    // production call sites in part01 pass `_activeAccountHasActiveMembership`;
    // a test that omits it is asserting against a state the app never reaches.
    //
    // Camera Club masked this for a long time: every one of its workflows is
    // `public`, so its tabs survive with or without membership. Garden Club's
    // `marketplace` is served only by `garden-tool-loan` and
    // `garden-tool-giveaway`, both `membersOnly`, so it is the first community
    // where the omission actually shows.
    final cameraTabs = appShellTabsFor(
      experience: camera.experience,
      personaId: 'camera-club-member',
      hasActiveMembership: true,
    );
    final gardenTabs = appShellTabsFor(
      experience: garden.experience,
      personaId: 'garden-member',
      hasActiveMembership: true,
    );
    expect(
      cameraTabs.singleWhere((tab) => tab.tabId == 'calendar').label,
      'Walks',
    );
    // `Exchange` is correct and always was -- it is the engine-native label
    // override, which is the whole point of this test. Do not "fix" it to
    // `Marketplace` by reading `appShell.tabs[].label` from the package root:
    // that is a different value, and `appShellTabsFor` does not derive the
    // label from it. The only thing wrong here was the missing membership.
    expect(
      gardenTabs.singleWhere((tab) => tab.tabId == 'marketplace').label,
      'Exchange',
    );
  });

  test(
    'seeded instances still render on canonical engine-native home/calendar tabs',
    () async {
      final checks = <_SeededInstanceFixtureCheck>[
        const _SeededInstanceFixtureCheck(
          extensionId: 'ext_camera_club',
          personaId: 'camera-club-member',
          tabId: 'home',
          instanceId: 'critique-lighthouse-portrait',
        ),
        const _SeededInstanceFixtureCheck(
          extensionId: 'ext_book_club',
          personaId: 'book-organizer',
          tabId: 'home',
          instanceId: 'vote-august',
        ),
        const _SeededInstanceFixtureCheck(
          extensionId: 'ext_garden_club',
          personaId: 'garden-coordinator',
          tabId: 'home',
          // Renamed by 154493e6 (Garden Club exportWizard integration,
          // Milestone 1.5); this test was not updated with it. Same instance,
          // same garden-volunteer-shift binding on `home` -- id only.
          instanceId: 'mulch-delivery-shift',
        ),
      ];

      for (final check in checks) {
        final fixture = await _installFixture(check.extensionId);
        expect(
          await _tabRendersSeededInstance(
            fixture: fixture,
            tabId: check.tabId,
            personaId: check.personaId,
            instanceId: check.instanceId,
          ),
          isTrue,
          reason:
              '${check.extensionId} does not render seeded instance ${check.instanceId} on tab ${check.tabId} for persona ${check.personaId}.',
        );
      }
    },
  );

  test('legacy Cedar Commons HOA tab construction remains unchanged', () {
    final experience = experienceForExtensionId(
      'ext_hoa',
      specVersion: currentCommunitySpecVersion,
    );

    final boardTabs = [
      for (final tab in appShellTabsFor(
        experience: experience,
        personaId: 'hoa-board',
      ))
        tab,
    ];
    final homeownerTabs = [
      for (final tab in appShellTabsFor(
        experience: experience,
        personaId: 'hoa-homeowner',
      ))
        tab,
    ];

    expect(boardTabs.map((tab) => tab.tabId), containsAll(['home', 'admin']));
    expect(homeownerTabs.map((tab) => tab.tabId), isNot(contains('admin')));
    expect(
      boardTabs
          .singleWhere((tab) => tab.tabId == 'documents')
          .rendererContractId,
      'documents-library-detail',
    );
    expect(
      boardTabs.singleWhere((tab) => tab.tabId == 'admin').rendererContractId,
      'admin-review-compose-queue',
    );
    expect(boardTabs.map((tab) => tab.tabId), contains('documents'));
    expect(homeownerTabs.map((tab) => tab.tabId), contains('documents'));
  });
}
