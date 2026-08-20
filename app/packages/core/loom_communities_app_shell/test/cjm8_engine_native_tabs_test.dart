import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
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

class _EngineNativeCommunityFixture {
  _EngineNativeCommunityFixture({
    required this.community,
    required this.experience,
    required this.engine,
    required this.declaredTabIds,
  });

  final LocalInstalledCommunity community;
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
  source['extensionId'] = extensionId;
  final temp = await Directory.systemTemp.createTemp('loom-cjm8-$extensionId-');
  late final LocalInstalledCommunity community;
  try {
    final extension = File('${temp.path}/$extensionId.loom-extension.zip');
    final initialization = File('${temp.path}/$extensionId.loom-init.zip');
    await extension.writeAsString(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'extensionId': extensionId,
        'displayName': source['displayName'],
        'version': '1.0.0',
        'mode': 'local-demo',
        'permissions': <String>[],
      }),
    );
    await initialization.writeAsString(jsonEncode(source));
    community = LocalInAppBackend()
        .installLocalPackagePairFromFiles(
          extensionPackagePath: extension.path,
          initializationPackagePath: initialization.path,
        )
        .community;
  } finally {
    await temp.delete(recursive: true);
  }
  final experienceRaw = community.experienceConfiguration;
  final declaredTabIds = {
    ..._declaredTabIdsFromShell(community.appShellConfiguration),
    ..._declaredTabIdsFromShell(experienceRaw['appShell']),
  };
  final experience = experienceForExtensionId(
    extensionId,
    displayName: community.displayName,
    specVersion: community.specVersion,
    experienceConfiguration: experienceRaw,
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
    appShellConfiguration: community.appShellConfiguration,
    activeMembershipLookup: (_) async => true,
  );
  final engine = await workflowEngineForExtensionId(extensionId);
  return _EngineNativeCommunityFixture(
    community: community,
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
        final allowedTabIds = {
          ..._engineNativeTabIds,
          ...fixture.declaredTabIds,
        };
        for (final personaId in personas) {
          final tabIds = [
            for (final tab in appShellTabsFor(
              experience: fixture.experience,
              personaId: personaId,
              appShellConfiguration: fixture.community.appShellConfiguration,
            ))
              tab.tabId,
          ];

          expect(
            tabIds.toSet().difference(allowedTabIds),
            isEmpty,
            reason:
                'Extension $extensionId persona $personaId has tabs outside home/messages/special + community-declared set: $tabIds',
          );
        }
      }
    },
  );

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
}
