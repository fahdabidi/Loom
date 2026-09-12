import '../archetypes/archetype_resolver.dart';
import '../models/workflow_models.dart';

/// Node-aware permission analysis over a community package plus the
/// permission-id set each role derives to.
///
/// **This file analyzes. It never grants.** `role_permission(app_id, role_id,
/// permission_id)` is the only grant table -- there is no per-fan and no
/// per-instance grant -- so a permission attached to a workflow node would
/// land on the *role*, widening authorization for every holder and every
/// instance in the community permanently. The derivation App Access performs
/// at install time already produces the union of every permission a
/// just-in-time engine could need; node awareness belongs here, in the
/// analysis and the runtime report, and nowhere in granting.
///
/// What this adds over a flat permission-set diff: the same derivation is
/// grouped **by workflow state**, so a gap reads as
///
///   portability-member cannot leave `failed` on `export-import-replay`:
///   progressing requires `export_wizard.cancel`, which it does not hold.
///
/// rather than "this role is missing these two ids".
///
/// The permission ids are **not** recomputed here. They arrive from the
/// caller as the export's already-derived sets, so there is exactly one
/// implementation of the derivation rules and this cannot drift from it.

/// Where an action's permission id came from, mirroring the export's
/// `grants[].sourceKind`.
enum ProgressPermissionSource {
  /// A transition guarded on the role, producing `<family>.<action>`.
  transition,

  /// A `create` action on a render binding, producing `<family>.create`.
  createAction,

  /// The fixed `community.*` governance set held by `<handle>-admin`.
  ///
  /// Never a reason a role is stuck: governance permissions are not attached
  /// to any workflow state.
  governance,
}

/// One permission a workflow action requires, and the action that requires it.
class RequiredActionPermission {
  const RequiredActionPermission({
    required this.permissionId,
    required this.sourceActionId,
    required this.source,
  });

  final String permissionId;

  /// The transition id, or the create-action id, that needs [permissionId].
  final String? sourceActionId;
  final ProgressPermissionSource source;
}

/// One way out of a state, for the roles permitted to take it.
class StateTransitionRequirement {
  const StateTransitionRequirement({
    required this.transitionId,
    required this.label,
    required this.toState,
    required this.allowedRoleIds,
    required this.permissions,
    required this.guardSummary,
  });

  final String transitionId;
  final String label;

  /// Null for an orthogonal-lifecycle transition that changes data without
  /// leaving the state.
  final String? toState;

  /// The roles the package's guard permits to fire this transition.
  ///
  /// Empty means the transition is guarded on instance data alone
  /// (`actorEqualsField`, `actorInList`, a formula) and derives no role grant.
  /// That is a real, common shape -- 243 occurrences across the fixtures --
  /// and it is **not** the same as "nobody may fire it".
  final List<String> allowedRoleIds;

  final List<RequiredActionPermission> permissions;

  /// Human-readable naming of the guard conditions that are *not* role-based,
  /// so the runtime report can say which engine guard blocked a caller who
  /// already holds the permission.
  final List<String> guardSummary;
}

/// Everything one workflow state owns, grouped by the state a caller is in.
class WorkflowStateNode {
  const WorkflowStateNode({
    required this.workflowType,
    required this.state,
    required this.label,
    required this.isTerminal,
    required this.transitions,
    required this.readRoleIds,
  });

  final String workflowType;
  final String state;
  final String label;
  final bool isTerminal;

  /// The ways out of this state, as declared.
  final List<StateTransitionRequirement> transitions;

  /// Roles the state's own `readGuard` admits, when it declares one.
  ///
  /// A role that may read a state and take nothing out of it is the
  /// read-only-by-design shape, and it is legitimate rather than a finding.
  final List<String> readRoleIds;
}

/// One role that cannot leave one state, and why.
class StuckRoleFinding {
  const StuckRoleFinding({
    required this.roleId,
    required this.workflowType,
    required this.state,
    required this.stateLabel,
    required this.blockedTransitions,
    required this.missingPermissionIds,
  });

  final String roleId;
  final String workflowType;
  final String state;
  final String stateLabel;

  /// Transitions this role is permitted by the package to fire from [state].
  final List<String> blockedTransitions;

  /// The permission ids those transitions require and the role does not hold.
  final List<String> missingPermissionIds;

  /// The sentence the ticket asks a gap to read as.
  String get sentence {
    // `blockedTransitions.single` must be applied to the list, not to the
    // interpolated list -- `'$blockedTransitions.single'` interpolates the
    // whole list first and then reads `.single` on the resulting String,
    // which rendered as `[cancel-full-bundle-error].single`.
    final single = blockedTransitions.length == 1
        ? blockedTransitions.single
        : null;
    final action = single != null
        ? 'transition `$single`'
        : 'transitions ${blockedTransitions.map((id) => '`$id`').join(', ')}';
    final permissions = missingPermissionIds
        .map((id) => '`$id`')
        .join(', ');
    return '$roleId cannot leave `$state` on `$workflowType`: '
        'progressing requires $action, which requires $permissions, '
        'which it does not hold.';
  }

