import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_extension_package/loom_extension_package.dart';

void main() {
  test('wf_local-demo-prereq-to-validation-ready', () {
    final prereq = _readJson('docs/Build Plan V2/Skill/setup/prereq-manifest.json');
    final lock = _readJson(
      'docs/Build Plan V2/Skill/setup/validation-environment.lock.json',
    );

    expect(prereq['supportedExecutionTargets'], contains('codex'));
    expect(lock['executionTarget'], 'codex');
    expect(lock['skillMode'], 'local-demo');
    expect(lock['validationReady'], isTrue);
  });

  test('wf_local-build-download-sideload-install', () {
    final backend = LocalInAppBackend();
    final shell = CommunityAppShellRuntime();
    backend.loadExtensionPackage(_extension());
    final report = backend.importInitializationPackage(
      _initialization(),
      logoAssetId: 'asset_logo_book_club',
      heroImageAssetId: 'asset_hero_book_club',
    );
    shell.installCommunity(
      CommunityCardProps(
        communityId: report.community.communityId,
        handle: 'book-club',
        branding: CommunityCardBranding(
          displayName: report.community.displayName,
          tagline: 'Read together',
          category: 'book',
          accentColor: report.community.accentColor,
          altText: 'Book club table',
          logoAssetId: report.community.logoAssetId,
          cardImageAssetId: report.community.cardImageAssetId,
          heroImageAssetId: report.community.heroImageAssetId,
          extensionDefaultCardImageAssetId: 'asset_default_book_club',
        ),
      ),
    );
    shell.openExtension('local:${report.community.extensionId}@latest');

    expect(backend.listCommunities(), hasLength(1));
    expect(bindCommunityCard(shell.cards.single).imageAssetId, 'asset_card_book_club');
    expect(shell.openExtensionId, 'local:ext_book_club@latest');
  });
}

Map<String, Object?> _readJson(String path) {
  final candidates = [
    '../$path',
    '../../../$path',
  ];
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

LoomExtensionPackageSummary _extension() {
  return const LoomExtensionPackageSummary(
    extensionId: 'ext_book_club',
    displayName: 'Book Club',
    version: '1.0.0',
    permissions: ['content.publish'],
    assetIds: ['asset_card_book_club', 'asset_logo_book_club'],
  );
}

LoomInitializationPackageSummary _initialization() {
  return const LoomInitializationPackageSummary(
    communityId: 'community_book_club',
    communityName: 'Neighborhood Book Club',
    extensionId: 'ext_book_club',
    seedDataFiles: ['seed/community.json', 'seed/workflows.json'],
    cardAssetId: 'asset_card_book_club',
  );
}
