import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _communityId = 'authz-p5-membership-community';

const _actorIdentities = [
  LoomActorIdentity(
    fanId: 'admin',
    roleId: 'admin',
    label: 'Community admin',
    roleLabel: 'Admin',
    description: 'Manages community membership.',
  ),
  LoomActorIdentity(
    fanId: 'member',
    roleId: 'member',
    label: 'Member',
    roleLabel: 'Member',
    description: 'Joins community activities.',
  ),
  LoomActorIdentity(
    fanId: 'applicant',
    roleId: 'applicant',
    label: 'Applicant',
    roleLabel: 'Applicant',
    description: 'Requests access to the community.',
    accessMode: LoomActorIdentityAccessMode.requiresApproval,
  ),
  LoomActorIdentity(
    fanId: 'invited',
    roleId: 'invited',
    label: 'Invited member',
    roleLabel: 'Member',
    description: 'Joins with an invitation.',
    accessMode: LoomActorIdentityAccessMode.requiresInvite,
  ),
];

LoomExperienceDefinition _experience() {
  return const LoomExperienceDefinition(
    extensionId: _communityId,
    displayName: 'AuthZ P5 Community',
    tagline: 'Membership flow fixture',
    accentColor: 0xff246b62,
    workflows: const [],
    actorIdentities: _actorIdentities,
    workflowDefinitions: {
      'membership-review': LoomWorkflowStateMachine(
        workflowType: 'membership-review',
        initialState: 'pending',
        states: const {
          'pending': LoomWorkflowState(label: 'Pending'),
          'approved': LoomWorkflowState(label: 'Approved'),
        },
        transitions: const [
          LoomWorkflowTransition(
            id: 'approve-membership',
            label: 'Approve membership',
            from: ['pending'],
            to: 'approved',
            guard: WorkflowGuard(allowedRoleIds: ['admin']),
          ),
        ],
        renderBindings: const [
          RenderBinding(
            states: ['pending'],
            role: 'actor',
            tabId: 'admin',
            cardSurfaceFamily: 'approval',
            bindingKind: 'primary',
          ),
        ],
      ),
    },
  );
}

LocalAuthApi _api() {
  final experience = _experience();
  final api = LocalAuthApi(
    actorIdentityResolver: (_) => _actorIdentities,
    experienceResolver: (_) => experience,
  );
  api.seedAccounts(_communityId, const [
    LoomAccount(
      accountId: 'admin-1',
      displayName: 'Admin One',
      roleId: 'admin',
    ),
    LoomAccount(
      accountId: 'member-1',
      displayName: 'Member One',
      roleId: 'member',
    ),
  ]);
  return api;
}

Widget _authScreen(LocalAuthApi api) {
  return MaterialApp(
    home: LoomAuthScreen(
      authApi: api,
      communityExtensionId: _communityId,
      experience: _experience(),
      onSignIn: () {},
    ),
  );
}

