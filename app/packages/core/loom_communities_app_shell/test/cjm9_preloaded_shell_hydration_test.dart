import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'authz_p6_test_helpers.dart';

const _cameraFixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc';
const _gardenFixtureRelative =
    'docs/references/communities/Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc';

class _PreloadedShellInstallation {
  const _PreloadedShellInstallation({
    required this.backend,
    required this.report,
    required this.incomingPackage,
    required this.incomingExperience,
    required this.initialCommunity,
    required this.temp,
  });

  final LocalInAppBackend backend;
  final LocalBackendImportReport report;
  final Map<String, Object?> incomingPackage;
  final Map<String, Object?> incomingExperience;
  final LocalInstalledCommunity? initialCommunity;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

Future<_PreloadedShellInstallation> _installOverPreloadedShell({
  required String fixtureRelative,
  String? extensionId,
  String? communityId,
}) async {
  final source = _readFixture(fixtureRelative);
  final resolvedExtensionId =
      extensionId ?? _stringValue(source, 'extensionId');
  source['extensionId'] = resolvedExtensionId;
  final resolvedCommunityId =
      communityId ?? _stringValue(source, 'communityId');
  source['communityId'] = resolvedCommunityId;
  final extensionManifest = _extensionManifestFromSource(
    source,
    resolvedExtensionId,
  );
  final incomingExperience = _experienceFromSource(source);

  final temp = await Directory.systemTemp.createTemp(
    'loom-cjm9-preloaded-$resolvedExtensionId-',
  );
  final extensionFile = File(
    '${temp.path}/${resolvedExtensionId}.loom-extension.zip',
  );
  final initializationFile = File(
    '${temp.path}/${resolvedExtensionId}.loom-init.zip',
  );
  await extensionFile.writeAsString(jsonEncode(extensionManifest));
  await initializationFile.writeAsString(jsonEncode(source));

  final preload = await preloadBundledExampleCommunities();
  final backend = LocalInAppBackend(snapshot: preload.snapshot);
  final preloadedCommunities = backend.listCommunities().where(
    (community) => community.communityId == resolvedCommunityId,
  );
  final snapshotCommunity = preloadedCommunities.isEmpty
      ? null
      : preloadedCommunities.single;
  final report = backend.installLocalPackagePairFromFiles(
    extensionPackagePath: extensionFile.path,
    initializationPackagePath: initializationFile.path,
  );
  return _PreloadedShellInstallation(
    backend: backend,
    report: report,
    incomingPackage: source,
    incomingExperience: incomingExperience,
    initialCommunity: snapshotCommunity,
    temp: temp,
  );
}

Map<String, Object?> _readFixture(String relativePath) {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    final file = File('${directory.path}/$relativePath');
    if (file.existsSync()) {
      return jsonDecode(stripJsonComments(file.readAsStringSync()))
          as Map<String, Object?>;
    }
    directory = directory.parent;
  }
  throw StateError('Could not find fixture: $relativePath');
}

Map<String, Object?> _experienceFromSource(Map<String, Object?> source) {
  final experience = source['experience'];
  if (experience is Map<String, Object?>) {
    return experience;
  }
  throw StateError(
    'Missing experience block in fixture community ${source['communityId']}',
  );
}

String _stringValue(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw StateError('Fixture missing required string "$key".');
}

void _expectCoherentHydratedVersionScheme(
  _PreloadedShellInstallation installation,
) {
  final incomingPackage = installation.incomingPackage;
  final incomingExperience = installation.incomingExperience;
  final installedCommunity = installation.report.community;
  final installedExperience = installedCommunity.experienceConfiguration;

  expect(incomingPackage['specVersion'], currentCommunitySpecVersion);
  expect(installedCommunity.specVersion, currentCommunitySpecVersion);
  expect(incomingPackage.containsKey('schemaVersion'), isFalse);
  for (final key in const <String>[
    'experienceSchemaVersion',
    'workflowGrammarVersion',
  ]) {
    expect(incomingExperience.containsKey(key), isFalse);
    expect(installedExperience.containsKey(key), isFalse);
  }
}

