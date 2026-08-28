import 'dart:io';

import 'package:loom_ux_judges/src/community_package_provenance.dart';
import 'package:test/test.dart';

void main() {
  late Directory repositoryRoot;
  late File manifestFile;
  late CommunityPackageProvenanceManifest manifest;

  setUpAll(() {
    repositoryRoot = locateCommunityPackageRepositoryRoot();
    manifestFile = communityProvenanceManifestFile(repositoryRoot);
    manifest = CommunityPackageProvenanceManifest.fromFile(manifestFile);
  });

  test('every shipped community package has a provenance manifest entry', () {
    for (final packageFile in communityPackageFiles(repositoryRoot)) {
      final name = communityPackageFileName(packageFile);
      expect(
        manifest.packages.containsKey(name),
        isTrue,
        reason:
            'Community package provenance is missing $name. New community '
            'packages must be recorded in '
            '$communityProvenanceRelativePath; an unguarded package is not '
            'acceptable.',
      );
    }
  });

  test('every provenance manifest entry has a shipped community package', () {
    final packagesDirectory = communityPackagesDirectory(repositoryRoot);
    for (final name in manifest.packages.keys) {
      expect(
        File('${packagesDirectory.path}/$name').existsSync(),
        isTrue,
        reason:
            'Community package provenance contains $name, but the package is '
            'missing. Remove or regenerate the stale manifest entry '
            'deliberately.',
      );
    }
  });

  test('manifest hashes and byte counts match every community package', () {
    final packagesDirectory = communityPackagesDirectory(repositoryRoot);
    for (final entry in manifest.packages.entries) {
      final packageFile = File('${packagesDirectory.path}/${entry.key}');
      if (!packageFile.existsSync()) continue;

      final actualHash = communityPackageSha256(packageFile);
      final actualBytes = packageFile.lengthSync();
      final expected = entry.value;
      final message = _provenanceFailureMessage(
        packageName: entry.key,
        expectedHash: expected.sha256,
        actualHash: actualHash,
        expectedBytes: expected.bytes,
        actualBytes: actualBytes,
      );
      expect(actualHash, expected.sha256, reason: message);
      expect(actualBytes, expected.bytes, reason: message);
      expect(
        expected.authoredBy,
        communityPackageAuthoringSkill,
        reason: message,
      );
    }
  });

  test('updater rendering is byte-identical for the current manifest', () {
    final regenerated = regenerateCommunityPackageProvenance(
      repositoryRoot: repositoryRoot,
      existingManifest: manifest,
      // This test deliberately does not shell out to git. It verifies the
      // updater's rendering and hashing path against metadata already present
      // in the committed manifest, so it runs in history-less checkouts.
      commitMetadataFor: (packageFile) {
        final existing =
            manifest.packages[communityPackageFileName(packageFile)]!;
        return CommunityPackageCommitMetadata(
          commit: existing.lastCommit,
          date: existing.lastCommitDate,
          subject: existing.lastCommitSubject,
        );
      },
    );

    expect(
      renderCommunityPackageProvenance(regenerated),
      manifestFile.readAsStringSync(),
      reason:
          'The updater must be a no-op when package bytes and their metadata '
          'have not changed.',
    );
  });
}

String _provenanceFailureMessage({
  required String packageName,
  required String expectedHash,
  required String actualHash,
  required int expectedBytes,
  required int actualBytes,
}) =>
    '''
Community package provenance check failed for $packageName.

This file is authored only by the loom-calendar-experience-authoring Skill.
Expected SHA-256: $expectedHash
Actual SHA-256: $actualHash
Expected bytes: $expectedBytes
Actual bytes: $actualBytes

If you regenerated it through data/call_skill_authoring_agent.sh, run the updater below and commit the manifest in the same commit:
  dart run tool/update_community_provenance.dart

If you hand-edited it, that is the thing this test exists to catch.
''';
