import 'export_client.dart';

/// The live `role_permission` grant, keyed by (`group_id`, `role_id`).
class LiveRoleGrants {
  const LiveRoleGrants({
    required this.groupId,
    required this.roleId,
    required this.permissionIds,
  });

  final String groupId;
  final String roleId;
  final Set<String> permissionIds;
}

/// One community that could not be compared, and why.
///
/// Printed rather than dropped: a silently skipped community hides exactly the
/// case that would disprove the gate.
class UnprocessedCommunity {
  const UnprocessedCommunity({
    required this.communityHandle,
    required this.reason,
  });

  final String communityHandle;
  final String reason;
}

/// One permission-id disagreement.
class PermissionSetDrift {
  const PermissionSetDrift({
    required this.groupId,
    required this.roleId,
    required this.missingInLive,
    required this.unexpectedInLive,
    required this.reason,
  });

  final String groupId;
  final String roleId;

  /// Derived by the export, absent from the live grants. The action would
  /// fail at run time for a role the package says may perform it.
  final List<String> missingInLive;

  /// Live, but not derived -- a stale or hand-made grant.
  final List<String> unexpectedInLive;

  /// The rule that caught this, for a report that explains itself.
  final String reason;

  PermissionSetDrift copyWith({
    List<String>? missingInLive,
    List<String>? unexpectedInLive,
  }) => PermissionSetDrift(
    groupId: groupId,
    roleId: roleId,
    missingInLive: missingInLive ?? this.missingInLive,
    unexpectedInLive: unexpectedInLive ?? this.unexpectedInLive,
    reason: reason,
  );

  String get sentence {
    final parts = <String>[];
    if (missingInLive.isNotEmpty) {
      parts.add(
        'derives ${missingInLive.map((id) => '`$id`').join(', ')} but live '
        'holds none of them',
      );
    }
    if (unexpectedInLive.isNotEmpty) {
      parts.add(
        'live holds ${unexpectedInLive.map((id) => '`$id`').join(', ')} but '
        'the package derives none of them',
      );
    }
    return '$reason `$roleId` in `$groupId`: ${parts.join('; ')}.';
  }
}

/// The complete comparison result for one corpus run.
class PermissionParityResult {
  const PermissionParityResult({
    required this.communitiesCompared,
    required this.drifts,
    required this.unprocessed,
    required this.findings,
  });

  final List<String> communitiesCompared;
  final List<PermissionSetDrift> drifts;
  final List<UnprocessedCommunity> unprocessed;

  /// Derivation findings echoed from each export, per community handle.
  final Map<String, List<String>> findings;

  bool get hasDrift => drifts.isNotEmpty;
}

/// Compares exports against live grants over **exact permission-id sets**.
///
/// Rule 1 -- every `<handle>-admin` holds exactly the vocabulary's governance
/// set.
/// Rule 2 -- every package domain role holds exactly what its `roles[]` entry
/// derives.
/// Rule 3 -- no other live role in the group holds any `community.*`
/// permission.
/// Rule 4 -- **a role the export says derives an action holds that
/// permission.** This keys on "did the package permit the role to perform an
/// action", **never** on the derived set being non-empty: a read-only role
/// (`portability-member`) derives nothing and is correctly clean. Getting this
/// backwards makes the gate cry wolf on every legitimately read-only role.
class PermissionParityComparer {
  const PermissionParityComparer({required this.governancePermissionIds});

  /// The vocabulary's governance set, from `systemAdminRole` when the export
  /// carries one. Used for rule 3, which must recognise a governance grant on
  /// a role the package never declared.
  final Set<String> governancePermissionIds;

