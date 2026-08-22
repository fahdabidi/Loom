part of '../loom_communities_app_shell.dart';

enum MembershipStatus { active, pendingApproval, invited }

enum InviteStatus { pending, claimed, revoked }

/// Data shape for a community invitation. The local auth implementation keeps
/// these records in its in-memory community store until a backend-backed
/// membership service is available.
class LoomCommunityInvite {
  final String inviteId;
  final String communityExtensionId;
  final String roleId;
  final String issuedByAccountId;
  final String code;
  final InviteStatus status;
  final DateTime createdAt;

  const LoomCommunityInvite({
    required this.inviteId,
    required this.communityExtensionId,
    required this.roleId,
    required this.issuedByAccountId,
    required this.code,
    required this.status,
    required this.createdAt,
  });
}

/// An account represents either a seeded demo individual or a newly
/// signed-up user.  [accountId] is the stable per-individual id (e.g.
/// `"tabletop-member-05"`); [roleId] is the *declared persona type*
/// this account plays (e.g. `"tabletop-member"` — the same string that
/// appears in `LoomPersonaDefinition.roleId`).
class LoomAccount {
  final String accountId;
  final String displayName;
  final String roleId;
  final MembershipStatus status;

  const LoomAccount({
    required this.accountId,
    required this.displayName,
    required this.roleId,
    this.status = MembershipStatus.active,
  });

  @override
  bool operator ==(Object other) =>
      other is LoomAccount &&
      other.accountId == accountId &&
      other.roleId == roleId;

  @override
  int get hashCode => Object.hash(accountId, roleId);
}

/// A signed-in session binding one [LoomAccount] to the current user.
class LoomSession {
  final LoomAccount account;

  const LoomSession({required this.account});
}

/// The typed outcome of creating an account.
///
/// [LoomActiveSignUpResult] is also a [LoomSession] for compatibility with
/// callers that treated an open signup's return value as the new session.
/// [LoomPendingApprovalSignUpResult] deliberately never becomes
/// [LoomAuthApi.currentSession]; its [session] is `null` and the account must
/// be approved before it can sign in.
sealed class LoomSignUpResult extends LoomSession {
  const LoomSignUpResult({required super.account});

  LoomSession? get session;

  bool get createsUsableSession => session != null;
}

final class LoomActiveSignUpResult extends LoomSignUpResult {
  const LoomActiveSignUpResult({required super.account});

  @override
  LoomSession get session => this;
}

final class LoomPendingApprovalSignUpResult extends LoomSignUpResult {
  const LoomPendingApprovalSignUpResult({required super.account});

  @override
  LoomSession? get session => null;
}

enum LoomAuthErrorCode {
  accountNotFound,
  accountPendingApproval,
  accountNotActive,
  accountNotPendingApproval,
  personaRequiresInvite,
  personaNotFound,
  personaDoesNotAcceptInvites,
  invalidDisplayName,
  inviteNotFound,
  inviteAlreadyClaimed,
  inviteRevoked,
  invitePersonaInvalid,
  membershipManagementUnauthorized,
}

/// A stable, inspectable auth/membership failure for UI and tests.
class LoomAuthException implements Exception {
  const LoomAuthException({required this.code, required this.message});

  final LoomAuthErrorCode code;
  final String message;

  @override
  String toString() => 'LoomAuthException(${code.name}): $message';
}

/// Abstract identity-provider contract modelled on [WorkflowEngineApi]'s
/// own pattern — one `Local*` implementation for demo/stub usage, a
/// separate remote implementation when a real backend exists.
abstract class LoomAuthApi {
  /// Lists every account registered for this community extension.
  Future<List<LoomAccount>> listAccounts({
    required String communityExtensionId,
  });

  /// Signs in as an existing account, returning the new session.
  Future<LoomSession> signIn({required String accountId});

  /// Signs up a new individual account for the given persona type.
  ///
  /// Open personas return [LoomActiveSignUpResult], approval-gated personas
  /// return [LoomPendingApprovalSignUpResult], and rejected attempts throw a
  /// [LoomAuthException].
  Future<LoomSignUpResult> signUp({
    required String communityExtensionId,
    required String displayName,
    required String roleId,
  });

  /// Redeems a pending invite and starts an active session for the new
  /// account. The invite determines both the community and persona type.
  Future<LoomSession> redeemInvite({
    required String code,
    required String displayName,
  });

  /// Issues a pending invite on behalf of an active, admin-capable account.
  Future<LoomCommunityInvite> issueInvite({
    required String roleId,
    required String issuedByAccountId,
  });

  /// Approves a pending account using the current active, admin-capable
  /// account as the approver.
  Future<LoomAccount> approveAccount({required String accountId});

  /// Ends the current session.
  Future<void> signOut();

  /// The current session, or `null` when not signed in.
  LoomSession? get currentSession;
}