Map<String, Object?> _extensionManifestFromSource(
  Map<String, Object?> source,
  String extensionId,
) {
  return <String, Object?>{
    'specVersion': currentCommunitySpecVersion,
    'mode': 'local-demo',
    'extensionId': extensionId,
    'displayName': _stringValue(source, 'displayName'),
    'version': '1.0.0',
    'permissions': const <String>[
      'community.install',
      'content.publish',
      'events.write',
      'forms.write',
    ],
  };
}

bool _hasMarketplaceBinding(LoomWorkflowStateMachine definition) {
  return definition.renderBindings.any(
    (binding) => binding.tabId == 'marketplace',
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxAttempts = 80,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  throw TestFailure('Timed out waiting for ${finder.toString()}.');
}

Future<void> _pumpForUi(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _selectTab(WidgetTester tester, String tabId) async {
  final tab = find.byKey(ValueKey('community-tab-$tabId'));
  expect(tab, findsOneWidget);
  await tester.ensureVisible(tab);
  await tester.tap(tab, warnIfMissed: false);
  await _pumpForUi(tester);
}

Widget _communityScreen({
  required LocalInstalledCommunity community,
  required List<String> seedDataFiles,
  String? accountId,
}) {
  return MaterialApp(
    home: LocalExtensionScreen(
      community: community,
      seedDataFiles: seedDataFiles,
      authApi: activeAuthForInstalledCommunity(
        community: community,
        accountId: accountId,
      ),
    ),
  );
}

void main() {
  test(
    'preloaded garden shell already carries the canonical package experience',
    () async {
      final installation = await _installOverPreloadedShell(
        fixtureRelative: _gardenFixtureRelative,
      );
      try {
        expect(
          installation.initialCommunity!.experienceConfiguration,
          equals(installation.incomingExperience),
        );
        expect(installation.report.created, isFalse);
        expect(
          installation.report.community.experienceConfiguration,
          equals(installation.incomingExperience),
        );
        _expectCoherentHydratedVersionScheme(installation);
        expect(
          installation.report.community.experienceConfiguration.isNotEmpty,
          isTrue,
        );
        final experience = experienceForExtensionId(
          installation.report.community.extensionId,
          displayName: installation.report.community.displayName,
          specVersion: installation.report.community.specVersion,
          experienceConfiguration:
              installation.report.community.experienceConfiguration,
        );
        final gardenToolLoan =
            experience.workflowDefinitions?['garden-tool-loan'];
        final gardenToolGiveaway =
            experience.workflowDefinitions?['garden-tool-giveaway'];

        expect(gardenToolLoan, isNotNull);
        expect(gardenToolGiveaway, isNotNull);
        expect(_hasMarketplaceBinding(gardenToolLoan!), isTrue);
        expect(_hasMarketplaceBinding(gardenToolGiveaway!), isTrue);
      } finally {
        await installation.dispose();
      }
    },
  );

  test(
    'preloaded camera shell retains its canonical marketplace binding',
    () async {
      final installation = await _installOverPreloadedShell(
        fixtureRelative: _cameraFixtureRelative,
      );
      try {
        expect(
          installation.initialCommunity!.experienceConfiguration,
          equals(installation.incomingExperience),
        );
        expect(installation.report.created, isFalse);
        expect(
          installation.report.community.experienceConfiguration,
          equals(installation.incomingExperience),
        );
        _expectCoherentHydratedVersionScheme(installation);
        final experience = experienceForExtensionId(
          installation.report.community.extensionId,
          displayName: installation.report.community.displayName,
          specVersion: installation.report.community.specVersion,
          experienceConfiguration:
              installation.report.community.experienceConfiguration,
        );
        final gearRequest =
            experience.workflowDefinitions?['gear-loan-request'];
        expect(gearRequest, isNotNull);
        expect(_hasMarketplaceBinding(gearRequest!), isTrue);
      } finally {
        await installation.dispose();
      }
    },
  );

  testWidgets(
    'preloaded Garden install renders Exchange via engine-native marketplace surface',
    (tester) async {
      final installation = (await tester.runAsync(
        () =>
            _installOverPreloadedShell(fixtureRelative: _gardenFixtureRelative),
      ))!;
      try {
        await tester.pumpWidget(
          _communityScreen(
            community: installation.report.community,
            seedDataFiles: installation.report.importedSeedFiles,
            accountId: 'garden-member',
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('community-tab-marketplace')),
        );
        await _selectTab(tester, 'marketplace');
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-marketplace-root')),
        );

        expect(
          find.byKey(const ValueKey('engine-native-marketplace-root')),
          findsOneWidget,
        );
        expect(find.text('Exchange is coming to Garden Club'), findsNothing);
      } finally {
        await tester.runAsync(installation.dispose);
      }
    },
  );

  testWidgets(
    'phone-viewport calendar grid reaches the seeded March event by scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final installation = (await tester.runAsync(
        () => _installOverPreloadedShell(
          fixtureRelative: _gardenFixtureRelative,
          extensionId: 'ext_garden_club_phone_scroll',
          communityId: 'community_garden_club_phone_scroll',
        ),
      ))!;
      try {
        await tester.pumpWidget(
          _communityScreen(
            community: installation.report.community,
            seedDataFiles: installation.report.importedSeedFiles,
            accountId: 'garden-member',
          ),
        );
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('community-tab-calendar')),
        );
        await _selectTab(tester, 'calendar');
        await _pumpUntil(
          tester,
          find.byKey(const ValueKey('engine-native-calendar-root')),
        );

        final dayCell = find.byKey(
          const ValueKey('engine-native-calendar-date-2027-03-13'),
        );
        final eventTile = find.byKey(
          const ValueKey('engine-native-calendar-entry-spring-workshop-0'),
        );

        // The tile is built (so a widget-existence assertion would pass), but
        // on a phone viewport it starts below the fold. Reachability is the
        // property under test, not tree membership.
        expect(dayCell, findsOneWidget);
        expect(eventTile, findsOneWidget);
        final initialRect = tester.getRect(eventTile);
        final viewportHeight =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        expect(initialRect.top, greaterThanOrEqualTo(viewportHeight));
        expect(initialRect.bottom, greaterThan(viewportHeight));

        // Drive the page scroll itself (equivalent to an `adb input swipe`)
        // until the tile is actually on-screen, without calling
        // ensureVisible, which would mask a broken scroll gesture.
        var attempts = 0;
        while ((tester.getRect(eventTile).bottom > viewportHeight ||
                tester.getRect(eventTile).top < 0) &&
            attempts < 40) {
          await tester.timedDrag(
            find.byType(Scaffold).first,
            const Offset(0, -200),
            const Duration(milliseconds: 120),
          );
          await tester.pump(const Duration(milliseconds: 40));
          attempts++;
        }

        final visibleRect = tester.getRect(eventTile);
        expect(visibleRect.top, greaterThanOrEqualTo(-0.5));
        expect(visibleRect.bottom, lessThanOrEqualTo(viewportHeight + 0.5));

        // A real tap hits the now-reachable tile and opens its detail. This
        // is the hit-test proof (tester.tap warns when nothing is hit).
        await tester.tap(eventTile, warnIfMissed: false);
        await tester.pump();
        expect(
          find.byKey(
            const ValueKey(
              'engine-native-calendar-selected-detail-spring-workshop-0',
            ),
          ),
          findsOneWidget,
        );
      } finally {
        await tester.runAsync(installation.dispose);
      }
    },
  );
}
