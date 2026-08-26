import 'package:loom_ux_judges/community_remote_migration.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import 'plan.dart';

/// Pure conversion from already-parsed shipped packages to App Access's
/// community-installation request contract.
///
/// This class extracts derivation *inputs*. It must not derive permissions,
/// role grants, or group ids: App Access owns each of those operations.
class AppAccessProvisioningDeriver {
  const AppAccessProvisioningDeriver({
    this.archetypeResolver = const ArchetypeResolver(),
  });

  final ArchetypeResolver archetypeResolver;

  AppAccessProvisioningPlan deriveAll(
    Iterable<ParsedCommunityPackage> packages,
  ) {
    final entries = <CommunityInstallationPlanEntry>[];
    final communityIds = <String>{};

    for (final package in packages) {
      if (!communityIds.add(package.communityId)) {
        throw FormatException('Duplicate communityId ${package.communityId}.');
      }
      entries.add(_derivePackage(package));
    }
    if (entries.isEmpty) {
      throw const FormatException(
        'At least one community package is required.',
      );
    }
    return AppAccessProvisioningPlan(communities: List.unmodifiable(entries));
  }

  CommunityInstallationPlanEntry _derivePackage(
    ParsedCommunityPackage package,
  ) {
    final resolvedArchetypes = archetypeResolver.resolveAll(
      package.rawWorkflowDefinitions,
    );
    final workflows = <DerivedWorkflowInput>[];
    final omittedWorkflowTypes = <String>[];

    for (final definitionEntry in package.rawWorkflowDefinitions.entries) {
      final workflowType = definitionEntry.key;
      final rawDefinition = definitionEntry.value;
      if (rawDefinition is! Map) {
        throw FormatException(
          '$workflowType must be a workflow-definition object.',
        );
      }
      final definition = package.workflowDefinitions[workflowType];
      if (definition == null) {
        throw StateError('Parsed definition is missing $workflowType.');
      }
      final rawTransitions = rawDefinition['transitions'];
      if (rawTransitions is! List) {
        throw FormatException('$workflowType.transitions must be a list.');
      }
      if (rawTransitions.length != definition.transitions.length) {
        throw StateError(
          'Parsed transition count drifted for $workflowType: '
          '${rawTransitions.length} raw, ${definition.transitions.length} parsed.',
        );
      }

      final cardSurfaceFamily = resolvedArchetypes[workflowType]?.family;
      if (cardSurfaceFamily == null) {
        // permissions.md step 3d: a workflow with neither render bindings nor
        // a responseTable owner derives nothing. It must not cross the App
        // Access request boundary as a nullable workflow input.
        omittedWorkflowTypes.add(workflowType);
        continue;
      }

      final transitions = <DerivedTransitionInput>[];
      for (var index = 0; index < definition.transitions.length; index++) {
        final parsedTransition = definition.transitions[index];
        final rawTransition = rawTransitions[index];
        if (rawTransition is! Map) {
          throw FormatException(
            '$workflowType.transitions[$index] must be an object.',
          );
        }
        if (rawTransition['id'] != parsedTransition.id) {
          throw StateError(
            'Parsed transition order drifted for $workflowType at index $index.',
          );
        }
        final rawAction = rawTransition['action'];
        if (rawAction != null && (rawAction is! String || rawAction.isEmpty)) {
          throw FormatException(
            '$workflowType transition ${parsedTransition.id} action must be '
            'a non-empty string when declared.',
          );
        }
        final target = parsedTransition.to;
        transitions.add(
          DerivedTransitionInput(
            transitionId: parsedTransition.id,
            // Read the raw key so an action that is absent in the package is
            // also absent in the request rather than serialized as null.
            action: rawAction as String?,
            tone: parsedTransition.tone,
            isTerminal:
                target != null &&
                (definition.states[target]?.isTerminal ?? false),
            allowedRoleIds: List.unmodifiable(
              parsedTransition.guard.allowedRoleIds ?? const [],
            ),
          ),
        );
      }

      final createRoleIds = <String>{};
      for (final binding in definition.renderBindings) {
        for (final action in binding.actions) {
          if (action.kind == 'create') {
            createRoleIds.addAll(action.byRoleIds ?? const <String>[]);
          }
        }
      }

      workflows.add(
        DerivedWorkflowInput(
          workflowType: workflowType,
          cardSurfaceFamily: cardSurfaceFamily,
          createRoleIds: _sorted(createRoleIds),
          transitions: List.unmodifiable(transitions),
        ),
      );
    }

    return CommunityInstallationPlanEntry(
      communityId: package.communityId,
      omittedWorkflowTypes: List.unmodifiable(omittedWorkflowTypes),
      request: InstallCommunityPackageRequest(
        communityHandle: package.communityHandle,
        displayName: package.displayName,
        grammarVersion: package.specVersion,
        roles: List.unmodifiable([
          for (final role in package.roles)
            DerivedRoleInput(roleId: role.roleId, label: role.label),
        ]),
        workflows: List.unmodifiable(workflows),
      ),
    );
  }
}

List<String> _sorted(Iterable<String> values) =>
    values.toSet().toList()..sort();
