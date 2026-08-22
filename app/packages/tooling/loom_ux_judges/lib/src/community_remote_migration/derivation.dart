import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'package_parser.dart';

typedef JsonMap = Map<String, Object?>;

/// Deterministic output of the community-to-remote derivation.
class CommunityMigrationPlan {
  const CommunityMigrationPlan({
    required this.installCommunityPackagePayload,
    required this.replaceWorkflowDefinitionsPayload,
  });

  final JsonMap installCommunityPackagePayload;
  final JsonMap replaceWorkflowDefinitionsPayload;
  List<Object> get findings => const [];

  int get cleanGuardCount => 0;
  int get flaggedGuardCount => 0;
  int get cleanCreateActionCount => 0;
  int get flaggedCreateActionCount => 0;

  JsonMap findingsReport({required int networkCallsMade}) => {
    'summary': {
      'guardsTranslatedCleanly': cleanGuardCount,
      'guardsFlagged': flaggedGuardCount,
      'createActionsTranslatedCleanly': cleanCreateActionCount,
      'createActionsFlagged': flaggedCreateActionCount,
      'networkCallsMade': networkCallsMade,
    },
    'findings': const <Object>[],
  };
}

class CommunityMigrationDeriver {
  const CommunityMigrationDeriver({
    this.archetypeResolver = const ArchetypeResolver(),
  });

  final ArchetypeResolver archetypeResolver;

  CommunityMigrationPlan derive(ParsedCommunityPackage package) {
    final resolvedArchetypes = archetypeResolver.resolveAll(
      package.rawWorkflowDefinitions,
    );
    final workflows = <JsonMap>[];

    for (final entry in package.workflowDefinitions.entries) {
      final workflowType = entry.key;
      final definition = entry.value;
      final rawDefinition = package.rawWorkflowDefinitions[workflowType] as Map;
      final rawTransitions = rawDefinition['transitions'] as List;

      final transitions = <JsonMap>[];
      for (var index = 0; index < definition.transitions.length; index++) {
        final transition = definition.transitions[index];
        final rawTransition = Map<String, dynamic>.from(
          rawTransitions[index] as Map,
        );
        if (rawTransition['id'] != transition.id) {
          throw StateError(
            'Parsed transition order drifted for $workflowType at index $index.',
          );
        }
        final transitionPath = _listItemPath(
          r'$.experience.workflowDefinitions.'
          '$workflowType.transitions',
          index,
          rawTransition,
        );
        final derived = <String, Object?>{
          'transitionId': transition.id,
          'action': transition.action,
          'tone': transition.tone,
          'isTerminal':
              transition.to != null &&
              (definition.states[transition.to]?.isTerminal ?? false),
        };

        final rawGuard = rawTransition['guard'];
        if (rawGuard is Map && rawGuard.containsKey('allowedRoleIds')) {
          derived['allowedRoleIds'] = _stringList(
            rawGuard['allowedRoleIds'],
            '$transitionPath.guard.allowedRoleIds',
          );
        } else {
          // App Access explicitly defines an empty list as an instance-gated
          // transition that derives no role grant.
          derived['allowedRoleIds'] = const <String>[];
        }
        transitions.add(derived);
      }

      final createRoleIds = <String>{};
      for (
        var bindingIndex = 0;
        bindingIndex < definition.renderBindings.length;
        bindingIndex++
      ) {
        final binding = definition.renderBindings[bindingIndex];
        for (
          var actionIndex = 0;
          actionIndex < binding.actions.length;
          actionIndex++
        ) {
          final action = binding.actions[actionIndex];
          if (action.kind != 'create') continue;
          createRoleIds.addAll(action.byRoleIds ?? const <String>[]);
        }
      }

      workflows.add({
        'workflowType': workflowType,
        'cardSurfaceFamily': resolvedArchetypes[workflowType]?.family,
        'transitions': transitions,
        'createRoleIds': createRoleIds.toList()..sort(),
      });
    }

    return CommunityMigrationPlan(
      installCommunityPackagePayload: {
        'communityHandle': package.communityHandle,
        'displayName': package.displayName,
        'grammarVersion': package.specVersion,
        'roles': [
          for (final role in package.personas)
            {'roleId': role.roleId, 'label': role.roleLabel},
        ],
        'workflows': workflows,
      },
      replaceWorkflowDefinitionsPayload: {
        'specVersion': currentCommunitySpecVersion,
        'definitions': package.rawWorkflowDefinitions,
      },
    );
  }
}

String _listItemPath(String path, int index, Object? item) {
  if (path.endsWith('.transitions') && item is Map) {
    final id = item['id'];
    if (id is String && id.isNotEmpty) return '$path[id=$id]';
  }
  return '$path[$index]';
}

List<String> _stringList(Object? value, String location) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$location must be a list of strings.');
  }
  return List.unmodifiable(value.cast<String>());
}