  PermissionParityResult compare({
    required Map<String, CommunityPermissionExport> exportsByHandle,
    required Map<String, List<LiveRoleGrants>> liveByGroupId,
    required List<UnprocessedCommunity> unprocessed,
  }) {
    final drifts = <PermissionSetDrift>[];
    final compared = <String>[];
    final findings = <String, List<String>>{};

    final handles = exportsByHandle.keys.toList()..sort();
    for (final handle in handles) {
      final export = exportsByHandle[handle]!;
      compared.add(handle);
      if (export.findings.isNotEmpty) {
        findings[handle] = [
          for (final finding in export.findings) finding.sentence,
        ];
      }

      final liveRoles = <String, LiveRoleGrants>{
        for (final row in liveByGroupId[export.groupId] ?? const <LiveRoleGrants>[])
          row.roleId: row,
      };
      final derivedRoleIds = <String>{
        for (final role in export.allRoles) role.roleId,
      };

      // Rule 1 + rule 2: exact sets, for every role the export names.
      for (final role in export.allRoles) {
        final live = liveRoles[role.roleId];
        final derived = role.permissionIdSet;
        final actual = live?.permissionIds ?? const <String>{};
        if (derived.length == actual.length &&
            derived.every(actual.contains)) {
          continue;
        }
        final isAdmin = role.roleId == export.systemAdminRole?.roleId;
        drifts.add(
          PermissionSetDrift(
            groupId: export.groupId,
            roleId: role.roleId,
            missingInLive: _sorted(derived.difference(actual)),
            unexpectedInLive: _sorted(actual.difference(derived)),
            reason: isAdmin
                ? 'rule 1 (system-admin governance set)'
                : 'rule 2 (package-derived set)',
          ),
        );
      }

      // Rule 3: no other live role in the group may hold a `community.*`
      // permission. A non-package role holding governance access is the exact
      // widening the generated-admin design exists to prevent.
      for (final live in liveRoles.values) {
        if (derivedRoleIds.contains(live.roleId)) continue;
        final governanceHeld = _sorted(
          live.permissionIds.where((id) => id.startsWith('community.')),
        );
        if (governanceHeld.isEmpty) continue;
        drifts.add(
          PermissionSetDrift(
            groupId: export.groupId,
            roleId: live.roleId,
            missingInLive: const <String>[],
            unexpectedInLive: governanceHeld,
            reason: 'rule 3 (undeclared role holding governance permissions)',
          ),
        );
      }

      // Rule 4: the package permits the role to act out of a state (a
      // transition guard naming it, or a create action), and the permission
      // that act requires is absent. Keyed on "permitted to act", never on
      // non-emptiness -- see the class doc.
      //
      // The guard here is deliberately narrow: skip a rule-4 entry only when
      // **rule 2 already reported this exact role**, so the same gap is not
      // narrated twice under two rule numbers. Testing the declared-role-id set
      // instead would suppress rule 4 for every role the package declares --
      // which is precisely the set it exists to catch. `derivedRoleIds` is
      // "every role in the export", true for essentially every role with
      // grants, so that condition made rule 4 unreachable.
      final ruleTwoRoleKeys = <String>{
        for (final existing in drifts)
          if (existing.reason.startsWith('rule 2')) _roleKey(existing),
      };
      for (final drift in _permittedActionDrifts(export)) {
        if (ruleTwoRoleKeys.contains(_roleKey(drift))) continue;
        drifts.add(drift);
      }
    }

    drifts.sort((left, right) {
      final byGroup = left.groupId.compareTo(right.groupId);
      if (byGroup != 0) return byGroup;
      return left.roleId.compareTo(right.roleId);
    });

    return PermissionParityResult(
      communitiesCompared: List.unmodifiable(compared),
      drifts: List.unmodifiable(drifts),
      unprocessed: List.unmodifiable(unprocessed),
      findings: Map.unmodifiable(findings),
    );
  }

  /// Rule 4, evaluated against the export's own `grants`.
  ///
  /// A grant with `sourceKind` of `transition` or `create_action` *is* the
  /// package saying "this role may perform this action". `governance` grants
  /// are the system-admin's fixed set and are not a package permission.
  List<PermissionSetDrift> _permittedActionDrifts(
    CommunityPermissionExport export,
  ) {
    final drifts = <PermissionSetDrift>[];
    for (final role in export.roles) {
      final packageGranted = [
        for (final grant in role.grants)
          if (grant.sourceKind != 'governance') grant.permissionId,
      ];
      if (packageGranted.isEmpty) continue;
      final missing = _sorted(
        packageGranted.toSet().difference(role.permissionIdSet),
      );
      if (missing.isEmpty) continue;
      drifts.add(
        PermissionSetDrift(
          groupId: export.groupId,
          roleId: role.roleId,
          missingInLive: missing,
          unexpectedInLive: const <String>[],
          reason:
              'rule 4 (package permits this role to act, but its own derived '
              'set omits the permission)',
        ),
      );
    }
    return drifts;
  }
}

List<String> _sorted(Iterable<String> values) => values.toList()..sort();

/// Identifies one role within one group, for "did an earlier rule already
/// report this role" checks.
String _roleKey(PermissionSetDrift drift) =>
    '${drift.groupId}\u0000${drift.roleId}';
