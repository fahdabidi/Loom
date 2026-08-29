import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';

/// A workflow package read directly from a shipped community asset.
///
/// [communityId] is intentionally read from the package body. Asset filenames
/// are presentation/provenance names and must never become database ids.
class CommunityWorkflowPackage {
  const CommunityWorkflowPackage({
    required this.file,
    required this.communityId,
    required this.specVersion,
    required this.workflowDefinitions,
  });

  final File file;
  final String communityId;
  final int specVersion;
  final Map<String, Map<String, dynamic>> workflowDefinitions;

  String get fileName => file.uri.pathSegments.last;
}

/// One package that could not be safely included in a publish run.
class CommunityWorkflowPackageError {
  const CommunityWorkflowPackageError({
    required this.fileName,
    required this.reason,
  });

  final String fileName;
  final String reason;
}

/// The complete result of reading an assets directory.
///
/// Errors are accumulated so a publisher can name every bad package rather
/// than silently skipping all but the first one. Callers must refuse to write
/// if [hasErrors] is true.
class CommunityWorkflowPackageReadResult {
  const CommunityWorkflowPackageReadResult({
    required this.packages,
    required this.errors,
  });

  final List<CommunityWorkflowPackage> packages;
  final List<CommunityWorkflowPackageError> errors;

  bool get hasErrors => errors.isNotEmpty;
}

/// Reads every shipped community JSONC package in [packagesDirectory].
///
/// This parser supports line and block comments because the app's shipped
/// package assets are JSONC. It deliberately validates the small contract the
/// publisher needs before a database connection is opened.
Future<CommunityWorkflowPackageReadResult> readCommunityWorkflowPackages(
  Directory packagesDirectory,
) async {
  final errors = <CommunityWorkflowPackageError>[];
  final packages = <CommunityWorkflowPackage>[];
  final files = <File>[];

  try {
    await for (final entity in packagesDirectory.list()) {
      if (entity is File && entity.path.endsWith('.jsonc')) {
        files.add(entity);
      }
    }
  } on FileSystemException catch (error) {
    errors.add(
      CommunityWorkflowPackageError(
        fileName: packagesDirectory.path,
        reason: 'could not list shipped community packages: ${error.message}',
      ),
    );
    return CommunityWorkflowPackageReadResult(
      packages: packages,
      errors: errors,
    );
  }

  files.sort((left, right) => left.path.compareTo(right.path));
  if (files.isEmpty) {
    errors.add(
      CommunityWorkflowPackageError(
        fileName: packagesDirectory.path,
        reason: 'contains no .jsonc community packages',
      ),
    );
  }

  for (final file in files) {
    try {
      packages.add(await _readPackage(file));
    } on Object catch (error) {
      errors.add(
        CommunityWorkflowPackageError(
          fileName: file.uri.pathSegments.last,
          reason: error.toString(),
        ),
      );
    }
  }

  final filesByCommunityId = <String, List<CommunityWorkflowPackage>>{};
  for (final package in packages) {
    filesByCommunityId.putIfAbsent(package.communityId, () => []).add(package);
  }
  for (final entry in filesByCommunityId.entries) {
    if (entry.value.length < 2) continue;
    final names = entry.value.map((package) => package.fileName).join(', ');
    for (final package in entry.value) {
      errors.add(
        CommunityWorkflowPackageError(
          fileName: package.fileName,
          reason:
              'communityId "${entry.key}" is also declared by $names; '
              'refusing to choose a definition source.',
        ),
      );
    }
  }

  return CommunityWorkflowPackageReadResult(packages: packages, errors: errors);
}

