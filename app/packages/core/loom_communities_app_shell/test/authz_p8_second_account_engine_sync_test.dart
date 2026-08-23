import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

const _communityId = 'authz-p8-community';
const _extensionId = 'authz-p8-extension';
const _openRoleId = 'open-member';
const _boardRoleId = 'hoa-board';
const _adminWorkflowInstanceId = 'authz-p8-admin-instance';
const _openAccountId = 'open-member-01';
const _seedCreatorFanId = 'hoa-board-00';
const _openAccountDisplayName = 'Open User';
const _freshBoardAccountDisplayName = 'Board Created In-Flow';
const _existingBoardAccountDisplayName = 'Board Existing';

LocalInstalledCommunity _communityFixture() => const LocalInstalledCommunity(
  communityId: _communityId,
  displayName: 'AuthZ.P8 regression community',
  extensionId: _extensionId,
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#246B62',
  specVersion: currentCommunitySpecVersion,
  appShellConfiguration: <String, Object?>{
    'tabs': <Object?>[
      <String, Object?>{'tabId': 'admin', 'label': 'Admin', 'iconKey': 'admin'},
    ],
  },
  experienceConfiguration: <String, Object?>{
    'tagline': 'AuthZ.P8 second-account sync regression',
    'roles': <Object?>[
      <String, Object?>{
        'roleId': _openRoleId,
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'Open member.',
        'accessMode': 'open',
      },
      <String, Object?>{
        'roleId': _boardRoleId,
        'label': 'Board',
        'roleLabel': 'Board',
        'description': 'Board-level manager.',
        'accessMode': 'open',
      },
    ],
    'workflowDefinitions': <String, Object?>{
      'admin-review': <String, Object?>{
        'initialState': 'pending',
        'states': <String, Object?>{
          'pending': <String, Object?>{'label': 'Pending'},
          'approved': <String, Object?>{'label': 'Approved'},
        },
        'transitions': <Object?>[
          <String, Object?>{
            'id': 'approve',
            'label': 'Approve',
            'from': <String>['pending'],
            'to': 'approved',
            'guard': <String, Object?>{
              'allowedRoleIds': <String>[_boardRoleId],
            },
          },
        ],
        'renderBindings': <Object?>[
          <String, Object?>{
            'states': <String>['pending'],
            'audience': 'receiver',
            'tabId': 'admin',
            'cardSurfaceFamily': 'approvalQueueItem',
            'bindingKind': 'primary',
          },
        ],
        'instanceDataSchema': <String, Object?>{
          'title': <String, Object?>{'type': 'text', 'label': 'Title'},
        },
      },
    },
    'workflowInstances': <Object?>[
      <String, Object?>{
        'instanceId': _adminWorkflowInstanceId,
        'workflowType': 'admin-review',
        'currentState': 'pending',
        'createdByFanId': _seedCreatorFanId,
        'instanceData': <String, Object?>{'title': 'Board-only instance'},
      },
    ],
  },
);

Widget _host(LocalAuthApi authApi) => MaterialApp(
  home: LocalExtensionScreen(
    community: _communityFixture(),
    seedDataFiles: const [],
    authApi: authApi,
  ),
);

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 25));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _openSpecificPersonSignIn(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('actor-identity-picker-button')));
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('actor-identity-sign-in-specific-person')),
  );
  final specificPerson = find.byKey(
    const ValueKey('actor-identity-sign-in-specific-person'),
  );
  await tester.ensureVisible(specificPerson);
  await tester.tap(specificPerson);
  await _pumpUntil(tester, find.text('Create New Account'));
}

Future<void> _signInFromEntryGate(
  WidgetTester tester,
  String displayName,
) async {
  final accountRow = find.ancestor(
    of: find.text(displayName),
    matching: find.byType(ListTile),
  );
  await _pumpUntil(tester, accountRow);
  await tester.ensureVisible(accountRow.first);
  await tester.tap(accountRow.first);
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('actor-identity-picker-button')),
  );
}

Future<void> _selectAccountFromSpecificPersonDialog(
  WidgetTester tester,
  String displayName,
) async {
  // The "Sign in as a specific person…" route pushes the same LoomAuthScreen
  // used by the entry gate (not the actor-identity-picker popup itself), so this
  // matches _signInFromEntryGate's plain ListTile lookup rather than
  // constraining to a "actor-identity-picker-dialog" ancestor that doesn't exist
  // on this route.
  final row = find.ancestor(
    of: find.text(displayName),
    matching: find.byType(ListTile),
  );
  await _pumpUntil(tester, row);
  await tester.ensureVisible(row.first);
  await tester.pumpAndSettle();
  await tester.tap(row.first, warnIfMissed: false);
  await tester.pumpAndSettle();
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('actor-identity-picker-button')),
  );
}

