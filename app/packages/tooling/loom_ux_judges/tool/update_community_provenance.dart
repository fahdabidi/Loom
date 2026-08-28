import 'dart:io';

import 'package:loom_ux_judges/src/community_package_provenance.dart';

void main() {
  final repositoryRoot = locateCommunityPackageRepositoryRoot();
  final manifestFile = communityProvenanceManifestFile(repositoryRoot);
  final existingManifest = CommunityPackageProvenanceManifest.fromFile(
    manifestFile,
  );
  final regenerated = regenerateCommunityPackageProvenance(
    repositoryRoot: repositoryRoot,
    existingManifest: existingManifest,
    commitMetadataFor: (packageFile) =>
        _lastCommitFor(repositoryRoot, packageFile),
  );
  final rendered = renderCommunityPackageProvenance(regenerated);
  final current = manifestFile.readAsStringSync();

  if (current == rendered) {
    stdout.writeln(
      'Community provenance manifest is already up to date '
      '(${regenerated.packages.length} packages).',
    );
    return;
  }

  manifestFile.writeAsStringSync(rendered);
  stdout.writeln(
    'Updated ${communityProvenanceRelativePath} '
    '(${regenerated.packages.length} packages).',
  );
}

CommunityPackageCommitMetadata _lastCommitFor(
  Directory repositoryRoot,
  File packageFile,
) {
  final relativePath =
      '$communityPackagesRelativePath/${communityPackageFileName(packageFile)}';
  final result = Process.runSync('git', <String>[
    'log',
    '-1',
    '--format=%h|%ad|%s',
    '--date=short',
    '--',
    relativePath,
  ], workingDirectory: repositoryRoot.path);
  if (result.exitCode != 0) {
    throw StateError(
      'Could not read the last commit for $relativePath: ${result.stderr}',
    );
  }
  final output = (result.stdout as String).trimRight();
  final parts = output.split('|');
  if (parts.length < 3 || parts.any((part) => part.isEmpty)) {
    throw StateError(
      'Git returned no usable last-commit metadata for $relativePath.',
    );
  }
  return CommunityPackageCommitMetadata(
    commit: parts[0],
    date: parts[1],
    subject: _first100Characters(parts.sublist(2).join('|')),
  );
}

String _first100Characters(String value) =>
    String.fromCharCodes(value.runes.take(100));
