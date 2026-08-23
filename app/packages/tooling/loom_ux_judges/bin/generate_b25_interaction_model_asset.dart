import 'dart:io';

import 'package:loom_ux_judges/b25_product_doc_interaction_models.dart';

void main(List<String> args) {
  final repoRootArg = _argValue(args, '--repo-root');
  final repositoryRoot = repoRootArg == null
      ? locateB25RepositoryRoot()
      : Directory(repoRootArg).absolute;
  final output = generateB25InteractionModelAsset(
    repositoryRoot: repositoryRoot,
  );
  final catalog = B25ProductDocInteractionCatalog.fromRepositoryRoot(
    repositoryRoot,
  );
  stdout.writeln(
    'generate_b25_interaction_model_asset: wrote '
    '${catalog.models.length} product-doc rows to ${output.path}',
  );
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