Future<void> _setSignupRole(WidgetTester tester, String fanId) async {
  final roleDropdown = find.byKey(const ValueKey('open-signup-role-dropdown'));
  await tester.ensureVisible(roleDropdown);
  await tester.tap(roleDropdown);
  await tester.pumpAndSettle();
  final target = find.byKey(ValueKey('open-signup-role-$fanId'));
  await _pumpUntil(tester, target);
  // DropdownMenuItem entries render inside a modal route overlay; the
  // strict hit-test check can flag a false negative here even though the
  // tap correctly lands on the item's InkWell, so it's disabled for this
  // one tap (matching the widget's real, working behavior at runtime).
  await tester.tap(target, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<String> _createBoardAccountFromPushedAuth(
  WidgetTester tester,
  LocalAuthApi authApi,
) async {
  await _setSignupRole(tester, _boardRoleId);
  final displayNameField = find.byKey(
    const ValueKey('open-signup-display-name'),
  );
  await tester.ensureVisible(displayNameField);
  await tester.enterText(displayNameField, _freshBoardAccountDisplayName);
  await tester.tap(find.byKey(const ValueKey('open-signup-submit')));
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('actor-identity-picker-button')),
  );
  final accountId = authApi.currentSession?.account.accountId;
  expect(accountId, isNotNull);
  return accountId!;
}

Future<void> _openAdminTab(WidgetTester tester) async {
  final adminTab = find.byKey(const ValueKey('community-tab-admin'));
  await _pumpUntil(tester, adminTab);
  await tester.ensureVisible(adminTab);
  await tester.pumpAndSettle();
  await tester.tap(adminTab, warnIfMissed: false);
  await tester.pumpAndSettle();
  await _pumpUntil(
    tester,
    find.byKey(const ValueKey('engine-native-list-root-admin')),
  );
}

void _assertAdminQuerySuccess(WidgetTester tester, String accountId) {
  expect(
    find.byKey(Key('engine-native-bindings-error-admin-$accountId')),
    findsNothing,
  );
  expect(
    find.textContaining('Permission denied for surface admin'),
    findsNothing,
  );
  expect(
    find.byKey(
      const ValueKey('generic-instance-card-$_adminWorkflowInstanceId'),
    ),
    findsOneWidget,
  );
}

void main() {
  testWidgets(
    'sign-in as specific person refreshes actorIdentity-type sync before release '
    'for created and pre-existing board accounts',
    (tester) async {
      final authApi = LocalAuthApi();
      authApi.seedAccounts(_extensionId, const [
        LoomAccount(
          accountId: _openAccountId,
          displayName: _openAccountDisplayName,
          roleId: _openRoleId,
        ),
      ]);

      await tester.pumpWidget(_host(authApi));
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey('community-entry-gate')),
      );
      await _signInFromEntryGate(tester, _openAccountDisplayName);

      expect(find.byKey(const ValueKey('community-tab-admin')), findsNothing);

      await _openSpecificPersonSignIn(tester);
      final freshBoardAccountId = await _createBoardAccountFromPushedAuth(
        tester,
        authApi,
      );
      await _openAdminTab(tester);
      _assertAdminQuerySuccess(tester, freshBoardAccountId);

      await _openSpecificPersonSignIn(tester);
      await _selectAccountFromSpecificPersonDialog(
        tester,
        _openAccountDisplayName,
      );
      expect(find.byKey(const ValueKey('community-tab-admin')), findsNothing);

      final existingBoardResult = await authApi.signUp(
        communityExtensionId: _extensionId,
        displayName: _existingBoardAccountDisplayName,
        roleId: _boardRoleId,
      );
      final existingBoardAccountId = existingBoardResult.account.accountId;

      await _openSpecificPersonSignIn(tester);
      await _selectAccountFromSpecificPersonDialog(
        tester,
        _existingBoardAccountDisplayName,
      );
      await _openAdminTab(tester);
      _assertAdminQuerySuccess(tester, existingBoardAccountId);
    },
  );
}
