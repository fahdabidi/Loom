import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

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
        'role': 'any',
        'tabId': 'home',
        'cardSurfaceFamily': 'workflow-status',
        'bindingKind': 'primary',
      },
    ],
  },
};

const _openPersona = <String, Object?>{
  'personaId': 'open-member',
  'label': 'Open member',
  'roleLabel': 'Member',
  'description': 'Joins this open community.',
  'accessMode': 'open',
};

const _approvalPersona = <String, Object?>{
  'personaId': 'approval-member',
  'label': 'Approval member',
  'roleLabel': 'Member',
  'description': 'Requests access to this community.',
  'accessMode': 'requiresApproval',
};

const _invitePersona = <String, Object?>{
  'personaId': 'invite-member',
  'label': 'Invite member',
  'roleLabel': 'Member',
  'description': 'Joins this community with an invite.',
  'accessMode': 'requiresInvite',
};

LocalInstalledCommunity _engineCommunity({
  required String communityId,
  required String displayName,
  required List<Map<String, Object?>> personas,
}) {
  return LocalInstalledCommunity(
    communityId: communityId,
    displayName: displayName,
    extensionId: 'authz-p6-$communityId',
    logoAssetId: null,
    cardImageAssetId: null,
    heroImageAssetId: null,
    accentColor: '#246B62',
    experienceConfiguration: <String, Object?>{
      'experienceSchemaVersion': 2,
      'workflowGrammarVersion': 1,
      'tagline': 'AuthZ.P6 entry gate fixture',
      'personas': personas,
      'workflowDefinitions': _entryWorkflowDefinitions,
      'workflowInstances': <Object?>[
        <String, Object?>{
          'instanceId': 'entry-content-1',
          'workflowType': 'entry-content',
          'currentState': 'ready',
          'instanceData': <String, Object?>{'title': 'Community content'},
        },
      ],
    },
  );
}

LocalInstalledCommunity _legacyCommunity() {
  return const LocalInstalledCommunity(
    communityId: 'authz-p6-legacy',
    displayName: 'Legacy community',
    extensionId: 'authz-p6-legacy-extension',
    logoAssetId: null,
    cardImageAssetId: null,
    heroImageAssetId: null,
    accentColor: '#246B62',
    experienceConfiguration: <String, Object?>{
      'workflows': <Object?>[
        <String, Object?>{
          'workflowId': 'legacy-content',
          'title': 'Legacy content',
          'entryText': 'Legacy content is available.',
          'actionText': 'Open legacy content.',
          'resultText': 'Legacy content opened.',
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

void main() {
  testWidgets(
    'open-only community gates entry, then renders content after signup',
    (tester) async {
      await tester.pumpWidget(
        _host(
          _engineCommunity(
            communityId: 'open',
            displayName: 'Open community',
            personas: [_openPersona],
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

      await tester.enterText(
        find.byKey(const ValueKey('open-signup-display-name')),
        'Open User',
      );
      await tester.tap(find.byKey(const ValueKey('open-signup-submit')));
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
            personas: [_approvalPersona],
          ),
        ),
      );
      await _settle(tester);

      await tester.enterText(
        find.byKey(const ValueKey('open-signup-display-name')),
        'Waiting User',
      );
      await tester.tap(find.byKey(const ValueKey('open-signup-submit')));
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
            personas: [_invitePersona],
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
        find.byKey(const ValueKey('invite-redeem-persona-dropdown')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('opened-community-invite')),
        findsNothing,
      );
    },
  );

  testWidgets('legacy-schema community still renders without the entry gate', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_legacyCommunity()));
    await _settle(tester);

    expect(find.byKey(const ValueKey('community-entry-gate')), findsNothing);
    expect(
      find.byKey(const ValueKey('local-extension-authz-p6-legacy-extension')),
      findsOneWidget,
    );
  });
}
