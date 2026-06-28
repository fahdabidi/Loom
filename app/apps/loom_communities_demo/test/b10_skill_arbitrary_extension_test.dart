import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

void main() {
  test('wf_skill-arbitrary-extension-test-run', () {
    final extensionJson = _readJson(
      'docs/Build Plan V2/Skill/examples/arbitrary-garden-club/loom.extension.json',
    );
    final initializationJson = _readJson(
      'docs/Build Plan V2/Skill/examples/arbitrary-garden-club/loom.initialization.json',
    );
    final fixture = _writePackageFiles(extensionJson, initializationJson);
    final backend = LocalInAppBackend();
    final shell = CommunityAppShellRuntime();

    final report = backend.installLocalPackagePairFromFiles(
      extensionPackagePath: fixture.extensionPath,
      initializationPackagePath: fixture.initializationPath,
    );
    shell.installCommunity(
      CommunityCardProps(
        communityId: report.community.communityId,
        handle: 'garden-club',
        branding: CommunityCardBranding(
          displayName: report.community.displayName,
          tagline: 'Skill generated arbitrary extension',
          category: 'club',
          accentColor: report.community.accentColor,
          altText: 'Garden Club',
          logoAssetId: report.community.logoAssetId,
          cardImageAssetId: report.community.cardImageAssetId,
          heroImageAssetId: report.community.heroImageAssetId,
          extensionDefaultCardImageAssetId:
              'assets/brand/garden-default-card.png',
        ),
      ),
    );
    shell.openExtension('local:${report.community.extensionId}@latest');

    expect(extensionJson['mode'], 'local-demo');
    expect(extensionJson['extensionId'], 'ext_garden_club');
    expect(initializationJson['displayName'], 'Garden Club');
    expect(backend.isExtensionLoaded('ext_garden_club'), isTrue);
    expect(report.community.displayName, 'Garden Club');
    expect(report.community.cardImageAssetId, 'seed/assets/garden-card.png');
    expect(report.community.logoAssetId, 'seed/assets/garden-logo.png');
    expect(report.community.heroImageAssetId, 'seed/assets/garden-hero.png');
    expect(report.importedSeedFiles, contains('seed/events.json'));
    expect(bindCommunityCard(shell.cards.single).displayName, 'Garden Club');
    expect(
      bindCommunityCard(shell.cards.single).imageAssetId,
      'seed/assets/garden-card.png',
    );
    expect(shell.openExtensionId, 'local:ext_garden_club@latest');
  });
}

Map<String, Object?> _readJson(String path) {
  final candidates = ['../$path', '../../../$path'];
  File? file;
  for (final candidate in candidates) {
    final candidateFile = File(candidate);
    if (candidateFile.existsSync()) {
      file = candidateFile;
      break;
    }
  }
  if (file == null) {
    fail('Could not find $path from ${Directory.current.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

_PackagePairFixture _writePackageFiles(
  Map<String, Object?> extensionJson,
  Map<String, Object?> initializationJson,
) {
  final tempDir = Directory.systemTemp.createTempSync('loom_b10_skill_');
  final extensionFile = File('${tempDir.path}/garden-club.loom-extension.zip');
  final initializationFile = File('${tempDir.path}/garden-club.loom-init.zip');
  extensionFile.writeAsStringSync(jsonEncode(extensionJson));
  initializationFile.writeAsStringSync(jsonEncode(initializationJson));
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}