Future<CommunityWorkflowPackage> _readPackage(File file) async {
  final encoded = await file.readAsString();
  final Object? decoded;
  try {
    decoded = jsonDecode(_stripJsonComments(encoded));
  } on FormatException catch (error) {
    throw FormatException('invalid JSONC: ${error.message}');
  }
  if (decoded is! Map) {
    throw const FormatException('package root must be a JSON object.');
  }
  final root = Map<String, dynamic>.from(decoded);
  final communityId = root['communityId'];
  if (communityId is! String || communityId.trim().isEmpty) {
    throw const FormatException('communityId must be a non-empty string.');
  }
  final specVersion = root['specVersion'];
  if (specVersion is! int || specVersion < 1) {
    throw const FormatException('specVersion must be a positive integer.');
  }
  final experience = root['experience'];
  if (experience is! Map) {
    throw const FormatException('experience must be a JSON object.');
  }
  final definitions = experience['workflowDefinitions'];
  if (definitions is! Map || definitions.isEmpty) {
    throw const FormatException(
      'experience.workflowDefinitions must be a non-empty JSON object.',
    );
  }

  final workflowDefinitions = <String, Map<String, dynamic>>{};
  for (final entry in definitions.entries) {
    final workflowType = entry.key;
    if (workflowType is! String || workflowType.trim().isEmpty) {
      throw const FormatException(
        'workflow definition types must be non-empty strings.',
      );
    }
    if (entry.value is! Map) {
      throw FormatException('workflow "$workflowType" must be a JSON object.');
    }
    workflowDefinitions[workflowType] = Map<String, dynamic>.from(
      entry.value as Map,
    );
  }

  return CommunityWorkflowPackage(
    file: file,
    communityId: communityId,
    specVersion: specVersion,
    workflowDefinitions: workflowDefinitions,
  );
}

/// A planned upsert, including the exact reader-visible definition id.
class WorkflowDefinitionPublication {
  const WorkflowDefinitionPublication({
    required this.package,
    required this.workflowType,
    required this.definitionId,
    required this.definitionJson,
    required this.action,
  });

  final CommunityWorkflowPackage package;
  final String workflowType;
  final String definitionId;
  final String definitionJson;
  final WorkflowDefinitionPublicationAction action;
}

enum WorkflowDefinitionPublicationAction { insert, update }

/// Result of either a dry-run plan or a completed publish.
class WorkflowDefinitionPublishReport {
  const WorkflowDefinitionPublishReport({
    required this.publications,
    required this.wrote,
  });

  final List<WorkflowDefinitionPublication> publications;
  final bool wrote;

  int get communityCount => publications
      .map((publication) => publication.package.communityId)
      .toSet()
      .length;
}

/// Plans and, when explicitly requested, upserts shipped definitions.
///
/// A run always reports every exact id and whether it already exists before
/// issuing any upsert. A write run uses only [WorkflowDatabase.upsertDefinition]
/// and verifies the store's community loader can read every workflow back.
class WorkflowDefinitionPublisher {
  WorkflowDefinitionPublisher({
    required WorkflowDatabase database,
    void Function(String line)? report,
  }) : _database = database,
       _report = report ?? print;

  final WorkflowDatabase _database;
  final void Function(String line) _report;

