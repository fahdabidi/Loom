import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_ux_judges/src/validator/jsonc.dart';

import 'workflow_ui_test_harness.dart';

class _ProductCommunity {
  const _ProductCommunity({
    required this.extensionId,
    required this.communityName,
    required this.shippedSourceName,
    required this.bundledAssetName,
  });

  final String extensionId;
  final String communityName;
  final String shippedSourceName;
  final String bundledAssetName;
}

const _productCommunitiesByDoc = <String, _ProductCommunity>{
  'ad-free-community-product-experience.md': _ProductCommunity(
    extensionId: 'ext_ad_free_community',
    communityName: 'Ad-Free Community',
    shippedSourceName:
        'Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc',
    bundledAssetName:
        'Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc',
  ),
  'camera-club-product-experience.md': _ProductCommunity(
    extensionId: 'ext_camera_club',
    communityName: 'Camera Club',
    shippedSourceName:
        'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
    bundledAssetName:
        'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
  ),
  'cedar-commons-hoa-product-experience.md': _ProductCommunity(
    extensionId: 'ext_cedar_commons_hoa',
    communityName: 'Cedar Commons HOA',
    shippedSourceName:
        'Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc',
    bundledAssetName:
        'Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc',
  ),
  'chess-club-product-experience.md': _ProductCommunity(
    extensionId: 'ext_chess_club',
    communityName: 'Chess Club',
    shippedSourceName:
        'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
    bundledAssetName:
        'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
  ),
  'data-portability-community-product-experience.md': _ProductCommunity(
    extensionId: 'ext_data_portability_community',
    communityName: 'Data Portability Community',
    shippedSourceName:
        'Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc',
    bundledAssetName:
        'Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc',
  ),
  'garden-club-product-experience.md': _ProductCommunity(
    extensionId: 'ext_garden_club',
    communityName: 'Garden Club',
    shippedSourceName:
        'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
    bundledAssetName:
        'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
  ),
  'masjid-nur-product-experience.md': _ProductCommunity(
    extensionId: 'ext_mosque',
    communityName: 'Masjid Nur',
    shippedSourceName:
        'Loom_Communities_Workflow_Engine_MasjidNur_Example.jsonc',
    bundledAssetName: 'Loom_Communities_Workflow_Engine_Mosque_Example.jsonc',
  ),
  'member-social-space-product-experience.md': _ProductCommunity(
    extensionId: 'ext_member_social_space',
    communityName: 'Member Social Space',
    shippedSourceName:
        'Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc',
    bundledAssetName:
        'Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc',
  ),
  'neighborhood-book-club-product-experience.md': _ProductCommunity(
    extensionId: 'ext_neighborhood_book_club',
    communityName: 'Neighborhood Book Club',
    shippedSourceName:
        'Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc',
    bundledAssetName: 'Loom_Communities_Workflow_Engine_BookClub_Example.jsonc',
  ),
  'riverside-youth-soccer-product-experience.md': _ProductCommunity(
    extensionId: 'ext_youth_soccer',
    communityName: 'Riverside Youth Soccer',
    shippedSourceName:
        'Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc',
    bundledAssetName:
        'Loom_Communities_Workflow_Engine_YouthSoccer_Example.jsonc',
  ),
};

// Exact named exclusions keep documentation structure from deciding product
// scope accidentally. Tabletop Club is the App Shell Phase 1 package-driven
// negative-control fixture (`ext_verify_tabletop_club`), as documented by
// examples/verify-tabletop-club/README.md; README.md is the directory guide.
const _nonProductMarkdownDocs = <String>{'README.md', 'tabletop-club.md'};
const _nonProductJsoncPackages = <String>{
  'Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc',
};

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory(
      '${directory.path}/docs/references/communities',
    ).existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError('Could not locate the repository root.');
}

Set<String> _fileNamesWithSuffix(Directory directory, String suffix) =>
    directory
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.endsWith(suffix))
        .toSet();

