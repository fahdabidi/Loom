import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

const _entryWorkflowDefinitions = <String, Object?>{
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
};

const _openRole = <String, Object?>{
  'roleId': 'open-member',
  'label': 'Open member',
  'roleLabel': 'Member',
  'description': 'Joins this open community.',
  'accessMode': 'open',
};

const _approvalRole = <String, Object?>{
  'roleId': 'approval-member',
  'label': 'Approval member',
  'roleLabel': 'Member',
  'description': 'Requests access to this community.',
  'accessMode': 'requiresApproval',
};

const _inviteRole = <String, Object?>{
  'roleId': 'invite-member',
  'label': 'Invite member',
  'roleLabel': 'Member',
  'description': 'Joins this community with an invite.',
  'accessMode': 'requiresInvite',
};

LocalInstalledCommunity _engineCommunity({
  required String communityId,
  required String displayName,
  required List<Map<String, Object?>> actorIdentities,
}) {
  return LocalInstalledCommunity(
    communityId: communityId,
    displayName: displayName,
    extensionId: 'authz-p6-$communityId',
    logoAssetId: null,
    cardImageAssetId: null,
    heroImageAssetId: null,
    accentColor: '#246B62',
    specVersion: currentCommunitySpecVersion,
    experienceConfiguration: <String, Object?>{
      'tagline': 'AuthZ.P6 entry gate fixture',
      'roles': actorIdentities,
      'workflowDefinitions': _entryWorkflowDefinitions,
      'workflowInstances': <Object?>[
        <String, Object?>{
          'instanceId': 'entry-content-1',
          'workflowType': 'entry-content',
          'currentState': 'ready',
          'createdByFanId': actorIdentities.first['roleId'],
          'instanceData': <String, Object?>{'title': 'Community content'},
        },
      ],
    },
  );
}

Widget _host(LocalInstalledCommunity community) {
  return MaterialApp(
    home: LocalExtensionScreen(community: community, seedDataFiles: const []),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _submitSignUp(WidgetTester tester, String displayName) async {
  final displayNameField = find.byKey(
    const ValueKey('open-signup-display-name'),
  );
  await tester.ensureVisible(displayNameField);
  await tester.enterText(displayNameField, displayName);
  final submit = find.byKey(const ValueKey('open-signup-submit'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
}

void main() {
  testWidgets(
    'open-only community gates entry, then renders content after signup',
    (tester) async {
      await tester.pumpWidget(
        _host(
          _engineCommunity(
            communityId: 'open',
            displayName: 'Open community',
            actorIdentities: [_openRole],
          ),
        ),
      );
      await _settle(tester);

      expect(
        find.byKey(const ValueKey('community-entry-gate')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('open-signup-submit')), findsOneWidget);
      expect(find.byKey(const ValueKey('opened-community-open')), findsNothing);

      await _submitSignUp(tester, 'Open User');
      await _settle(tester);

      expect(find.byKey(const ValueKey('community-entry-gate')), findsNothing);
      expect(
        find.byKey(const ValueKey('opened-community-open')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'requiresApproval community stays at the gate with pending membership state',
    (tester) async {
      await tester.pumpWidget(
        _host(
          _engineCommunity(
            communityId: 'approval',
            displayName: 'Approval community',
            actorIdentities: [_approvalRole],
          ),
        ),
      );
      await _settle(tester);

      await _submitSignUp(tester, 'Waiting User');
      await _settle(tester);

      expect(
        find.byKey(const ValueKey('community-entry-gate')),
        findsOneWidget,
      );
      expect(find.text('Pending approval'), findsAtLeastNWidgets(1));
      expect(
        find.text(
          'Your account was created and is waiting for community approval.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('opened-community-approval')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('community-entry-refresh-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'requiresInvite community exposes invite redemption at the entry gate',
    (tester) async {
      await tester.pumpWidget(
        _host(
          _engineCommunity(
            communityId: 'invite',
            displayName: 'Invite community',
            actorIdentities: [_inviteRole],
          ),
        ),
      );
      await _settle(tester);

      expect(
        find.byKey(const ValueKey('community-entry-gate')),
        findsOneWidget,
      );
      expect(find.text('Redeem an invite'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('redeem-invite-submit')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('invite-redeem-role-dropdown')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('opened-community-invite')),
        findsNothing,
      );
    },
  );
}
