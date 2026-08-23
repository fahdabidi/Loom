import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _bundledAssetToShippedSource = <String, String>{
  'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc':
      'Loom_Communities_Workflow_Engine_GardenClub_Example.jsonc',
  'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc':
      'Loom_Communities_Workflow_Engine_CameraClub_Example.jsonc',
  'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc':
      'Loom_Communities_Workflow_Engine_ChessClub_Example.jsonc',
  'Loom_Communities_Workflow_Engine_Mosque_Example.jsonc':
      'Loom_Communities_Workflow_Engine_MasjidNur_Example.jsonc',
  'Loom_Communities_Workflow_Engine_YouthSoccer_Example.jsonc':
      'Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc',
  'Loom_Communities_Workflow_Engine_BookClub_Example.jsonc':
      'Loom_Communities_Workflow_Engine_NeighborhoodBookClub_Example.jsonc',
  'Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc':
      'Loom_Communities_Workflow_Engine_AdFreeCommunity_Example.jsonc',
  'Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc':
      'Loom_Communities_Workflow_Engine_CedarCommonsHOA_Example.jsonc',
  'Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc':
      'Loom_Communities_Workflow_Engine_DataPortabilityCommunity_Example.jsonc',
  'Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc':
      'Loom_Communities_Workflow_Engine_MemberSocialSpace_Example.jsonc',
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

void main() {
  test(
    'every bundled community asset is byte-identical to its shipped source',
    () {
      final repositoryRoot = _repositoryRoot();
      final assetDirectory = Directory(
        '${repositoryRoot.path}/app/packages/core/'
        'loom_communities_app_shell/assets',
      );
      final bundledAssetNames = assetDirectory
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.endsWith('.jsonc'))
          .toSet();

      expect(
        bundledAssetNames,
        equals(_bundledAssetToShippedSource.keys.toSet()),
        reason:
            'Every bundled JSONC asset must have an explicit shipped-source '
            'mapping in this conformance test.',
      );

      for (final mapping in _bundledAssetToShippedSource.entries) {
        final bundledAsset = File('${assetDirectory.path}/${mapping.key}');
        final shippedSource = File(
          '${repositoryRoot.path}/docs/references/communities/${mapping.value}',
        );
        expect(
          bundledAsset.readAsBytesSync(),
          orderedEquals(shippedSource.readAsBytesSync()),
          reason:
              'Bundled asset ${mapping.key} has drifted from shipped source '
              '${mapping.value}. Copy the shipped source byte-for-byte.',
        );
      }
    },
  );
}
