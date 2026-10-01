import 'dart:convert';
import 'dart:io';

import 'comparison.dart';

/// Reads live role grants the same way `check_role_parity.sh` already does:
/// direct `kubectl exec postgres-0 -- psql`, so the gate needs Postgres access
/// but not a second HTTP round trip per role.
///
/// Deliberately one query for the whole corpus rather than one per community.
/// A per-community query would be 10 round trips through `kubectl exec` for
/// data one `select` returns, and the sibing gate's own convention is a
/// single read.
class LiveRoleGrantsReader {
  const LiveRoleGrantsReader({
    this.kubectl = 'kubectl',
    this.namespace = 'loom',
    this.pod = 'postgres-0',
    this.database = 'loom_app_access',
    this.username = 'loom',
    this.groupPrefix = 'loom_communities_',
    this.appId = 'loom_communities',
  });

  final String kubectl;
  final String namespace;
  final String pod;
  final String database;
  final String username;
  final String groupPrefix;

  /// The app whose roles this reads -- `app_role` and `role_permission` are
  /// both keyed by `(app_id, role_id)`, and the same `role_id` can exist
  /// under more than one app. Threaded through to [buildLiveRoleGrantsSql],
  /// which validates it before it is interpolated into SQL.
  final String appId;

  /// Reads every grant for every community group in one query.
  Map<String, List<LiveRoleGrants>> readAll() {
    final password = _readPostgresPassword();
    final grants = _readGrantRows(password);
    final byGroup = <String, List<LiveRoleGrants>>{};
    for (final row in grants) {
      byGroup.putIfAbsent(row.groupId, () => <LiveRoleGrants>[]).add(row);
    }
    return byGroup;
  }

  /// The live grant rows, one per (group, role) with its permission-id set.
  List<LiveRoleGrants> _readGrantRows(String password) {
    // `role_permission` has no `group_id`; the group lives on `app_role`.
    // Both tables are keyed by `(app_id, role_id)`, so the join matches both
    // columns and the read is scoped to this one app -- see
    // `buildLiveRoleGrantsSql`'s doc for why joining on `role_id` alone is
    // wrong.
    final sql = buildLiveRoleGrantsSql(appId);
    final result = Process.runSync(kubectl, [
      'exec',
      '-n',
      namespace,
      pod,
      '--',
      'env',
      'PGPASSWORD=$password',
      'psql',
      '-U',
      username,
      '-d',
      database,
      '-A',
      '-t',
      '-F',
      '|',
      '-c',
      sql,
    ], environment: {'PGPASSWORD': password});
    if (result.exitCode != 0) {
      throw StateError(
        'The live role-grant read failed (exit ${result.exitCode}): '
        '${result.stderr}',
      );
    }

    final byRole = <String, Set<String>>{};
    final groupByRole = <String, String>{};
    for (final line in '${result.stdout}'.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('|');
      if (parts.length < 2) continue;
      final groupId = parts[0];
      final roleId = parts[1];
      final key = '$groupId\u0000$roleId';
      groupByRole[key] = groupId;
      final permissions = byRole.putIfAbsent(key, () => <String>{});
      // A role with no grants still appears once, with a null permission
      // column -- so the empty set is recorded rather than the role vanishing.
      if (parts.length >= 3) {
        final permissionId = parts[2].trim();
        if (permissionId.isNotEmpty) permissions.add(permissionId);
      }
    }

    final rows = <LiveRoleGrants>[];
    for (final entry in byRole.entries) {
      final separator = entry.key.indexOf('\u0000');
      rows.add(
        LiveRoleGrants(
          groupId: entry.key.substring(0, separator),
          roleId: entry.key.substring(separator + 1),
          permissionIds: entry.value,
        ),
      );
    }
    rows.sort((left, right) {
      final byGroup = left.groupId.compareTo(right.groupId);
      if (byGroup != 0) return byGroup;
      return left.roleId.compareTo(right.roleId);
    });
    return rows;
  }

  String _readPostgresPassword() {
    final result = Process.runSync(kubectl, [
      'get',
      'secret',
      '-n',
      namespace,
      'postgres-credentials',
      '-o',
      'jsonpath={.data.password}',
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'Could not read the postgres secret (exit ${result.exitCode}): '
        '${result.stderr}',
      );
    }
    final encoded = '${result.stdout}'.trim();
    if (encoded.isEmpty) {
      throw StateError('The postgres-credentials secret carried no password.');
    }
    return utf8.decode(base64.decode(encoded));
  }
}

/// The allowed shape for an app id that is about to be interpolated into
/// live SQL. Deliberately narrow -- it is the thing standing between a bad
/// value and a broken `psql -c` invocation.
final RegExp appIdPattern = RegExp(r'^[a-z0-9_]+$');

/// Builds the SQL that reads live grant rows for exactly one app.
///
/// `app_role` and `role_permission` are both keyed by `(app_id, role_id)`.
/// Joining on `role_id` alone -- the bug found live 2026-10-01 -- attributes
/// a same-named role's grants in a DIFFERENT app to this one: a second app,
/// `ai_controller`, has its own `member` role holding `profile.read`, Loom
/// Communities also has a role `member`, and the unqualified join merged the
/// two. Fixing just the join is not enough on its own: `app_role` is not
/// otherwise filtered by app, so the `where` clause scopes `r` to the one
/// app being checked, and the join then matches `role_permission` rows for
/// that same app.
///
/// [appId] is interpolated directly into the query text run through `psql`,
/// so it is validated against [appIdPattern] rather than merely trusted.
String buildLiveRoleGrantsSql(String appId) {
  if (!appIdPattern.hasMatch(appId)) {
    throw ArgumentError.value(
      appId,
      'appId',
      'must match ${appIdPattern.pattern} to be safely interpolated into SQL',
    );
  }
  return "select r.group_id, r.role_id, rp.permission_id "
      "from app_role r "
      "left join role_permission rp "
      "on rp.app_id = r.app_id and rp.role_id = r.role_id "
      "where r.app_id = '$appId' "
      "and r.group_id like 'loom_communities_%' "
      "order by r.group_id, r.role_id, rp.permission_id;";
}
