import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_ux_judges/b25_product_doc_interaction_models.dart';

void main() {
  test(
    'bundled B25 interaction rows are generated exactly from product docs',
    () {
      final repositoryRoot = locateB25RepositoryRoot();
      final expected = B25ProductDocInteractionCatalog.fromRepositoryRoot(
        repositoryRoot,
      ).toCanonicalAssetString();
      final asset = File(
        '${repositoryRoot.path}/$b25InteractionModelAssetRepositoryPath',
      );

      expect(asset.existsSync(), isTrue);
      expect(asset.readAsStringSync(), expected);
      expect(
        B25ProductDocInteractionCatalog.fromAssetJson(
          asset.readAsStringSync(),
        ).models,
        hasLength(79),
      );
    },
  );
}
