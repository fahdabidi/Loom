part of '../loom_communities_app_shell.dart';

/// In-memory demo implementation of [LoomAuthApi].
///
/// Seeds accounts from the frozen Tabletop Club JSON's own individual
/// actor-identity IDs (and equivalent individual ids for other
/// engine-native communities) so signing in as a specific individual
/// immediately surfaces already-seeded per-individual behaviour
/// (owner-only approvals, per-individual queues, etc.).
class LocalAuthApi implements LoomAuthApi {
  final Map<String, List<LoomAccount>> _accountsByCommunity = {};
  final Map<String, List<LoomCommunityInvite>> _invitesByCommunity = {};
  LoomSession? _currentSession;
  final List<LoomActorIdentity> Function(String communityExtensionId)?
  actorIdentityResolver;
  final LoomExperienceDefinition Function(String communityExtensionId)?
  experienceResolver;

  LocalAuthApi({this.actorIdentityResolver, this.experienceResolver}) {
    _seedTabletopAccounts();
  }

  // ── Seeded demo accounts ────────────────────────────────────────────

  void _seedTabletopAccounts() {
    const extId = 'ext_verify_tabletop_club';
    _accountsByCommunity[extId] = [
      const LoomAccount(
        accountId: 'tabletop-organizer',
        displayName: 'Alex T.',
        roleId: 'tabletop-organizer',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-03',
        displayName: 'Jordan W.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-04',
        displayName: 'Sam K.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-05',
        displayName: 'Priya N.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-06',
        displayName: 'Casey M.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-07',
        displayName: 'Riley B.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-08',
        displayName: 'Taylor G.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-09',
        displayName: 'Morgan D.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-10',
        displayName: 'Drew P.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-11',
        displayName: 'Avery S.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-12',
        displayName: 'Quinn L.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-13',
        displayName: 'Blake R.',
        roleId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-14',
        displayName: 'Reese J.',
        roleId: 'tabletop-member',
      ),
    ];
  }

  void seedAccounts(String communityExtensionId, List<LoomAccount> accounts) {
    _accountsByCommunity[communityExtensionId] = List.unmodifiable(accounts);
  }

  // ── LoomAuthApi ─────────────────────────────────────────────────────

  @override
  Future<List<LoomAccount>> listAccounts({
    required String communityExtensionId,
  }) async {
    return _accountsByCommunity[communityExtensionId] ?? const [];
  }

  @override
  Future<LoomSession> signIn({required String accountId}) async {
    final location = _accountLocation(accountId);
    if (location == null) {
      throw StateError('Account $accountId not found');
    }
    final account = location.account;
    switch (account.status) {
      case MembershipStatus.active:
        final session = LoomSession(account: account);
        _currentSession = session;
        return session;
      case MembershipStatus.pendingApproval:
        throw const LoomAuthException(
          code: LoomAuthErrorCode.accountPendingApproval,
          message: 'This account is pending approval and cannot sign in yet.',
        );
      case MembershipStatus.invited:
        throw const LoomAuthException(
          code: LoomAuthErrorCode.accountNotActive,
          message:
              'This account is invited but not active. Redeem the invitation before signing in.',
        );
    }
  }

  int _nextSignUpCounter = 20;
  int _nextInviteSequence = 100000;

