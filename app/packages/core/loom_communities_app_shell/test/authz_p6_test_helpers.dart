import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

/// A test-only auth provider with an already-selected active account.
///
/// Engine-native widget tests are testing the content after a user has passed
/// the community entry gate. Keeping that session explicit makes the test
/// setup match the production flow without adding a test bypass to the gate.
class TestActiveAuthApi implements LoomAuthApi {
  TestActiveAuthApi({
    required String communityExtensionId,
    required LoomAccount activeAccount,
    required List<LoomAccount> accounts,
    List<LoomPersonaDefinition> personas = const [],
    LoomExperienceDefinition? experience,
  }) : _delegate = LocalAuthApi(
         personaResolver: personas.isEmpty ? null : (_) => personas,
         experienceResolver: experience == null ? null : (_) => experience,
       ),
       _session = LoomSession(account: activeAccount) {
    _delegate.seedAccounts(communityExtensionId, accounts);
  }

  final LocalAuthApi _delegate;
  LoomSession? _session;

  @override
  LoomSession? get currentSession => _session;

  @override
  Future<List<LoomAccount>> listAccounts({
    required String communityExtensionId,
  }) => _delegate.listAccounts(communityExtensionId: communityExtensionId);

  @override
  Future<LoomSession> signIn({required String accountId}) async {
    final session = await _delegate.signIn(accountId: accountId);
    _session = session;
    return session;
  }

  @override
  Future<LoomSignUpResult> signUp({
    required String communityExtensionId,
    required String displayName,
    required String personaTypeId,
  }) async {
    final result = await _delegate.signUp(
      communityExtensionId: communityExtensionId,
      displayName: displayName,
      personaTypeId: personaTypeId,
    );
    if (result.session case final session?) {
      _session = session;
    }
    return result;
  }

  @override
  Future<LoomSession> redeemInvite({
    required String code,
    required String displayName,
  }) async {
    final session = await _delegate.redeemInvite(
      code: code,
      displayName: displayName,
    );
    _session = session;
    return session;
  }

  Future<void> _ensureDelegateSession() async {
    if (_session != null && _delegate.currentSession == null) {
      await _delegate.signIn(accountId: _session!.account.accountId);
    }
  }

  @override
  Future<LoomCommunityInvite> issueInvite({
    required String personaTypeId,
    required String issuedByAccountId,
  }) async {
    await _ensureDelegateSession();
    return _delegate.issueInvite(
      personaTypeId: personaTypeId,
      issuedByAccountId: issuedByAccountId,
    );
  }

  @override
  Future<LoomAccount> approveAccount({required String accountId}) async {
    await _ensureDelegateSession();
    return _delegate.approveAccount(accountId: accountId);
  }

  @override
  Future<void> signOut() async {
    _session = null;
    await _delegate.signOut();
  }
}

const _tabletopAccounts = <LoomAccount>[
  LoomAccount(
    accountId: 'tabletop-organizer',
    displayName: 'Alex T.',
    personaTypeId: 'tabletop-organizer',
  ),
  LoomAccount(
    // The frozen Tabletop fixture still contains role-level actor seeds for
    // the shared widget tests. Keep this test account role-level as well so
    // those tests exercise the real entry gate without changing the fixture's
    // established actor identity. Individual-account behavior is covered by
    // the dedicated sign-in tests, which use the production account list.
    accountId: 'tabletop-member',
    displayName: 'Jordan W.',
    personaTypeId: 'tabletop-member',
  ),
  LoomAccount(
    accountId: 'tabletop-member-04',
    displayName: 'Sam K.',
    personaTypeId: 'tabletop-member',
  ),
  LoomAccount(
    accountId: 'tabletop-member-05',
    displayName: 'Priya N.',
    personaTypeId: 'tabletop-member',
  ),
  LoomAccount(
    accountId: 'tabletop-member-06',
    displayName: 'Casey M.',
    personaTypeId: 'tabletop-member',
  ),
];

TestActiveAuthApi activeAuthForCommunity({
  required LocalInstalledCommunity community,
  required LoomExperienceDefinition experience,
  String? personaTypeId,
  String? accountId,
  List<LoomAccount>? accounts,
}) {
  final personas = experience.personas ?? const <LoomPersonaDefinition>[];
  final usesTabletopAccounts = personas.any(
    (persona) => persona.personaId == 'tabletop-member',
  );
  final resolvedAccounts =
      accounts ??
      (usesTabletopAccounts
          ? _tabletopAccounts
          : [
              for (final persona in personas)
                LoomAccount(
                  accountId: persona.personaId,
                  displayName: 'Test ${persona.label}',
                  personaTypeId: persona.personaId,
                ),
            ]);
  final activeAccount = resolvedAccounts.firstWhere(
    (account) =>
        (accountId != null && account.accountId == accountId) ||
        (accountId == null &&
            personaTypeId != null &&
            account.personaTypeId == personaTypeId),
    orElse: () => resolvedAccounts.first,
  );
  return TestActiveAuthApi(
    communityExtensionId: community.extensionId,
    activeAccount: activeAccount,
    accounts: resolvedAccounts,
    personas: personas,
    experience: experience,
  );
}

TestActiveAuthApi activeAuthForInstalledCommunity({
  required LocalInstalledCommunity community,
  String? personaTypeId,
  String? accountId,
  List<LoomAccount>? accounts,
}) {
  final experience = experienceForExtensionId(
    community.extensionId,
    displayName: community.displayName,
    specVersion: community.specVersion,
    experienceConfiguration: community.experienceConfiguration,
  );
  return activeAuthForCommunity(
    community: community,
    experience: experience,
    personaTypeId: personaTypeId,
    accountId: accountId,
    accounts: accounts,
  );
}

Future<void> selectTestTabletopPersona(
  WidgetTester tester,
  String personaTypeId,
) async {
  final displayName = switch (personaTypeId) {
    'tabletop-organizer' => 'Alex T.',
    'tabletop-member' => 'Jordan W.',
    _ => throw ArgumentError('No test account for $personaTypeId'),
  };
  final picker = find.byKey(const ValueKey('persona-picker-button'));
  for (var attempt = 0; attempt < 40; attempt++) {
    if (picker.evaluate().isNotEmpty) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.tap(picker);
  await tester.pump();
  final specificPerson = find.byKey(
    const ValueKey('persona-sign-in-specific-person'),
  );
  for (var attempt = 0; attempt < 40; attempt++) {
    if (specificPerson.evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.ensureVisible(specificPerson);
  await tester.tap(specificPerson);
  await tester.pumpAndSettle();
  final account = find.text(displayName);
  for (var attempt = 0; attempt < 40; attempt++) {
    if (account.evaluate().isNotEmpty) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.ensureVisible(account.first);
  await tester.tap(account.first);
  await tester.pumpAndSettle();
}
