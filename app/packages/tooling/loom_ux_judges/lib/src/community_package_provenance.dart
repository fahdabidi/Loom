import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const communityPackagesRelativePath = 'docs/references/communities';
const communityProvenanceRelativePath =
    'docs/references/_meta/community-provenance.json';
const communityPackageAuthoringSkill = 'loom-calendar-experience-authoring';

/// Finds the repository by walking upward from the current directory, matching
/// the path-resolution convention already used by the judges' corpus tests.
Directory locateCommunityPackageRepositoryRoot({Directory? start}) {
  var directory = start ?? Directory.current;
  for (var depth = 0; depth < 8; depth++) {
    if (Directory(
      '${directory.path}/$communityPackagesRelativePath',
    ).existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError(
    'Could not locate the repository root containing '
    '$communityPackagesRelativePath from ${Directory.current.path}.',
  );
}

Directory communityPackagesDirectory(Directory repositoryRoot) =>
    Directory('${repositoryRoot.path}/$communityPackagesRelativePath');

File communityProvenanceManifestFile(Directory repositoryRoot) =>
    File('${repositoryRoot.path}/$communityProvenanceRelativePath');

List<File> communityPackageFiles(Directory repositoryRoot) {
  final files =
      communityPackagesDirectory(repositoryRoot)
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.jsonc'))
          .toList()
        ..sort(
          (left, right) => communityPackageFileName(
            left,
          ).compareTo(communityPackageFileName(right)),
        );
  return files;
}

String communityPackageFileName(File file) => file.uri.pathSegments.last;

String communityPackageSha256(File file) =>
    sha256.convert(file.readAsBytesSync()).toString();

final class CommunityPackageCommitMetadata {
  const CommunityPackageCommitMetadata({
    required this.commit,
    required this.date,
    required this.subject,
  });

  final String commit;
  final String date;
  final String subject;
}

final class CommunityPackageProvenanceEntry {
  const CommunityPackageProvenanceEntry({
    required this.sha256,
    required this.bytes,
    required this.authoredBy,
    required this.lastCommit,
    required this.lastCommitDate,
    required this.lastCommitSubject,
  });

  factory CommunityPackageProvenanceEntry.fromJson(Map<String, dynamic> json) =>
      CommunityPackageProvenanceEntry(
        sha256: json['sha256'] as String,
        bytes: json['bytes'] as int,
        authoredBy: json['authoredBy'] as String,
        lastCommit: json['lastCommit'] as String,
        lastCommitDate: json['lastCommitDate'] as String,
        lastCommitSubject: json['lastCommitSubject'] as String,
      );

  final String sha256;
  final int bytes;
  final String authoredBy;
  final String lastCommit;
  final String lastCommitDate;
  final String lastCommitSubject;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sha256': sha256,
    'bytes': bytes,
    'authoredBy': authoredBy,
    'lastCommit': lastCommit,
    'lastCommitDate': lastCommitDate,
    'lastCommitSubject': lastCommitSubject,
  };
}

final class CommunityPackageProvenanceManifest {
  const CommunityPackageProvenanceManifest({
    required this.comment,
    required this.algorithm,
    required this.packages,
  });

  factory CommunityPackageProvenanceManifest.fromJson(
    Map<String, dynamic> json,
  ) {
    final packagesJson = json['packages'] as Map<String, dynamic>;
    return CommunityPackageProvenanceManifest(
      comment: (json[r'$comment'] as List<dynamic>).cast<String>(),
      algorithm: json['algorithm'] as String,
      packages: <String, CommunityPackageProvenanceEntry>{
        for (final entry in packagesJson.entries)
          entry.key: CommunityPackageProvenanceEntry.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
    );
  }

  factory CommunityPackageProvenanceManifest.fromFile(File file) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return CommunityPackageProvenanceManifest.fromJson(json);
  }

  final List<String> comment;
  final String algorithm;
  final Map<String, CommunityPackageProvenanceEntry> packages;

  Map<String, dynamic> toJson() => <String, dynamic>{
    r'$comment': comment,
    'algorithm': algorithm,
    'packages': <String, dynamic>{
      for (final entry in packages.entries) entry.key: entry.value.toJson(),
    },
  };
}

CommunityPackageProvenanceManifest regenerateCommunityPackageProvenance({
  required Directory repositoryRoot,
  required CommunityPackageProvenanceManifest existingManifest,
  required CommunityPackageCommitMetadata Function(File packageFile)
  commitMetadataFor,
}) {
  final packages = <String, CommunityPackageProvenanceEntry>{};
  for (final packageFile in communityPackageFiles(repositoryRoot)) {
    final metadata = commitMetadataFor(packageFile);
    packages[communityPackageFileName(
      packageFile,
    )] = CommunityPackageProvenanceEntry(
      sha256: communityPackageSha256(packageFile),
      bytes: packageFile.lengthSync(),
      authoredBy: communityPackageAuthoringSkill,
      lastCommit: metadata.commit,
      lastCommitDate: metadata.date,
      lastCommitSubject: metadata.subject,
    );
  }
  return CommunityPackageProvenanceManifest(
    comment: existingManifest.comment,
    algorithm: existingManifest.algorithm,
    packages: packages,
  );
}

String renderCommunityPackageProvenance(
  CommunityPackageProvenanceManifest manifest,
) => const JsonEncoder.withIndent('  ').convert(manifest.toJson()) + '\n';