void main() {
  group('AuthZ.P5 membership flows', () {
    test(
      'signUp returns active, pending, and rejected outcomes by accessMode',
      () async {
        final api = _api();

        final active = await api.signUp(
          communityExtensionId: _communityId,
          displayName: 'Open User',
          roleId: 'member',
        );
        expect(active, isA<LoomActiveSignUpResult>());
        expect(active.account.status, MembershipStatus.active);
        expect(active.session, isNotNull);
        expect(api.currentSession?.account.accountId, active.account.accountId);

        await api.signOut();
        final pending = await api.signUp(
          communityExtensionId: _communityId,
          displayName: 'Applicant User',
          roleId: 'applicant',
        );
        expect(pending, isA<LoomPendingApprovalSignUpResult>());
        expect(pending.account.status, MembershipStatus.pendingApproval);
        expect(pending.session, isNull);
        expect(api.currentSession, isNull);

        await expectLater(
          api.signUp(
            communityExtensionId: _communityId,
            displayName: 'Invite User',
            roleId: 'invited',
          ),
          throwsA(
            isA<LoomAuthException>().having(
              (error) => error.code,
              'code',
              LoomAuthErrorCode.roleRequiresInvite,
            ),
          ),
        );
      },
    );

    test(
      'signIn rejects pending approval with a distinguishable error',
      () async {
        final api = _api();
        final pending = await api.signUp(
          communityExtensionId: _communityId,
          displayName: 'Waiting User',
          roleId: 'applicant',
        );

        await expectLater(
          api.signIn(accountId: pending.account.accountId),
          throwsA(
            isA<LoomAuthException>()
                .having(
                  (error) => error.code,
                  'code',
                  LoomAuthErrorCode.accountPendingApproval,
                )
                .having(
                  (error) => error.message,
                  'message',
                  contains('pending approval'),
                ),
          ),
        );
      },
    );

    test(
      'redeemInvite accepts valid codes and rejects invalid or claimed codes',
      () async {
        final api = _api();
        await api.signIn(accountId: 'admin-1');
        final invite = await api.issueInvite(
          roleId: 'invited',
          issuedByAccountId: 'admin-1',
        );

        expect(invite.status, InviteStatus.pending);
        expect(invite.code, startsWith('LOOM-'));
        expect(invite.code.length, 11);

        await expectLater(
          api.redeemInvite(code: 'LOOM-NOTFOUND', displayName: 'Missing'),
          throwsA(
            isA<LoomAuthException>().having(
              (error) => error.code,
              'code',
              LoomAuthErrorCode.inviteNotFound,
            ),
          ),
        );

        final session = await api.redeemInvite(
          code: invite.code.toLowerCase(),
          displayName: 'Invited User',
        );
        expect(session.account.status, MembershipStatus.active);
        expect(session.account.roleId, 'invited');
        expect(api.currentSession, same(session));

        await expectLater(
          api.redeemInvite(code: invite.code, displayName: 'Second User'),
          throwsA(
            isA<LoomAuthException>().having(
              (error) => error.code,
              'code',
              LoomAuthErrorCode.inviteAlreadyClaimed,
            ),
          ),
        );
      },
    );

    test(
      'issueInvite and approveAccount complete the membership lifecycle',
      () async {
        final api = _api();
        await api.signIn(accountId: 'admin-1');

        final invite = await api.issueInvite(
          roleId: 'invited',
          issuedByAccountId: 'admin-1',
        );
        final invitedSession = await api.redeemInvite(
          code: invite.code,
          displayName: 'Invite Recipient',
        );
        expect(invitedSession.account.status, MembershipStatus.active);

        await api.signIn(accountId: 'admin-1');
        final pending = await api.signUp(
          communityExtensionId: _communityId,
          displayName: 'Approval Recipient',
          roleId: 'applicant',
        );
        final approved = await api.approveAccount(
          accountId: pending.account.accountId,
        );
        expect(approved.status, MembershipStatus.active);

        final approvedSession = await api.signIn(
          accountId: pending.account.accountId,
        );
        expect(approvedSession.account.status, MembershipStatus.active);
      },
    );

    testWidgets(
      'requiresInvite actorIdentities are absent from the open signup picker',
      (tester) async {
        final api = _api();
        await tester.pumpWidget(_authScreen(api));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('open-signup-role-dropdown')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('open-signup-role-invited')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('invite-redeem-role-invited')),
          findsOneWidget,
        );
        expect(find.text('Redeem an invite'), findsOneWidget);
      },
    );

    testWidgets(
      'pending and invite surface follows the admin capability gate',
      (tester) async {
        final api = _api();
        await api.signIn(accountId: 'admin-1');
        await tester.pumpWidget(_authScreen(api));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('pending-invites-surface')),
          findsOneWidget,
        );
        expect(find.text('Pending & Invites'), findsOneWidget);

        await api.signOut();
        await api.signIn(accountId: 'member-1');
        await tester.pumpWidget(_authScreen(api));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('pending-invites-surface')),
          findsNothing,
        );
      },
    );

    testWidgets('admin can issue an invite from the visible surface', (
      tester,
    ) async {
      final api = _api();
      await api.signIn(accountId: 'admin-1');
      await tester.pumpWidget(_authScreen(api));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('issue-invite-button')),
      );
      await tester.tap(find.byKey(const ValueKey('issue-invite-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('issued-invite-code')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('issued-invite-code')),
          matching: find.textContaining('LOOM-'),
        ),
        findsOneWidget,
      );
    });
  });
}
