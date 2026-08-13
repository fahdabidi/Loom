/// Lifecycle state shared by app access and group membership assignments.
enum AssignmentState { active, suspended, revoked }

/// One fan's access to one app, with any app-level roles they hold there.
///
/// App-level roles apply across every group in the app. Group-scoped roles are
/// carried on [GroupMembership] instead.
///
/// Maps to the `AppAccess` schema in
/// `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`.
class AppAccess {
  const AppAccess({
    required this.appId,
    required this.fanId,
    required this.roleIds,
    required this.state,
    required this.grantedAt,
  });

  final String appId;

  /// Fan Passport `fanId` — the identity subject of this assignment.
  final String fanId;

  /// App-level roles, applying across every group in this app.
  final List<String> roleIds;
  final AssignmentState state;
  final DateTime grantedAt;
}

/// One fan's membership of one group, and the roles they hold within it.
///
/// This single record answers both "is this fan in the group" and "as what" —
/// it is the join that community membership plus role assignment needs.
///
/// Maps to the `GroupMembership` schema in
/// `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`.
class GroupMembership {
  const GroupMembership({
    required this.appId,
    required this.groupId,
    required this.fanId,
    required this.roleIds,
    required this.state,
    required this.joinedAt,
  });

  final String appId;
  final String groupId;

  /// Fan Passport `fanId` — the identity subject of this membership.
  final String fanId;

  /// Roles this fan holds within this group.
  final List<String> roleIds;
  final AssignmentState state;
  final DateTime joinedAt;
}
