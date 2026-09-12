import 'package:loom_permission_parity_gate/loom_permission_parity_gate.dart';
import 'package:test/test.dart';

const _groupId = 'loom_communities_data-portability-community';
const _governance = {
  'community.view',
  'community.invite',
  'community.manage_members',
  'community.manage_roles',
  'community.manage_settings',
};

CommunityPermissionExport _export({
  String handle = 'data-portability-community',
  String groupId = _groupId,
  List<ExportedRolePermissions> roles = const [],
  ExportedRolePermissions? admin,
  List<ExportedDerivationFinding> findings = const [],
}) => CommunityPermissionExport(
  appId: 'loom_communities',
  groupId: groupId,
  communityHandle: handle,
  systemAdminRole: admin,
  roles: roles,
  findings: findings,
);

ExportedRolePermissions _role(
  String roleId,
  List<String> permissionIds, {
  List<ExportedPermissionGrant>? grants,
}) => ExportedRolePermissions(
  roleId: roleId,
  permissionIds: permissionIds,
  grants: grants ?? const <ExportedPermissionGrant>[],
);

ExportedRolePermissions _admin({
  List<String>? permissionIds,
  String handle = 'data-portability-community',
}) => ExportedRolePermissions(
  roleId: '$handle-admin',
  permissionIds: permissionIds ?? _governance.toList(),
  grants: [
    for (final id in permissionIds ?? _governance.toList())
      ExportedPermissionGrant(permissionId: id, sourceKind: 'governance'),
  ],
);

LiveRoleGrants _liveAdmin({
  String handle = 'data-portability-community',
  String groupId = _groupId,
  Set<String>? permissionIds,
}) => LiveRoleGrants(
  groupId: groupId,
  roleId: '$handle-admin',
  permissionIds: permissionIds ?? _governance,
);

PermissionParityResult _compare({
  required Map<String, CommunityPermissionExport> exports,
  required Map<String, List<LiveRoleGrants>> live,
}) => const PermissionParityComparer(
  governancePermissionIds: _governance,
).compare(
  exportsByHandle: exports,
  liveByGroupId: live,
  unprocessed: const [],
);

