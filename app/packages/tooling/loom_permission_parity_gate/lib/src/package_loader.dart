import 'dart:io';

import 'package:loom_ux_judges/community_remote_migration.dart';

/// Loads the shipped JSONC packages through the same engine-validating parser
/// `check_role_parity.sh`'s deriver uses, with a fixed file order so a run is
/// reproducible.
///
/// Re-exported through this package so the gate has one import for its
/// corpus, rather than reaching into the provisioning tool's internals.
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

  /// Loads one explicitly named package file.
  ///
  /// Exists so the negative test can point the gate at a **disposable** probe
  /// package -- a throwaway community handle, installed, deliberately
  /// corrupted, verified caught, then deleted -- without putting that probe
  /// into the shipped assets directory, where it would become part of the real
  /// corpus and the gate would then be checking a fixture against itself.
  Future<ParsedCommunityPackage> loadFile(File file) async {
    if (!await file.exists()) {
      throw FormatException('Community package file does not exist: '
          '${file.path}');
    }
    return ParsedCommunityPackage.fromFile(file);
  }
}
