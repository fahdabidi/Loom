import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

void main() {
  test('wf_arbitrary-local-package-ingestion', () {
    final fixture = _writePackagePair(
      communityId: 'community_chess_club',
      communityName: 'Chess Club',
      extensionId: 'ext_chess_club',
      cardAssetId: 'asset_card_chess',
      logoAssetId: 'asset_logo_chess',
      heroImageAssetId: 'asset_hero_chess',
      accentColor: '#58432F',
      extensionDisplayName: 'Chess Club',
    );
    final backend = LocalInAppBackend();
    final shell = CommunityAppShellRuntime();

    final report = backend.installLocalPackagePairFromFiles(
      extensionPackagePath: fixture.extensionPath,
      initializationPackagePath: fixture.initializationPath,
    );
    shell.installCommunity(
      CommunityCardProps(
        communityId: report.community.communityId,
        handle: 'chess-club',
        branding: CommunityCardBranding(
          displayName: report.community.displayName,
          tagline: 'Local arbitrary package',
          category: 'club',
          accentColor: report.community.accentColor,
          altText: 'Chess Club',
          logoAssetId: report.community.logoAssetId,
          cardImageAssetId: report.community.cardImageAssetId,
          heroImageAssetId: report.community.heroImageAssetId,
          extensionDefaultCardImageAssetId: 'asset_default_chess',
        ),
      ),
    );
    shell.openExtension('local:${report.community.extensionId}@latest');

    expect(backend.isExtensionLoaded('ext_chess_club'), isTrue);
    expect(report.community.communityId, 'community_chess_club');
    expect(report.community.displayName, 'Chess Club');
    expect(report.community.logoAssetId, 'asset_logo_chess');
    expect(report.community.heroImageAssetId, 'asset_hero_chess');
    expect(bindCommunityCard(shell.cards.single).displayName, 'Chess Club');
    expect(
      bindCommunityCard(shell.cards.single).imageAssetId,
      'asset_card_chess',
    );
    expect(shell.openExtensionId, 'local:ext_chess_club@latest');
  });
}

_PackagePairFixture _writePackagePair({
  required String communityId,
  required String communityName,
  required String extensionId,
  required String extensionDisplayName,
  required String cardAssetId,
  required String logoAssetId,
  required String heroImageAssetId,
  required String accentColor,
}) {
  final tempDir = Directory.systemTemp.createTempSync('loom_b9_arbitrary_');
  final extensionFile = File('${tempDir.path}/$extensionId.loom-extension.zip');
  final initializationFile = File('${tempDir.path}/$extensionId.loom-init.zip');
  extensionFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'mode': 'local-demo',
      'extensionId': extensionId,
      'displayName': extensionDisplayName,
      'version': '1.0.0',
      'permissions': ['content.publish', 'events.write', 'community.install'],
      'assets': [
        {
          'assetId': cardAssetId,
          'kind': 'cardImage',
          'path': 'assets/card.png',
        },
        {'assetId': logoAssetId, 'kind': 'logo', 'path': 'assets/logo.png'},
        {
          'assetId': heroImageAssetId,
          'kind': 'hero',
          'path': 'assets/hero.png',
        },
      ],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'communityId': communityId,
      'communityName': communityName,
      'extensionId': extensionId,
      'seedDataFiles': ['seed/community.json', 'seed/workflows.json'],
      'branding': {
        'cardAssetId': cardAssetId,
        'logoAssetId': logoAssetId,
        'heroImageAssetId': heroImageAssetId,
        'accentColor': accentColor,
      },
    }),
  );
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
