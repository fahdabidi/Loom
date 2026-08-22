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
  final LocalInstalledCommunity initialCommunity;
  final Directory temp;

  Future<void> dispose() => temp.delete(recursive: true);
}

Future<_PreloadedShellInstallation> _installOverPreloadedShell({
  required String fixtureRelative,
}) async {
  final source = _readFixture(fixtureRelative);
  final extensionId = _stringValue(source, 'extensionId');
  final communityId = _stringValue(source, 'communityId');
  final extensionManifest = _extensionManifestFromSource(source, extensionId);
  final incomingExperience = _experienceFromSource(source);

  final temp = await Directory.systemTemp.createTemp(
    'loom-cjm9-preloaded-$extensionId-',
  );
  final extensionFile = File('${temp.path}/${extensionId}.loom-extension.zip');
  final initializationFile = File('${temp.path}/${extensionId}.loom-init.zip');
  await extensionFile.writeAsString(jsonEncode(extensionManifest));
  await initializationFile.writeAsString(jsonEncode(source));

  final backend = LocalInAppBackend(
    snapshot: preloadedExampleCommunitiesSnapshot(),
  );
  final snapshotCommunity = backend.listCommunities().singleWhere(
    (community) => community.communityId == communityId,
  );
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
    'preloaded garden shell is hydrated with incoming canonical schema-v2 experience',
    () async {
      final installation = await _installOverPreloadedShell(
        fixtureRelative: _gardenFixtureRelative,
      );
      try {
        expect(installation.initialCommunity.experienceConfiguration, isEmpty);
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
    'camera shell hydrates canonical binding into marketplace flow',
    () async {
      final installation = await _installOverPreloadedShell(
        fixtureRelative: _cameraFixtureRelative,
      );
      try {
        expect(installation.initialCommunity.experienceConfiguration, isEmpty);
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
}
