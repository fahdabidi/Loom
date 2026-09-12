import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_auth_session/loom_auth_session.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

const _communityId = 'auth-recovery-community';
const _extensionId = 'auth-recovery-extension';

const _account = LoomAccount(
  accountId: 'fan-alice',
  displayName: 'Alice Active',
  roleId: 'member',
);

const _experience = LoomExperienceDefinition(
  extensionId: _extensionId,
  displayName: 'Auth recovery community',
  tagline: 'Secure login recovery fixture',
  accentColor: 0xff246b62,
  workflows: [],
  actorIdentities: [
    LoomActorIdentity(
      fanId: 'fan-alice',
      roleId: 'member',
      label: 'Alice Active',
      roleLabel: 'Member',
      description: 'A community member.',
    ),
  ],
);

final class _MemoryStorage implements LoomAuthSecureStorageBackend {
  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) async => null;

  @override
  Future<void> write({required String key, required String value}) async {}
}

final class _InteractiveSession extends LoomAuthSession {
  _InteractiveSession()
    : super(
        tokenEndpoint: Uri.parse(
          'https://identity.test/realms/loom/protocol/openid-connect/token',
        ),
        clientId: 'test-client',
        secureStorage: _MemoryStorage(),
      );

  bool usable = false;
  int loginCalls = 0;

  @override
  Future<String> currentAccessToken() async {
    if (!usable) throw const LoomAuthNotLoggedInException();
    return 'token-for-fan-alice';
  }

  @override
  Future<bool> completeInteractiveLogin() async => false;

  @override
  Future<void> loginInteractively({List<String>? scopes}) async {
    loginCalls += 1;
    usable = true;
  }
}

LoomRemoteServiceConfiguration _configuration(_InteractiveSession session) =>
    LoomRemoteServiceConfiguration(
      session: session,
      workflowServiceBaseUri: Uri.parse('https://workflow.test/api/'),
      appAccessBaseUri: Uri.parse('https://app-access.test/api/'),
      fanPassportBaseUri: Uri.parse('https://fan-passport.test/api/'),
      communityGroupIds: const {_communityId: 'test-group'},
    );

/// A remote implementation with controlled account-directory responses. It
/// still subclasses the production remote API so [LoomAuthScreen]'s remote
/// login affordance is exercised exactly as it is in production.
final class _RecoverableRemoteAuthApi extends RemoteLoomAuthApi {
  _RecoverableRemoteAuthApi(this.testSession)
    : super(
        session: testSession,
        appAccessBaseUri: Uri.parse('https://app-access.test/api/'),
        fanPassportBaseUri: Uri.parse('https://fan-passport.test/api/'),
        appId: 'loom_communities',
        communityId: _communityId,
        communityExtensionId: _extensionId,
        remoteServiceConfiguration: _configuration(testSession),
        fallbackCommunityGroupId: 'test-group',
        actorIdentityResolver: (_) => _experience.actorIdentities!,
      );

  final _InteractiveSession testSession;
  int accountLoadCalls = 0;
  bool failAccountLoads = false;
  Completer<List<LoomAccount>>? pendingAccountLoad;

  @override
  Future<List<LoomAccount>> listAccounts({
    required String communityExtensionId,
  }) async {
    accountLoadCalls += 1;
    final pending = pendingAccountLoad;
    if (pending != null) return pending.future;
    if (failAccountLoads) throw StateError('Account directory unavailable');
    return const [_account];
  }

  @override
  Future<LoomSession> signIn({required String accountId}) async {
    await testSession.currentAccessToken();
    if (accountId != _account.accountId) {
      throw const LoomAuthException(
        code: LoomAuthErrorCode.accountNotFound,
        message: 'The selected account is not the authenticated identity.',
      );
    }
    return const LoomSession(account: _account);
  }
}

final class _ThrowingAccountDirectoryAuthApi implements LoomAuthApi {
  _ThrowingAccountDirectoryAuthApi(this.delegate);

  final LocalAuthApi delegate;

  @override
  LoomSession? get currentSession => delegate.currentSession;

  @override
  Future<LoomAccount> approveAccount({required String accountId}) =>
      delegate.approveAccount(accountId: accountId);

  @override
  Future<LoomCommunityInvite> issueInvite({
    required String roleId,
    required String issuedByAccountId,
  }) => delegate.issueInvite(
    roleId: roleId,
    issuedByAccountId: issuedByAccountId,
  );

  @override
  Future<List<LoomCommunityMember>> listCommunityMembers({
    required String communityExtensionId,
  }) async => throw StateError('OAuth session is no longer usable');

  @override
  Future<List<LoomAccount>> listAccounts({
    required String communityExtensionId,
  }) async => throw StateError('OAuth session is no longer usable');

  @override
  Future<LoomSession> redeemInvite({
    required String code,
    required String displayName,
  }) => delegate.redeemInvite(code: code, displayName: displayName);

  @override
  Future<void> signOut() => delegate.signOut();

  @override
  Future<LoomSession> signIn({required String accountId}) =>
      delegate.signIn(accountId: accountId);

  @override
  Future<LoomSignUpResult> signUp({
    required String communityExtensionId,
    required String displayName,
    required String roleId,
  }) => delegate.signUp(
    communityExtensionId: communityExtensionId,
    displayName: displayName,
    roleId: roleId,
  );
}