  @override
  Future<LoomSignUpResult> signUp({
    required String communityExtensionId,
    required String displayName,
    required String roleId,
  }) async {
    final actorIdentity = actorIdentityResolver == null
        ? null
        : _resolveActorIdentity(communityExtensionId, roleId);
    final accessMode =
        actorIdentity?.accessMode ?? LoomActorIdentityAccessMode.open;
    if (accessMode == LoomActorIdentityAccessMode.requiresInvite) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.roleRequiresInvite,
        message:
            'Direct sign-up is not available for this actor identity. Redeem a community invite instead.',
      );
    }
    final counter = _nextSignUpCounter++;
    final account = LoomAccount(
      accountId: '$roleId-$counter',
      // Preserve the existing open-signup behavior exactly; the auth screen
      // performs presentation-level validation before calling this method.
      displayName: displayName,
      roleId: roleId,
      status: accessMode == LoomActorIdentityAccessMode.requiresApproval
          ? MembershipStatus.pendingApproval
          : MembershipStatus.active,
    );
    _appendAccount(communityExtensionId, account);

    if (account.status == MembershipStatus.pendingApproval) {
      return LoomPendingApprovalSignUpResult(account: account);
    }

    final result = LoomActiveSignUpResult(account: account);
    _currentSession = result;
    return result;
  }

  @override
  Future<LoomSession> redeemInvite({
    required String code,
    required String displayName,
  }) async {
    if (displayName.trim().isEmpty) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.invalidDisplayName,
        message: 'A display name is required to redeem an invite.',
      );
    }

    final normalizedCode = code.trim().toUpperCase();
    final location = _inviteLocation(normalizedCode);
    if (location == null) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.inviteNotFound,
        message: 'That invite code was not found.',
      );
    }
    switch (location.invite.status) {
      case InviteStatus.pending:
        break;
      case InviteStatus.claimed:
        throw const LoomAuthException(
          code: LoomAuthErrorCode.inviteAlreadyClaimed,
          message: 'That invite code has already been claimed.',
        );
      case InviteStatus.revoked:
        throw const LoomAuthException(
          code: LoomAuthErrorCode.inviteRevoked,
          message: 'That invite code has been revoked.',
        );
    }

    final actorIdentity = _actorIdentityForInvite(
      location.communityExtensionId,
      location.invite.roleId,
    );
    if (actorIdentity == null ||
        actorIdentity.accessMode !=
            LoomActorIdentityAccessMode.requiresInvite) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.inviteRoleInvalid,
        message: 'This invite is no longer valid for its community role.',
      );
    }

    final account = LoomAccount(
      accountId: '${location.invite.roleId}-${_nextSignUpCounter++}',
      displayName: displayName.trim(),
      roleId: location.invite.roleId,
      status: MembershipStatus.active,
    );
    _appendAccount(location.communityExtensionId, account);
    _replaceInvite(
      location.communityExtensionId,
      location.index,
      LoomCommunityInvite(
        inviteId: location.invite.inviteId,
        communityExtensionId: location.invite.communityExtensionId,
        roleId: location.invite.roleId,
        issuedByAccountId: location.invite.issuedByAccountId,
        code: location.invite.code,
        status: InviteStatus.claimed,
        createdAt: location.invite.createdAt,
      ),
    );
    final session = LoomSession(account: account);
    _currentSession = session;
    return session;
  }

  @override
  Future<LoomCommunityInvite> issueInvite({
    required String roleId,
    required String issuedByAccountId,
  }) async {
    final issuer = _requireAdminAccount(issuedByAccountId);
    final actorIdentity = _actorIdentityForMembershipAction(
      issuer.communityExtensionId,
      roleId,
    );
    if (actorIdentity.accessMode !=
        LoomActorIdentityAccessMode.requiresInvite) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.roleDoesNotAcceptInvites,
        message: 'Invites can only be issued for invite-only roles.',
      );
    }

    final sequence = _nextInviteSequence++;
    final invite = LoomCommunityInvite(
      inviteId: 'invite-$sequence',
      communityExtensionId: issuer.communityExtensionId,
      roleId: roleId,
      issuedByAccountId: issuer.account.accountId,
      code: _formatInviteCode(sequence),
      status: InviteStatus.pending,
      createdAt: DateTime.now().toUtc(),
    );
    final existing = _invitesByCommunity.putIfAbsent(
      issuer.communityExtensionId,
      () => [],
    );
    _invitesByCommunity[issuer.communityExtensionId] = [...existing, invite];
    return invite;
  }

  @override
  Future<LoomAccount> approveAccount({required String accountId}) async {
    final approverId = _currentSession?.account.accountId;
    if (approverId == null) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.membershipManagementUnauthorized,
        message: 'An active admin account must approve memberships.',
      );
    }
    final approver = _requireAdminAccount(approverId);
    final target = _accountLocation(accountId);
    if (target == null) {
      throw LoomAuthException(
        code: LoomAuthErrorCode.accountNotFound,
        message: 'Account $accountId was not found.',
      );
    }
    if (target.communityExtensionId != approver.communityExtensionId) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.membershipManagementUnauthorized,
        message: 'An admin can only approve accounts in their own community.',
      );
    }
    if (target.account.status != MembershipStatus.pendingApproval) {
      throw LoomAuthException(
        code: LoomAuthErrorCode.accountNotPendingApproval,
        message: 'Account $accountId is not pending approval.',
      );
    }
    final approved = LoomAccount(
      accountId: target.account.accountId,
      displayName: target.account.displayName,
      roleId: target.account.roleId,
      status: MembershipStatus.active,
    );
    _replaceAccount(target.communityExtensionId, approved);
    return approved;
  }

  @override
  Future<void> signOut() async {
    final memberId = _currentSession?.account.accountId;
    await endLoomReplicaSyncSession(memberId: memberId);
    _currentSession = null;
  }

  @override
  LoomSession? get currentSession => _currentSession;

  void _appendAccount(String communityExtensionId, LoomAccount account) {
    final existing = _accountsByCommunity.putIfAbsent(
      communityExtensionId,
      () => [],
    );
    _accountsByCommunity[communityExtensionId] = [...existing, account];
  }

  void _replaceAccount(String communityExtensionId, LoomAccount replacement) {
    final existing = _accountsByCommunity[communityExtensionId];
    if (existing == null) return;
    _accountsByCommunity[communityExtensionId] = [
      for (final account in existing)
        if (account.accountId == replacement.accountId)
          replacement
        else
          account,
    ];
  }

  ({String communityExtensionId, LoomAccount account})? _accountLocation(
    String accountId,
  ) {
    for (final entry in _accountsByCommunity.entries) {
      for (final account in entry.value) {
        if (account.accountId == accountId) {
          return (communityExtensionId: entry.key, account: account);
        }
      }
    }
    return null;
  }

  LoomActorIdentity? _resolveActorIdentity(
    String communityExtensionId,
    String roleId,
  ) {
    final actorIdentities = actorIdentityResolver!(communityExtensionId);
    for (final actorIdentity in actorIdentities) {
      if (actorIdentity.roleId == roleId) return actorIdentity;
    }
    throw ArgumentError(
      'Role "$roleId" is not declared by community '
      '"$communityExtensionId".',
    );
  }

  LoomActorIdentity? _actorIdentityForInvite(
    String communityExtensionId,
    String roleId,
  ) {
    final resolver = actorIdentityResolver;
    if (resolver != null) {
      final actorIdentities = resolver(communityExtensionId);
      for (final actorIdentity in actorIdentities) {
        if (actorIdentity.roleId == roleId) return actorIdentity;
      }
      return null;
    }
    final actorIdentities = _experienceForCommunity(
      communityExtensionId,
    ).actorIdentities;
    if (actorIdentities == null) return null;
    for (final actorIdentity in actorIdentities) {
      if (actorIdentity.roleId == roleId) return actorIdentity;
    }
    return null;
  }

  LoomActorIdentity _actorIdentityForMembershipAction(
    String communityExtensionId,
    String roleId,
  ) {
    final resolver = actorIdentityResolver;
    if (resolver != null) {
      return _resolveActorIdentity(communityExtensionId, roleId)!;
    }
    final actorIdentity = _actorIdentityForInvite(communityExtensionId, roleId);
    if (actorIdentity == null) {
      throw ArgumentError(
        'Role "$roleId" is not declared by community '
        '"$communityExtensionId".',
      );
    }
    return actorIdentity;
  }

  LoomExperienceDefinition _experienceForCommunity(String communityId) {
    final resolver = experienceResolver;
    return resolver?.call(communityId) ?? experienceForExtensionId(communityId);
  }

  ({String communityExtensionId, LoomAccount account}) _requireAdminAccount(
    String accountId,
  ) {
    final location = _accountLocation(accountId);
    if (location == null ||
        location.account.status != MembershipStatus.active ||
        !_roleCanAdministerAnyWorkflow(
          _experienceForCommunity(location.communityExtensionId),
          location.account.roleId,
        )) {
      throw LoomAuthException(
        code: LoomAuthErrorCode.membershipManagementUnauthorized,
        message:
            'Account $accountId is not authorized to manage memberships in this community.',
      );
    }
    return location;
  }

  ({String communityExtensionId, int index, LoomCommunityInvite invite})?
  _inviteLocation(String normalizedCode) {
    for (final entry in _invitesByCommunity.entries) {
      for (var index = 0; index < entry.value.length; index++) {
        final invite = entry.value[index];
        if (invite.code.toUpperCase() == normalizedCode) {
          return (
            communityExtensionId: entry.key,
            index: index,
            invite: invite,
          );
        }
      }
    }
    return null;
  }

  void _replaceInvite(
    String communityExtensionId,
    int index,
    LoomCommunityInvite replacement,
  ) {
    final existing = _invitesByCommunity[communityExtensionId];
    if (existing == null || index >= existing.length) return;
    final updated = [...existing];
    updated[index] = replacement;
    _invitesByCommunity[communityExtensionId] = updated;
  }

  /// Codes use `LOOM-` plus six uppercase characters from an alphabet that
  /// omits I, O, 0, and 1, making them short and human-typeable over chat or
  /// a phone call.
  String _formatInviteCode(int sequence) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var value = sequence;
    final chars = List<String>.filled(6, alphabet[0]);
    for (var index = chars.length - 1; index >= 0; index--) {
      chars[index] = alphabet[value % alphabet.length];
      value ~/= alphabet.length;
    }
    return 'LOOM-${chars.join()}';
  }
}
