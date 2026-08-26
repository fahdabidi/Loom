import 'dart:io';

import 'package:loom_ux_judges/community_remote_migration.dart';

/// Loads the shipped JSONC packages through the existing, engine-validating
/// community package parser. File ordering is fixed for reproducible plans.
class ShippedCommunityPackageLoader {
  const ShippedCommunityPackageLoader();

  Future<List<ParsedCommunityPackage>> loadDirectory(
    Directory directory,
  ) async {
    if (!await directory.exists()) {
      throw FormatException(
        'Community package directory does not exist: ${directory.path}',
      );
    }
    final files = <File>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File && entity.path.endsWith('.jsonc')) files.add(entity);
    }
    files.sort((left, right) => left.path.compareTo(right.path));
    if (files.isEmpty) {
      throw FormatException('No .jsonc packages found in ${directory.path}.');
    }
    return List.unmodifiable(
      await Future.wait(files.map(ParsedCommunityPackage.fromFile)),
    );
  }
}