Widget _authApp(LoomAuthApi api, {VoidCallback? onSignIn}) => MaterialApp(
  home: LoomAuthScreen(
    authApi: api,
    communityExtensionId: _extensionId,
    experience: _experience,
    onSignIn: onSignIn ?? () {},
  ),
);

const _entryCommunity = LocalInstalledCommunity(
  communityId: _communityId,
  displayName: 'Auth recovery community',
  extensionId: _extensionId,
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#246B62',
  specVersion: currentCommunitySpecVersion,
  experienceConfiguration: <String, Object?>{
    'roles': <Object?>[
      <String, Object?>{
        'roleId': 'member',
        'label': 'Alice Active',
        'roleLabel': 'Member',
        'description': 'A community member.',
      },
    ],
    'workflowDefinitions': <String, Object?>{
      'entry-content': <String, Object?>{
        'initialState': 'ready',
        'states': <String, Object?>{
          'ready': <String, Object?>{'label': 'Ready'},
        },
        'transitions': <Object?>[],
        'renderBindings': <Object?>[
          <String, Object?>{
            'states': <String>['ready'],
            'audience': 'any',
            'tabId': 'home',
            'cardSurfaceFamily': 'workflow-status',
            'bindingKind': 'primary',
          },
        ],
      },
    },
  },
);

void main() {
  testWidgets(
    'a loaded remote account directory always offers secure login and reloads after a cancelled retry',
    (tester) async {
      final session = _InteractiveSession();
      final api = _RecoverableRemoteAuthApi(session);
      await tester.pumpWidget(_authApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Alice Active'), findsAtLeastNWidgets(1));
      final secureLogin = find.byKey(
        const ValueKey('remote-auth-login-button'),
      );
      expect(secureLogin, findsOneWidget);

      await tester.ensureVisible(secureLogin);
      await tester.tap(secureLogin);
      await tester.pumpAndSettle();
      final productionLogin = tester.widget<LoomProductionLoginScreen>(
        find.byType(LoomProductionLoginScreen),
      );
      expect(productionLogin.session, same(session));

      // Closing the interactive route without a callback is a cancellation.
      Navigator.of(
        tester.element(find.byType(LoomProductionLoginScreen)),
      ).pop();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(secureLogin, findsOneWidget);
      expect(api.accountLoadCalls, 2);

      await tester.ensureVisible(secureLogin);
      await tester.tap(secureLogin);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('production-login-button')));
      await tester.pumpAndSettle();

      expect(session.loginCalls, 1);
      expect(api.accountLoadCalls, 3);
      expect(find.text('Alice Active'), findsAtLeastNWidgets(1));
      expect(secureLogin, findsOneWidget);
    },
  );

  testWidgets(
    'an unusable token cannot admit a picked account and leaves secure login reachable',
    (tester) async {
      final api = _RecoverableRemoteAuthApi(_InteractiveSession());
      var admissionCalls = 0;
      await tester.pumpWidget(
        _authApp(api, onSignIn: () => admissionCalls += 1),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.ancestor(
          of: find.text('ID: ${_account.accountId}'),
          matching: find.byType(ListTile),
        ),
      );
      await tester.pump();

      expect(admissionCalls, 0);
      expect(find.textContaining('Sign-in failed'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('remote-auth-login-button')),
        findsOneWidget,
      );
      expect(
        api.accountLoadCalls,
        1,
        reason: 'no membership refresh is needed',
      );
    },
  );

  testWidgets(
    'remote secure login remains available while account loading is pending',
    (tester) async {
      final api = _RecoverableRemoteAuthApi(_InteractiveSession())
        ..pendingAccountLoad = Completer<List<LoomAccount>>();
      await tester.pumpWidget(_authApp(api));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.byKey(const ValueKey('remote-auth-login-button')),
        findsOneWidget,
      );

      api.pendingAccountLoad!.complete(const [_account]);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'remote account-load failure keeps login available and Retry reloads',
    (tester) async {
      final api = _RecoverableRemoteAuthApi(_InteractiveSession())
        ..failAccountLoads = true;
      await tester.pumpWidget(_authApp(api));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Account directory unavailable'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('remote-auth-login-button')),
        findsOneWidget,
      );

      api.failAccountLoads = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(api.accountLoadCalls, 2);
      expect(find.text('Alice Active'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'local auth keeps its existing account flow without remote login',
    (tester) async {
      final api = LocalAuthApi()..seedAccounts(_extensionId, const [_account]);
      await tester.pumpWidget(_authApp(api));
      await tester.pumpAndSettle();

      expect(find.text('Alice Active'), findsAtLeastNWidgets(1));
      expect(
        find.byKey(const ValueKey('remote-auth-login-button')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'a cached active account with a failed entry check leaves checking and keeps content closed',
    (tester) async {
      final localApi = LocalAuthApi()
        ..seedAccounts(_extensionId, const [_account]);
      await localApi.signIn(accountId: _account.accountId);
      final authApi = _ThrowingAccountDirectoryAuthApi(localApi);

      await tester.pumpWidget(
        MaterialApp(
          home: LocalExtensionScreen(
            community: _entryCommunity,
            seedDataFiles: const [],
            authApi: authApi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('community-entry-checking')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('community-entry-gate')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('community-entry-refresh-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('opened-community-$_communityId')),
        findsNothing,
      );
    },
  );
}