  Future<WorkflowDefinitionPublishReport> publish(
    Iterable<CommunityWorkflowPackage> sourcePackages, {
    bool write = false,
  }) async {
    final packages = sourcePackages.toList()
      ..sort((left, right) => left.communityId.compareTo(right.communityId));
    final publications = <WorkflowDefinitionPublication>[];

    for (final package in packages) {
      final workflowTypes = package.workflowDefinitions.keys.toList()..sort();
      for (final workflowType in workflowTypes) {
        final definitionId = '${package.communityId}_$workflowType';
        final stored = await _database.loadDefinitionJson(definitionId);
        publications.add(
          WorkflowDefinitionPublication(
            package: package,
            workflowType: workflowType,
            definitionId: definitionId,
            definitionJson: jsonEncode(
              package.workflowDefinitions[workflowType],
            ),
            action: stored == null
                ? WorkflowDefinitionPublicationAction.insert
                : WorkflowDefinitionPublicationAction.update,
          ),
        );
      }
    }

    _report(
      'Found ${packages.length} communities and ${publications.length} workflows.',
    );
    for (final package in packages) {
      _report(
        '${package.fileName}: community=${package.communityId}, '
        'workflows=${package.workflowDefinitions.length}.',
      );
    }
    final prefix = write ? 'WRITE PLAN' : 'DRY RUN';
    for (final publication in publications) {
      _report(
        '$prefix: ${publication.package.communityId} '
        '${publication.workflowType} ${publication.definitionId} '
        '${publication.action.name}.',
      );
    }

    if (!write) {
      _report(
        'Dry run complete: ${publications.length} definitions would be '
        'upserted; no definitions were written. Re-run with --write to publish.',
      );
      return WorkflowDefinitionPublishReport(
        publications: publications,
        wrote: false,
      );
    }

    await _database.transaction(() async {
      for (final publication in publications) {
        await _database.upsertDefinition(
          definitionId: publication.definitionId,
          workflowType: publication.workflowType,
          definitionJson: publication.definitionJson,
          version: publication.package.specVersion,
        );
      }
    });

    for (final package in packages) {
      final loaded = await _database.loadDefinitionsForCommunity(
        package.communityId,
      );
      final missing = package.workflowDefinitions.keys
          .where((workflowType) => !loaded.containsKey(workflowType))
          .toList();
      if (missing.isNotEmpty) {
        throw StateError(
          'Published ${package.fileName}, but '
          'loadDefinitionsForCommunity(${package.communityId}) did not return '
          '${missing.join(', ')}.',
        );
      }
      _report(
        'Verified ${package.communityId}: '
        '${package.workflowDefinitions.length}/${package.workflowDefinitions.length} '
        'declared workflows load by community id.',
      );
    }
    _report(
      'Publish complete: ${publications.length} definitions upserted for '
      '${packages.length} communities.',
    );
    return WorkflowDefinitionPublishReport(
      publications: publications,
      wrote: true,
    );
  }
}

/// Locates the single asset directory the Communities app declares as shipped.
///
/// The search walks only toward the repository root and fails loudly when it
/// cannot find that fixed repository-relative path.
Directory locateShippedCommunityPackagesDirectory(Directory startingDirectory) {
  var candidateRoot = startingDirectory.absolute;
  while (true) {
    final assets = Directory(
      '${candidateRoot.path}/app/packages/core/'
      'loom_communities_app_shell/assets',
    );
    if (assets.existsSync()) return assets;
    final parent = candidateRoot.parent;
    if (parent.path == candidateRoot.path) break;
    candidateRoot = parent;
  }
  throw StateError(
    'Could not locate app/packages/core/loom_communities_app_shell/assets '
    'from ${startingDirectory.path}.',
  );
}

/// Removes JSONC comments without touching string values such as https URLs.
String _stripJsonComments(String content) {
  final buffer = StringBuffer();
  var index = 0;
  var inString = false;

  while (index < content.length) {
    if (inString && content[index] == '\\' && index + 1 < content.length) {
      buffer.write(content[index]);
      index++;
      buffer.write(content[index]);
      index++;
      continue;
    }
    if (content[index] == '"') {
      inString = !inString;
      buffer.write(content[index]);
      index++;
      continue;
    }
    if (!inString &&
        index + 1 < content.length &&
        content[index] == '/' &&
        content[index + 1] == '/') {
      index += 2;
      while (index < content.length && content[index] != '\n') {
        index++;
      }
      continue;
    }
    if (!inString &&
        index + 1 < content.length &&
        content[index] == '/' &&
        content[index + 1] == '*') {
      index += 2;
      var terminated = false;
      while (index + 1 < content.length) {
        if (content[index] == '*' && content[index + 1] == '/') {
          index += 2;
          terminated = true;
          break;
        }
        if (content[index] == '\n') buffer.write('\n');
        index++;
      }
      if (!terminated) {
        throw const FormatException('unterminated block comment.');
      }
      continue;
    }
    buffer.write(content[index]);
    index++;
  }
  return buffer.toString();
}