void main() {
  group('rule 1 -- the system-admin governance set', () {
    test('passes when the admin holds exactly the governance set', () {
      final result = _compare(
        exports: {
          'data-portability-community': _export(admin: _admin()),
        },
        live: {
          _groupId: [
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'data-portability-community-admin',
              permissionIds: _governance,
            ),
          ],
        },
      );
      expect(result.drifts, isEmpty);
    });

    test('flags a missing governance permission by id, not by count', () {
      final result = _compare(
        exports: {
          'data-portability-community': _export(admin: _admin()),
        },
        live: {
          _groupId: [
            LiveRoleGrants(
              groupId: _groupId,
              roleId: 'data-portability-community-admin',
              // Same count-1 shape as a swap: one governance permission gone.
              permissionIds: _governance.difference({'community.manage_roles'}),
            ),
          ],
        },
      );
      expect(result.drifts, hasLength(1));
      expect(result.drifts.single.roleId, 'data-portability-community-admin');
      expect(
        result.drifts.single.missingInLive,
        ['community.manage_roles'],
      );
      expect(result.drifts.single.reason, contains('rule 1'));
    });

    test('a swap that preserves the count is still caught', () {
      // One permission out, a bogus one in. Identical cardinality, so a
      // count-based gate would pass this.
      final result = _compare(
        exports: {
          'data-portability-community': _export(admin: _admin()),
        },
        live: {
          _groupId: [
            LiveRoleGrants(
              groupId: _groupId,
              roleId: 'data-portability-community-admin',
              permissionIds: {
                ..._governance.difference({'community.view'}),
                'community.view_all',
              },
            ),
          ],
        },
      );
      expect(result.drifts, hasLength(1));
      expect(result.drifts.single.missingInLive, ['community.view']);
      expect(result.drifts.single.unexpectedInLive, ['community.view_all']);
    });
  });

  group('rule 2 -- package domain roles hold exactly their derived set', () {
    test('passes on an exact match', () {
      final result = _compare(
        exports: {
          'data-portability-community': _export(
            admin: _admin(),
            roles: [
              _role('portability-owner', [
                'export_wizard.run',
                'export_wizard.cancel',
              ]),
            ],
          ),
        },
        live: {
          _groupId: [
            _liveAdmin(),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'portability-owner',
              permissionIds: {'export_wizard.run', 'export_wizard.cancel'},
            ),
          ],
        },
      );
      expect(result.drifts, isEmpty);
    });

    test('flags a role whose live grant diverges from its derivation', () {
      final result = _compare(
        exports: {
          'data-portability-community': _export(
            admin: _admin(),
            roles: [
              _role('portability-owner', [
                'export_wizard.run',
                'export_wizard.cancel',
              ]),
            ],
          ),
        },
        live: {
          _groupId: [
            _liveAdmin(),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'portability-owner',
              // Masjid shape: the id the package derives is absent.
              permissionIds: {'export_wizard.run'},
            ),
          ],
        },
      );
      expect(result.drifts, hasLength(1));
      expect(result.drifts.single.missingInLive, ['export_wizard.cancel']);
      expect(result.drifts.single.reason, contains('rule 2'));
    });
  });

  group('rule 4 -- permission-permitted-to-act, never non-emptiness', () {
    test('does NOT flag a read-only role that derives nothing', () {
      // `portability-member` is read-only by design: readGuards only, no
      // transition guard, no create action. Zero permissions is CORRECT, and
      // a gate that flagged it would prove it keyed on non-emptiness.
      final result = _compare(
        exports: {
          'data-portability-community': _export(
            admin: _admin(),
            roles: [
              _role('portability-owner', ['export_wizard.run']),
              _role('portability-member', const []),
            ],
          ),
        },
        live: {
          _groupId: [
            _liveAdmin(),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'portability-owner',
              permissionIds: {'export_wizard.run'},
            ),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'portability-member',
              permissionIds: {},
            ),
          ],
        },
      );
      expect(
        result.drifts,
        isEmpty,
        reason: 'a legitimately empty set must never be treated as drift',
      );
    });

    test('flags a role the export says is permitted to act out of its own set', () {
      // The export claims a transition grant but its permissionIds omits the
      // permission. This is the shape rule 4 exists for, and it is the case
      // the old `derivedRoleIds.contains(...)` guard silently swallowed:
      // `portability-receiving-provider` IS declared by the package, so the
      // declared-set test suppressed the very drift it names.
      final export = _export(
        admin: _admin(),
        roles: [
          _role(
            'portability-receiving-provider',
            const [],
            grants: [
              const ExportedPermissionGrant(
                permissionId: 'export_wizard.decide_transfer',
                sourceKind: 'transition',
                sourceActionId: 'provider-accept-transfer',
                workflowType: 'export-transfer-verification',
              ),
            ],
          ),
        ],
      );
      final result = _compare(
        exports: {'data-portability-community': export},
        live: {
          _groupId: [
            _liveAdmin(),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'portability-receiving-provider',
              permissionIds: {},
            ),
          ],
        },
      );
      expect(result.drifts, hasLength(1));
      expect(result.drifts.single.roleId, 'portability-receiving-provider');
      expect(
        result.drifts.single.missingInLive,
        ['export_wizard.decide_transfer'],
      );
      expect(result.drifts.single.reason, contains('rule 4'));
    });

    test('rule 4 stays silent when rule 2 already narrated the same role', () {
      // Guards against double-reporting: when rule 2 has already flagged this
      // exact role, rule 4 must not add a second entry for it.
      final export = _export(
        admin: _admin(),
        roles: [
          _role(
            'portability-owner',
            const ['export_wizard.run', 'export_wizard.cancel'],
            grants: [
              const ExportedPermissionGrant(
                permissionId: 'export_wizard.run',
                sourceKind: 'transition',
                sourceActionId: 'run-bundle',
                workflowType: 'export-full-bundle',
              ),
              const ExportedPermissionGrant(
                permissionId: 'export_wizard.cancel',
                sourceKind: 'transition',
                sourceActionId: 'cancel-bundle',
                workflowType: 'export-full-bundle',
              ),
            ],
          ),
        ],
      );
      final result = _compare(
        exports: {'data-portability-community': export},
        live: {
          _groupId: [
            _liveAdmin(),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'portability-owner',
              // The live row is missing `export_wizard.cancel`.
              permissionIds: {'export_wizard.run'},
            ),
          ],
        },
      );
      expect(result.drifts, hasLength(1));
      expect(result.drifts.single.roleId, 'portability-owner');
      expect(result.drifts.single.reason, contains('rule 2'));
      expect(
        result.drifts.where((d) => d.reason.contains('rule 4')),
        isEmpty,
        reason: 'rule 2 already narrated this role; rule 4 must not repeat it',
      );
    });

    test('a governance-only grant does not count as permission-to-act', () {
      final export = _export(
        admin: _admin(),
        roles: [
          _role(
            'read-only-role',
            const [],
            grants: [
              for (final id in _governance)
                ExportedPermissionGrant(
                  permissionId: id,
                  sourceKind: 'governance',
                ),
            ],
          ),
        ],
      );
      final result = _compare(
        exports: {'data-portability-community': export},
        live: {
          _groupId: [
            _liveAdmin(),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'read-only-role',
              permissionIds: {},
            ),
          ],
        },
      );
      expect(
        result.drifts,
        isEmpty,
        reason: 'a governance sourceKind is not a package permission to act',
      );
    });
  });

  group('rule 3 -- no undeclared role may hold a community.* permission', () {
    test('flags a stale role holding governance access', () {
      final result = _compare(
        exports: {
          'data-portability-community': _export(
            admin: _admin(),
            roles: [_role('portability-owner', ['export_wizard.run'])],
          ),
        },
        live: {
          _groupId: [
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'data-portability-community-admin',
              permissionIds: _governance,
            ),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'portability-owner',
              permissionIds: {'export_wizard.run'},
            ),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'stale-legacy-role',
              permissionIds: {'community.manage_members'},
            ),
          ],
        },
      );
      expect(result.drifts, hasLength(1));
      expect(result.drifts.single.roleId, 'stale-legacy-role');
      expect(result.drifts.single.reason, contains('rule 3'));
    });

    test('an unrelated undeclared role with no community.* grant is clean', () {
      final result = _compare(
        exports: {
          'data-portability-community': _export(
            admin: _admin(),
            roles: [_role('portability-owner', ['export_wizard.run'])],
          ),
        },
        live: {
          _groupId: [
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'data-portability-community-admin',
              permissionIds: _governance,
            ),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'portability-owner',
              permissionIds: {'export_wizard.run'},
            ),
          ],
        },
      );
      expect(result.drifts, isEmpty);
    });
  });

  group('unprocessed communities', () {
    test('a community that could not be compared is reported, not dropped', () {
      final result = const PermissionParityComparer(
        governancePermissionIds: _governance,
      ).compare(
        exportsByHandle: const {},
        liveByGroupId: const {},
        unprocessed: const [
          UnprocessedCommunity(
            communityHandle: 'garden-club',
            reason: 'HTTP 401',
          ),
        ],
      );
      expect(result.unprocessed, hasLength(1));
      expect(result.unprocessed.single.communityHandle, 'garden-club');
      expect(result.communitiesCompared, isEmpty);
    });
  });

  group('derivation findings', () {
    test('findings are surfaced per community but do not become drift', () {
      final result = _compare(
        exports: {
          'data-portability-community': _export(
            admin: _admin(),
            roles: [_role('portability-owner', ['export_wizard.run'])],
            findings: const [
              ExportedDerivationFinding({
                'code': 'undeclared_role_in_guard',
                'message': 'guard names a role the package does not declare',
                'workflowType': 'export-full-bundle',
                'transitionId': 'retry-full-bundle',
              }),
            ],
          ),
        },
        live: {
          _groupId: [
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'data-portability-community-admin',
              permissionIds: _governance,
            ),
            const LiveRoleGrants(
              groupId: _groupId,
              roleId: 'portability-owner',
              permissionIds: {'export_wizard.run'},
            ),
          ],
        },
      );
      expect(result.drifts, isEmpty);
      expect(result.findings['data-portability-community'], hasLength(1));
      expect(
        result.findings['data-portability-community']!.single,
        contains('retry-full-bundle'),
      );
    });
  });
}
