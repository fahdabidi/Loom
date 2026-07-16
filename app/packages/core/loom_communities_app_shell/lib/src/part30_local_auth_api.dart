part of '../loom_communities_app_shell.dart';

/// In-memory demo implementation of [LoomAuthApi].
///
/// Seeds accounts from the frozen Tabletop Club JSON's own individual
/// persona ids (and equivalent individual ids for other
/// engine-native communities) so signing in as a specific individual
/// immediately surfaces already-seeded per-individual behaviour
/// (owner-only approvals, per-individual queues, etc.).
class LocalAuthApi implements LoomAuthApi {
  final Map<String, List<LoomAccount>> _accountsByCommunity = {};
  LoomSession? _currentSession;

  LocalAuthApi() {
    _seedTabletopAccounts();
  }

  // ── Seeded demo accounts ────────────────────────────────────────────

  void _seedTabletopAccounts() {
    const extId = 'ext_tabletop_club';
    _accountsByCommunity[extId] = [
      const LoomAccount(
        accountId: 'tabletop-organizer',
        displayName: 'Alex T.',
        personaTypeId: 'tabletop-organizer',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-03',
        displayName: 'Jordan W.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-04',
        displayName: 'Sam K.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-05',
        displayName: 'Priya N.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-06',
        displayName: 'Casey M.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-07',
        displayName: 'Riley B.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-08',
        displayName: 'Taylor G.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-09',
        displayName: 'Morgan D.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-10',
        displayName: 'Drew P.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-11',
        displayName: 'Avery S.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-12',
        displayName: 'Quinn L.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-13',
        displayName: 'Blake R.',
        personaTypeId: 'tabletop-member',
      ),
      const LoomAccount(
        accountId: 'tabletop-member-14',
        displayName: 'Reese J.',
        personaTypeId: 'tabletop-member',
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
    for (final list in _accountsByCommunity.values) {
      for (final account in list) {
        if (account.accountId == accountId) {
          final session = LoomSession(account: account);
          _currentSession = session;
          return session;
        }
      }
    }
    throw StateError('Account $accountId not found');
  }

  int _nextSignUpCounter = 20;

  @override
  Future<LoomSession> signUp({
    required String communityExtensionId,
    required String displayName,
    required String personaTypeId,
  }) async {
    final counter = _nextSignUpCounter++;
    final account = LoomAccount(
      accountId: '$personaTypeId-$counter',
      displayName: displayName,
      personaTypeId: personaTypeId,
    );
    final existing = _accountsByCommunity.putIfAbsent(
      communityExtensionId,
      () => [],
    );
    _accountsByCommunity[communityExtensionId] = [...existing, account];
    final session = LoomSession(account: account);
    _currentSession = session;
    return session;
  }

  @override
  Future<void> signOut() async {
    _currentSession = null;
  }

  @override
  LoomSession? get currentSession => _currentSession;
}
