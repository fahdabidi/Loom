part of '../loom_communities_app_shell.dart';

/// An account represents either a seeded demo individual or a newly
/// signed-up user.  [accountId] is the stable per-individual id (e.g.
/// `"tabletop-member-05"`); [personaTypeId] is the *declared persona type*
/// this account plays (e.g. `"tabletop-member"` — the same string that
/// appears in `LoomPersonaDefinition.personaId`).
class LoomAccount {
  final String accountId;
  final String displayName;
  final String personaTypeId;

  const LoomAccount({
    required this.accountId,
    required this.displayName,
    required this.personaTypeId,
  });

  @override
  bool operator ==(Object other) =>
      other is LoomAccount &&
      other.accountId == accountId &&
      other.personaTypeId == personaTypeId;

  @override
  int get hashCode => Object.hash(accountId, personaTypeId);
}

/// A signed-in session binding one [LoomAccount] to the current user.
class LoomSession {
  final LoomAccount account;

  const LoomSession({required this.account});
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
  Future<LoomSession> signUp({
    required String communityExtensionId,
    required String displayName,
    required String personaTypeId,
  });

  /// Ends the current session.
  Future<void> signOut();

  /// The current session, or `null` when not signed in.
  LoomSession? get currentSession;
}
