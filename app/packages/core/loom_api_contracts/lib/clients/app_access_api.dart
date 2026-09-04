import '../models/app_access/access_decision.dart';
import '../models/app_access/app_assignment.dart';
import '../models/app_access/app_group.dart';
import '../models/app_access/app_permission.dart';
import '../models/app_access/app_role.dart';
import '../models/app_access/registered_app.dart';
import '../models/shared/resource_ref.dart';

/// Generic multi-tenant authorization over Fan Passport identity.
///
/// Fan Passport answers "who is this user, and are they authenticated". This
/// API answers "which apps may they use, which groups are they in, which roles
/// do they hold there, and what may those roles do".
///
/// Deliberately app-agnostic: an app registers its own permission catalog,
/// defines groups and roles, and assigns fans. No Loom Communities concept
/// appears here — `loom_communities` is simply its first consumer.
///
/// Contract: `docs/API/OpenAPI/identity/app-access-api.openapi.yaml`.
abstract class AppAccessApi {
  // ── Apps ──────────────────────────────────────────────────────────────

  Future<List<RegisteredApp>> listApps();

  Future<RegisteredApp?> getApp(String appId);

  Future<RegisteredApp> registerApp({
    required String appId,
    required String displayName,
    required String idempotencyKey,
    String? description,
  });

  // ── Permission catalog ────────────────────────────────────────────────

  Future<List<AppPermission>> listPermissions({
    required String appId,
    String? category,
  });

  /// Replaces an app's entire permission catalog in one call.
  ///
  /// Permissions removed from the catalog are never silently revoked from
  /// roles — the returned catalog reports them in
  /// [AppPermissionCatalog.orphanedRoleGrants] for deliberate reconciliation.
  Future<AppPermissionCatalog> replacePermissionCatalog({
    required String appId,
    required String catalogVersion,
    required List<AppPermission> permissions,
    required String idempotencyKey,
  });

  // ── Groups ────────────────────────────────────────────────────────────

  Future<List<AppGroup>> listGroups(String appId);

  Future<AppGroup?> getGroup({required String appId, required String groupId});

  Future<AppGroup> createGroup({
    required String appId,
    required String groupId,
    required String displayName,
    required String idempotencyKey,
    String? parentGroupId,
    ResourceRef? externalRef,
  });

  // ── Roles, and role → permission mapping ──────────────────────────────

  /// Lists roles in an app. Pass [groupId] to list only roles bound to that
  /// group; omit it to include app-level template roles.
  Future<List<AppRole>> listRoles({required String appId, String? groupId});

  Future<AppRole?> getRole({required String appId, required String roleId});

  /// Creates a role. Pass [groupId] to bind it to one group, or omit it to
  /// create an app-level template role assignable in any group.
  Future<AppRole> createRole({
    required String appId,
    required String roleId,
    required String displayName,
    required String idempotencyKey,
    String? groupId,
    String? description,
    List<String> permissionIds,
  });

  /// Replaces the permission set a role grants. Every id must already exist in
  /// the app's catalog.
  Future<AppRole> setRolePermissions({
    required String appId,
    required String roleId,
    required List<String> permissionIds,
    required String idempotencyKey,
  });

  // ── Fan → app access ──────────────────────────────────────────────────

  Future<AppAccess?> getAppAccess({
    required String appId,
    required String fanId,
  });

  /// Grants or updates a fan's access to an app, with app-level roles.
  Future<AppAccess> setAppAccess({
    required String appId,
    required String fanId,
    required List<String> roleIds,
    required String idempotencyKey,
    AssignmentState state,
  });

  Future<void> revokeAppAccess({
    required String appId,
    required String fanId,
    required String idempotencyKey,
  });

  Future<List<AppAccess>> listFanApps(String fanId);

  // ── Fan → group membership ────────────────────────────────────────────

  Future<List<GroupMembership>> listGroupMembers({
    required String appId,
    required String groupId,
  });

  Future<GroupMembership?> getGroupMembership({
    required String appId,
    required String groupId,
    required String fanId,
  });

  /// Adds a fan to a group, or updates the roles they hold there.
  Future<GroupMembership> setGroupMembership({
    required String appId,
    required String groupId,
    required String fanId,
    required List<String> roleIds,
    required String idempotencyKey,
    AssignmentState state,
  });

  Future<void> removeGroupMember({
    required String appId,
    required String groupId,
    required String fanId,
    required String idempotencyKey,
  });

  /// Lists every group one fan belongs to, across apps.
  ///
  /// Backs cross-app and cross-community surfaces — for example a unified
  /// Messages tab spanning every community the fan is a member of.
  Future<List<GroupMembership>> listFanGroups({
    required String fanId,
    String? appId,
  });

  /// Lists every community-backed group one fan belongs to.
  ///
  /// Each response row includes the canonical [FanCommunityMembership]
  /// community id, group id, server-authoritative roles, and membership
  /// state. Callers use it to resolve a fan's communities without deriving or
  /// configuring group naming rules client-side.
  Future<List<FanCommunityMembership>> listFanCommunities({
    required String fanId,
    String? appId,
  });

  // ── Runtime authorization ─────────────────────────────────────────────

  /// Decides whether a fan holds one permission, optionally within a group.
  Future<AccessDecision> checkAccess({
    required String fanId,
    required String appId,
    required String permissionId,
    String? groupId,
  });

  /// Resolves every permission a fan effectively holds, in one call.
  Future<EffectivePermissions> getEffectivePermissions({
    required String appId,
    required String fanId,
    String? groupId,
  });
}
