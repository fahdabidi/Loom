import 'dart:convert';
import 'dart:io';

import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import '../validator/jsonc.dart';

typedef JsonObject = Map<String, dynamic>;

/// A VM-safe parse of the engine-native portion of a shipped community.
///
/// The Flutter app shell's `LoomExperienceDefinition` parser delegates each
/// workflow to [LoomWorkflowStateMachine.fromJson]. A console tool cannot
/// import the shell wrapper because it imports `dart:ui`, so this parser calls
/// that same existing workflow parser directly and retains the raw experience
/// map for fields that must pass through without a lossy model round-trip.
class ParsedCommunityPackage {
  ParsedCommunityPackage._({
    required this.sourcePath,
    required this.root,
    required this.experience,
    required this.communityId,
    required this.communityHandle,
    required this.displayName,
    required this.extensionId,
    required this.specVersion,
    required this.roles,
    required this.rawWorkflowDefinitions,
    required this.workflowDefinitions,
  });

  final String sourcePath;
  final JsonObject root;
  final JsonObject experience;
  final String communityId;
  final String communityHandle;
  final String displayName;
  final String extensionId;
  final int specVersion;
  final List<MigrationRole> roles;
  final Map<String, Object?> rawWorkflowDefinitions;
  final Map<String, LoomWorkflowStateMachine> workflowDefinitions;

  static Future<ParsedCommunityPackage> fromFile(File file) async {
    if (!await file.exists()) {
      throw FormatException('Community file does not exist: ${file.path}');
    }
    return parse(await file.readAsString(), sourcePath: file.path);
  }

  static ParsedCommunityPackage parse(
    String source, {
    String sourcePath = '<memory>',
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(stripJsonComments(source));
    } on FormatException catch (error) {
      throw FormatException('Invalid community JSONC: ${error.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The community package must be an object.');
    }

    final specVersion = decoded['specVersion'];
    if (specVersion is! int) {
      throw const FormatException(
        'Packages must declare specVersion: $currentCommunitySpecVersion. '
        'Pre-v4 packages are unsupported. See '
        'docs/references/reference/identity-types.md.',
      );
    }
    if (specVersion != currentCommunitySpecVersion) {
      throw FormatException(
        'Unsupported specVersion "$specVersion". Packages must declare '
        'specVersion: $currentCommunitySpecVersion. See '
        'docs/references/reference/identity-types.md.',
      );
    }

    final experience = _requiredObject(decoded, 'experience');
    final rawDefinitionsObject = _requiredObject(
      experience,
      'workflowDefinitions',
    );
    if (rawDefinitionsObject.isEmpty) {
      throw const FormatException(
        'experience.workflowDefinitions must not be empty.',
      );
    }

    final rawDefinitions = <String, Object?>{};
    final parsedDefinitions = <String, LoomWorkflowStateMachine>{};
    for (final entry in rawDefinitionsObject.entries) {
      if (entry.value is! Map) {
        throw FormatException(
          'experience.workflowDefinitions.${entry.key} must be an object.',
        );
      }
      final rawDefinition = Map<String, dynamic>.from(entry.value as Map);
      rawDefinitions[entry.key] = rawDefinition;
      parsedDefinitions[entry.key] = LoomWorkflowStateMachine.fromJson(
        rawDefinition,
        entry.key,
      );
    }

    final rawRoles = experience['roles'];
    if (rawRoles is! List || rawRoles.isEmpty) {
      throw const FormatException('experience.roles must not be empty.');
    }
    const rolesPath = 'experience.roles';
    final roles = <MigrationRole>[];
    for (var index = 0; index < rawRoles.length; index++) {
      final raw = rawRoles[index];
      if (raw is! Map) {
        throw FormatException('$rolesPath[$index] must be an object.');
      }
      final role = Map<String, dynamic>.from(raw);
      roles.add(
        MigrationRole(
          roleId: _requiredString(
            role,
            'roleId',
            prefix: '$rolesPath[$index].',
          ),
          label: _requiredString(role, 'label', prefix: '$rolesPath[$index].'),
          roleLabel: _requiredString(
            role,
            'roleLabel',
            prefix: '$rolesPath[$index].',
          ),
        ),
      );
    }

    return ParsedCommunityPackage._(
      sourcePath: sourcePath,
      root: decoded,
      experience: experience,
      communityId: _requiredString(decoded, 'communityId'),
      communityHandle: _requiredString(decoded, 'communityHandle'),
      displayName: _requiredString(decoded, 'displayName'),
      extensionId: _requiredString(decoded, 'extensionId'),
      specVersion: specVersion,
      roles: List.unmodifiable(roles),
      rawWorkflowDefinitions: Map.unmodifiable(rawDefinitions),
      workflowDefinitions: Map.unmodifiable(parsedDefinitions),
    );
  }
}

class MigrationRole {
  const MigrationRole({
    required this.roleId,
    required this.label,
    required this.roleLabel,
  });

  final String roleId;
  final String label;
  final String roleLabel;
}

JsonObject _requiredObject(JsonObject object, String key) {
  final value = object[key];
  if (value is! Map) {
    throw FormatException('$key must be an object.');
  }
  return Map<String, dynamic>.from(value);
}

String _requiredString(JsonObject object, String key, {String prefix = ''}) {
  final value = object[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$prefix$key must be a non-empty string.');
  }
  return value.trim();
}
