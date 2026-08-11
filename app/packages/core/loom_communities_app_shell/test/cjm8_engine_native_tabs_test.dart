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
  });

  final LoomExperienceDefinition experience;
  final WorkflowEngineApi engine;
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

Future<_EngineNativeCommunityFixture> _installFixture(String extensionId) async {
  final sourcePath = _fixturesByExtension[extensionId];
  if (sourcePath == null) {
    throw StateError('No fixture mapping for extensionId "$extensionId"');
  }
  final source = jsonDecode(
    stripJsonComments(_fixtureFile(sourcePath).readAsStringSync()),
  ) as Map<String, dynamic>;
  final experience = experienceForExtensionId(
    extensionId,
    displayName: source['displayName'] as String?,
    experienceConfiguration: source['experience'] as Map<String, Object?>,
  );
  final engine = await workflowEngineForExtensionId(extensionId);
  return _EngineNativeCommunityFixture(experience: experience, engine: engine);
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
    'engine-native communities keep only closed real tab IDs and drop obsolete custom tab IDs',
    () async {
      for (final extensionId in _fixturesByExtension.keys) {
        final fixture = await _installFixture(extensionId);
        final personas = _personasByExtension[extensionId]!;
        final obsolete = _obsoleteIdsByExtension[extensionId]!;
        for (final personaId in personas) {
          final tabIds = [
            for (final tab in appShellTabsFor(
              experience: fixture.experience,
              personaId: personaId,
            ))
              tab.tabId,
          ];

          expect(
            tabIds.toSet().difference(_engineNativeTabIds),
            isEmpty,
            reason:
                'Extension $extensionId persona $personaId has non-real tab IDs: $tabIds',
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

    final cameraTabs = appShellTabsFor(
      experience: camera.experience,
      personaId: 'camera-club-member',
    );
    expect(
      cameraTabs.singleWhere((tab) => tab.tabId == 'calendar').label,
      'Walks',
    );

    final gardenTabs = appShellTabsFor(
      experience: garden.experience,
      personaId: 'garden-member',
    );
    expect(
      gardenTabs.singleWhere((tab) => tab.tabId == 'marketplace').label,
      'Exchange',
    );
  });

  test('seeded instances still render on canonical engine-native home/calendar tabs', () async {
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
        instanceId: 'mulch-day-shift',
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
  });

  test('legacy Cedar Commons HOA tab construction remains unchanged', () {
    final experience = experienceForExtensionId('ext_hoa');

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
      boardTabs.singleWhere((tab) => tab.tabId == 'documents').rendererContractId,
      'documents-library-detail',
    );
    expect(
      boardTabs.singleWhere((tab) => tab.tabId == 'admin').rendererContractId,
      'admin-review-compose-queue',
    );
    expect(
      boardTabs.map((tab) => tab.tabId),
      contains('documents'),
    );
    expect(
      homeownerTabs.map((tab) => tab.tabId),
      contains('documents'),
    );
  });
}