  @override
  String toString() => sentence;
}

/// The node-grouped derivation for one community package.
class CommunityPermissionProgressReport {
  CommunityPermissionProgressReport({
    required this.communityHandle,
    required this.groupId,
    required this.workflowNodes,
    required this.stuckRoleFindings,
    required this.unprocessedWorkflowTypes,
  });

  final String communityHandle;
  final String groupId;

  /// `workflowType` -> `state` -> node, for every state of every workflow the
  /// package declares.
  final Map<String, Map<String, WorkflowStateNode>> workflowNodes;

  final List<StuckRoleFinding> stuckRoleFindings;

  /// Workflows that derive no permission at all (permissions.md step 3d) and
  /// are therefore not part of the analysis.
  ///
  /// Printed rather than dropped: a silently skipped workflow hides exactly
  /// the case that would disprove the analysis.
  final List<String> unprocessedWorkflowTypes;
}

/// Groups a package's already-derived permission sets by workflow state.
///
/// [derivedPermissionIdsByRole] is the permission truth: what App Access
/// derived for each role, keyed by role id. The analysis never recomputes it.
class CommunityPermissionProgressAnalyzer {
  const CommunityPermissionProgressAnalyzer({
    required this.archetypeResolver,
  });

  const CommunityPermissionProgressAnalyzer.defaults()
    : archetypeResolver = const ArchetypeResolver();

  final ArchetypeResolver archetypeResolver;

  /// Builds the node-grouped report.
  ///
  /// [roleIds] is the union of roles the package declares, so a role that
  /// derives nothing still appears in the analysis instead of vanishing.
  CommunityPermissionProgressReport analyze({
    required String communityHandle,
    required Map<String, Object?> rawWorkflowDefinitions,
    required Map<String, LoomWorkflowStateMachine> workflowDefinitions,
    required Map<String, Set<String>> derivedPermissionIdsByRole,
  }) {
    final resolved = archetypeResolver.resolveAll(rawWorkflowDefinitions);
    final nodes = <String, Map<String, WorkflowStateNode>>{};
    final unprocessed = <String>[];

    for (final entry in workflowDefinitions.entries) {
      final workflowType = entry.key;
      final definition = entry.value;
      final archetype = resolved[workflowType];

      // permissions.md step 3d: a workflow with neither a bespoke family nor a
      // `responseTable` owner derives nothing and owns no permission-bearing
      // node. Recorded, never silently skipped.
      if (archetype == null || archetype.family == null) {
        unprocessed.add(workflowType);
        continue;
      }
      final family = archetype.family!;

      final transitionsByState = <String, List<StateTransitionRequirement>>{};
      for (final transition in definition.transitions) {
        final requirement = _requirementFor(
          transition: transition,
          definition: definition,
          family: family,
        );
        for (final state in transition.from) {
          transitionsByState
              .putIfAbsent(state, () => <StateTransitionRequirement>[])
              .add(requirement);
        }
      }

      final stateNodes = <String, WorkflowStateNode>{};
      for (final stateEntry in definition.states.entries) {
        final state = stateEntry.key;
        final stateModel = stateEntry.value;
        stateNodes[state] = WorkflowStateNode(
          workflowType: workflowType,
          state: state,
          label: stateModel.label,
          isTerminal: stateModel.isTerminal,
          transitions: List.unmodifiable(
            transitionsByState[state] ?? const <StateTransitionRequirement>[],
          ),
          readRoleIds: List.unmodifiable(
            stateModel.readGuard?.allowedRoleIds ?? const <String>[],
          ),
        );
      }
      nodes[workflowType] = stateNodes;
    }

    return CommunityPermissionProgressReport(
      communityHandle: communityHandle,
      groupId: 'loom_communities_$communityHandle',
      workflowNodes: nodes,
      stuckRoleFindings: _stuckFindings(
        nodes: nodes,
        derivedPermissionIdsByRole: derivedPermissionIdsByRole,
      ),
      unprocessedWorkflowTypes: List.unmodifiable(unprocessed),
    );
  }

  StateTransitionRequirement _requirementFor({
    required LoomWorkflowTransition transition,
    required LoomWorkflowStateMachine definition,
    required String family,
  }) {
    final permissions = <RequiredActionPermission>[];
    final permissionId = _permissionIdFor(
      transition: transition,
      definition: definition,
      family: family,
    );
    if (permissionId != null) {
      permissions.add(
        RequiredActionPermission(
          permissionId: permissionId,
          sourceActionId: transition.id,
          source: ProgressPermissionSource.transition,
        ),
      );
    }
    return StateTransitionRequirement(
      transitionId: transition.id,
      label: transition.label,
      toState: transition.to,
      allowedRoleIds: List.unmodifiable(
        transition.guard.allowedRoleIds ?? const <String>[],
      ),
      permissions: List.unmodifiable(permissions),
      guardSummary: List.unmodifiable(_guardSummary(transition.guard)),
    );
  }

