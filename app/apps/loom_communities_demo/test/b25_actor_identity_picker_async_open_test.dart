import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'walkthrough_wait.dart';
import 'workflow_ui_test_harness.dart';

/// Wraps [LocalAuthApi] so `listAccounts` only resolves after [delay], or
/// never resolves at all when [delay] is null -- standing in for the real
/// network round trip `RemoteLoomAuthApi.listAccounts` makes under
/// production wiring, which `_showActorIdentityPicker`
/// (`part01_local_extension_screen.dart`) awaits before calling
/// `showDialog`.
class _DelayedAuthApi implements LoomAuthApi {
  _DelayedAuthApi(this._inner, this.delay);

  final LoomAuthApi _inner;
  final Duration? delay;

  @override
  Future<List<LoomAccount>> listAccounts({
    required String communityExtensionId,
  }) async {
    final delay = this.delay;
    if (delay == null) {
      // Never resolves: models a stalled network call.
      return Completer<List<LoomAccount>>().future;
    }
    await Future<void>.delayed(delay);
    return _inner.listAccounts(communityExtensionId: communityExtensionId);
  }

  @override
  Future<List<LoomCommunityMember>> listCommunityMembers({
    required String communityExtensionId,
  }) => _inner.listCommunityMembers(communityExtensionId: communityExtensionId);

  @override
  Future<LoomSession> signIn({required String accountId}) =>
      _inner.signIn(accountId: accountId);

  @override
  Future<LoomSignUpResult> signUp({
    required String communityExtensionId,
    required String displayName,
    required String roleId,
  }) => _inner.signUp(
    communityExtensionId: communityExtensionId,
    displayName: displayName,
    roleId: roleId,
  );

  @override
  Future<LoomSession> redeemInvite({
    required String code,
    required String displayName,
  }) => _inner.redeemInvite(code: code, displayName: displayName);

  @override
  Future<LoomCommunityInvite> issueInvite({
    required String roleId,
    required String issuedByAccountId,
  }) =>
      _inner.issueInvite(roleId: roleId, issuedByAccountId: issuedByAccountId);

  @override
  Future<LoomAccount> approveAccount({required String accountId}) =>
      _inner.approveAccount(accountId: accountId);

  @override
  Future<void> signOut() => _inner.signOut();

  @override
  LoomSession? get currentSession => _inner.currentSession;
}

const _community = LocalInstalledCommunity(
  communityId: 'picker-async-open-community',
  displayName: 'Picker Async Open Community',
  extensionId: 'ext_picker_async_open_community',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#2f6f67',
  specVersion: currentCommunitySpecVersion,
  experienceConfiguration: <String, Object?>{
    'roles': <Object?>[
      <String, Object?>{'roleId': 'picker-async-open-member', 'label': 'Member'},
    ],
  },
);

Future<void> _pumpGatedPickerScreen(
  WidgetTester tester, {
  required Duration? listAccountsDelay,
}) async {
  final authApi = _DelayedAuthApi(
    LocalAuthApi()
      ..seedAccounts(_community.extensionId, const [
        LoomAccount(
          accountId: 'picker-async-open-member',
          displayName: 'Picker Async Open Member',
          roleId: 'picker-async-open-member',
        ),
      ]),
    listAccountsDelay,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: LocalExtensionScreen(
        community: _community,
        seedDataFiles: const [],
        authApi: authApi,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'openActorIdentityPickerDialog waits through a delayed listAccounts '
    'before returning',
    (tester) async {
      await _pumpGatedPickerScreen(
        tester,
        listAccountsDelay: const Duration(seconds: 2),
      );

      // A bare tap followed by a single pumpAndSettle is exactly the
      // pre-fix pattern this ticket replaces, and it does NOT see the
      // dialog while `listAccounts` is still pending -- confirmed directly
      // against the un-fixed behaviour before this test was trusted (see
      // HARNESS-async-identity-picker-and-wrong-auth-branch.md).
      await openActorIdentityPickerDialog(
        tester,
        description: 'actor identity picker in the async-open regression test',
      );

      expect(
        find.byKey(const ValueKey('actor-identity-picker-dialog')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'openActorIdentityPickerDialog throws with the dialog closed when '
    'listAccounts never resolves',
    (tester) async {
      await _pumpGatedPickerScreen(tester, listAccountsDelay: null);

      await expectLater(
        openActorIdentityPickerDialog(
          tester,
          description:
              'actor identity picker in the stalled-gate regression test',
          timeout: const Duration(milliseconds: 200),
        ),
        throwsA(isA<WalkthroughStallFailure>()),
      );

      expect(
        find.byKey(const ValueKey('actor-identity-picker-dialog')),
        findsNothing,
      );
    },
  );
}
