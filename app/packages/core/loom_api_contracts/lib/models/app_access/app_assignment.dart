/// Lifecycle state shared by app access and group membership assignments.
///
/// The App Access service retains requested and rejected assignments so that
/// membership decisions remain auditable. They are first-class response
/// states, rather than an absence of a membership record.
enum AssignmentState { requested, active, suspended, revoked, rejected }

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

/// One fan's membership of a community-backed App Access group.
///
/// This is the server's join of [GroupMembership] with the community linked by
/// the group's external reference. It is intentionally distinct from a
/// client-side community configuration: [groupId], [roleIds], and [state] are
/// all returned by App Access for the authenticated fan.
///
/// Maps to the `FanCommunityMembership` schema in
/// `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`.
class FanCommunityMembership extends GroupMembership {
  const FanCommunityMembership({
    required super.appId,
    required super.groupId,
    required super.fanId,
    required super.roleIds,
    required super.state,
    required super.joinedAt,
    required this.communityId,
    required this.displayName,
  });

  /// Canonical community id from the group's external reference.
  final String communityId;

  /// The display name configured for the App Access group.
  final String displayName;
}