  /// The permission id a transition's action resolves to, or null when the
  /// transition carries no permission at all.
  String? _permissionIdFor({
    required LoomWorkflowTransition transition,
    required LoomWorkflowStateMachine definition,
    required String family,
  }) {
    final declared = transition.action;
    if (declared != null && declared.isNotEmpty) {
      return archetypeResolver.permissionId(family, declared);
    }
    // Generic families declare no action and derive it structurally
    // (permissions.md §5). A transition with no target state is a pure
    // bookkeeping step and derives nothing.
    final target = transition.to;
    if (target == null) return null;
    final isTerminal = definition.states[target]?.isTerminal ?? false;
    final action = transition.tone == 'destructive' || isTerminal
        ? 'terminate'
        : 'advance';
    return archetypeResolver.permissionId(family, action);
  }

  /// Names the non-role guard conditions, so a runtime report can say which
  /// engine guard blocked a caller who already holds the permission.
  List<String> _guardSummary(WorkflowGuard guard) {
    final summary = <String>[];
    if (guard.actorEqualsField != null) {
      summary.add('actorEqualsField:${guard.actorEqualsField!.key}');
    }
    if (guard.actorInList != null) {
      summary.add('actorInList:${guard.actorInList!.key}');
    }
    if (guard.instanceDataEquals != null) {
      summary.add('instanceDataEquals:${guard.instanceDataEquals!.key}');
    }
    if (guard.formula != null) {
      summary.add('formula');
    }
    if (guard.cancellationDeadline != null) {
      summary.add('cancellationDeadline');
    }
    if (guard.relatedListMembership != null) {
      summary.add('relatedList');
    }
    if (guard.relatedAggregate != null) {
      summary.add('relatedAggregate');
    }
    if (guard.locationOverlap != null) {
      summary.add('locationOverlap');
    }
    if ((guard.requiresWorkflowsComplete ?? const <String>[]).isNotEmpty) {
      summary.add('requiresWorkflowsComplete');
    }
    return summary;
  }

  /// A role is stuck when the package *permits it to act* out of a state and
  /// the permission that act requires is not in its derived set.
  ///
  /// The test is **"may this role fire a transition from this state"**, never
  /// "is the role's permission set non-empty". A read-only role derives
  /// nothing and is never stuck, because no transition names it.
  List<StuckRoleFinding> _stuckFindings({
    required Map<String, Map<String, WorkflowStateNode>> nodes,
    required Map<String, Set<String>> derivedPermissionIdsByRole,
  }) {
    final findings = <StuckRoleFinding>[];
    final workflowTypes = nodes.keys.toList()..sort();
    for (final workflowType in workflowTypes) {
      final stateNodes = nodes[workflowType]!;
      final states = stateNodes.keys.toList()..sort();
      for (final state in states) {
        final node = stateNodes[state]!;
        final byRole = <String, List<StateTransitionRequirement>>{};
        for (final transition in node.transitions) {
          for (final roleId in transition.allowedRoleIds) {
            byRole.putIfAbsent(roleId, () => []).add(transition);
          }
        }
        final roleIds = byRole.keys.toList()..sort();
        for (final roleId in roleIds) {
          final held = derivedPermissionIdsByRole[roleId] ?? const <String>{};
          final blocked = <String>[];
          final missing = <String>{};
          for (final transition in byRole[roleId]!) {
            for (final permission in transition.permissions) {
              if (!held.contains(permission.permissionId)) {
                blocked.add(transition.transitionId);
                missing.add(permission.permissionId);
              }
            }
          }
          if (blocked.isEmpty) continue;
          final sortedBlocked = blocked.toSet().toList()..sort();
          final sortedMissing = missing.toList()..sort();
          findings.add(
            StuckRoleFinding(
              roleId: roleId,
              workflowType: workflowType,
              state: state,
              stateLabel: node.label,
              blockedTransitions: List.unmodifiable(sortedBlocked),
              missingPermissionIds: List.unmodifiable(sortedMissing),
            ),
          );
        }
      }
    }
    findings.sort((left, right) {
      final byRole = left.roleId.compareTo(right.roleId);
      if (byRole != 0) return byRole;
      final byWorkflow = left.workflowType.compareTo(right.workflowType);
      if (byWorkflow != 0) return byWorkflow;
      return left.state.compareTo(right.state);
    });
    return List.unmodifiable(findings);
  }
}