void main() {
  test('product docs, shipped packages, assets, harness, and catalog agree', () {
    final repositoryRoot = _repositoryRoot();
    final communityDocsDirectory = Directory(
      '${repositoryRoot.path}/docs/references/communities',
    );
    final assetDirectory = Directory(
      '${repositoryRoot.path}/app/packages/core/'
      'loom_communities_app_shell/assets',
    );

    expect(
      _fileNamesWithSuffix(communityDocsDirectory, '.md'),
      equals({..._productCommunitiesByDoc.keys, ..._nonProductMarkdownDocs}),
      reason:
          'Every community Markdown doc must be classified explicitly as a '
          'product community or a named non-product document.',
    );
    expect(
      _fileNamesWithSuffix(communityDocsDirectory, '.jsonc'),
      equals({
        for (final community in _productCommunitiesByDoc.values)
          community.shippedSourceName,
        ..._nonProductJsoncPackages,
      }),
      reason:
          'Every shipped community package must map to a product doc or be '
          'an explicitly named non-product fixture.',
    );

    final expectedExtensionIds = {
      for (final community in _productCommunitiesByDoc.values)
        community.extensionId,
    };
    final targetsByExtensionId = {
      for (final target in loomEvidenceTargets) target.extensionId: target,
    };
    expect(
      targetsByExtensionId.length,
      loomEvidenceTargets.length,
      reason: 'Evidence catalog extensionIds must be unique.',
    );
    expect(
      targetsByExtensionId.keys.toSet(),
      equals(expectedExtensionIds),
      reason:
          'The evidence catalog must contain exactly the product-community '
          'extensionIds declared by shipped packages.',
    );
    expect(
      shippedEvidencePackageExtensionIds,
      equals(expectedExtensionIds),
      reason:
          'The Android harness map must contain exactly the product-community '
          'extensionIds declared by shipped packages.',
    );

    final expectedAssetNames = {
      for (final community in _productCommunitiesByDoc.values)
        community.bundledAssetName,
    };
    expect(
      _fileNamesWithSuffix(assetDirectory, '.jsonc'),
      equals(expectedAssetNames),
      reason:
          'Bundled community JSONC assets must match the product-community '
          'mapping in both directions.',
    );

    final pubspec = File(
      '${repositoryRoot.path}/app/packages/core/'
      'loom_communities_app_shell/pubspec.yaml',
    ).readAsStringSync();
    final declaredJsoncAssets = RegExp(
      r'^\s+- assets/(.+\.jsonc)\s*$',
      multiLine: true,
    ).allMatches(pubspec).map((match) => match.group(1)!).toSet();
    expect(
      declaredJsoncAssets,
      equals(expectedAssetNames),
      reason:
          'pubspec.yaml must declare exactly the bundled product-community '
          'JSONC assets.',
    );

    for (final entry in _productCommunitiesByDoc.entries) {
      final community = entry.value;
      final shippedSource = File(
        '${communityDocsDirectory.path}/${community.shippedSourceName}',
      );
      final bundledAsset = File(
        '${assetDirectory.path}/${community.bundledAssetName}',
      );
      final decoded =
          jsonDecode(stripJsonComments(shippedSource.readAsStringSync()))
              as Map<String, dynamic>;
      expect(
        decoded['extensionId'],
        community.extensionId,
        reason:
            'Product doc ${entry.key} must map to the extensionId declared '
            'by its shipped package ${community.shippedSourceName}.',
      );
      expect(
        bundledAsset.readAsBytesSync(),
        orderedEquals(shippedSource.readAsBytesSync()),
        reason:
            'Bundled asset ${community.bundledAssetName} must remain '
            'byte-identical to ${community.shippedSourceName}.',
      );

      final target = targetsByExtensionId[community.extensionId]!;
      expect(target.communityName, community.communityName);
      final harnessLocation = shippedEvidencePackageLocationForExtensionId(
        community.extensionId,
      )!;
      expect(
        harnessLocation.repositoryPath,
        'docs/references/communities/${community.shippedSourceName}',
      );
      expect(
        harnessLocation.assetPath,
        'packages/loom_communities_app_shell/assets/'
        '${community.bundledAssetName}',
      );
    }
  });
}
