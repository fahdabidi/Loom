import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets(
    'CJM.18 resolves a community B role after community A was active',
    (tester) async {
      final communityA = _writeHydratedCommunity(
        extensionId: 'ext_cjm18_community_a',
        communityId: 'community_cjm18_a',
        displayName: 'CJM.18 Community A',
        roleId: 'community-a-role',
      );
      final communityB = _writeHydratedCommunity(
        extensionId: 'ext_cjm18_community_b',
        communityId: 'community_cjm18_b',
        displayName: 'CJM.18 Community B',
        roleId: 'community-b-role',
      );

      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installCommunity(tester, communityA.package);
      final authApiA = await _openCommunity(
        tester,
        extensionId: communityA.extensionId,
        communityId: communityA.communityId,
      );
      await _returnToCommunityList(tester);
      await _installCommunity(tester, communityB.package);

      final result = await authApiA.signUp(
        communityExtensionId: communityB.extensionId,
        displayName: 'Community B member',
        roleId: 'community-b-role',
      );

      expect(result.account.roleId, 'community-b-role');
    },
  );

  testWidgets(
    'CJM.18 invalidates a cached resolver when a community is re-hydrated',
    (tester) async {
      const extensionId = 'ext_cjm18_rehydrated_community';
      const communityId = 'community_cjm18_rehydrated';
      final unhydratedCommunity = _writeUnhydratedCommunity(
        extensionId: extensionId,
        communityId: communityId,
        displayName: 'CJM.18 Rehydrated Community',
      );
      final hydratedCommunity = _writeHydratedCommunity(
        extensionId: extensionId,
        communityId: communityId,
        displayName: 'CJM.18 Rehydrated Community',
        roleId: 'rehydrated-role',
      );

      addTearDown(
        () => unhydratedCommunity.directory.deleteSync(recursive: true),
      );
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installCommunity(tester, unhydratedCommunity.package);
      await _openCommunity(
        tester,
        extensionId: extensionId,
        communityId: communityId,
      );
      await _returnToCommunityList(tester);
      await _installCommunity(tester, hydratedCommunity.package);
      final rehydratedAuthApi = await _openCommunity(
        tester,
        extensionId: extensionId,
        communityId: communityId,
      );

      final result = await rehydratedAuthApi.signUp(
        communityExtensionId: extensionId,
        displayName: 'Rehydrated member',
        roleId: 'rehydrated-role',
      );

      expect(result.account.roleId, 'rehydrated-role');
    },
  );
}

class _UnhydratedCommunity {
  const _UnhydratedCommunity({required this.package, required this.directory});

  final EvidencePackagePair package;
  final Directory directory;
}

class _HydratedCommunity {
  const _HydratedCommunity({
    required this.package,
    required this.extensionId,
    required this.communityId,
  });

  final EvidencePackagePair package;
  final String extensionId;
  final String communityId;
}

_HydratedCommunity _writeHydratedCommunity({
  required String extensionId,
  required String communityId,
  required String displayName,
  required String roleId,
}) {
  final workflowId = '$extensionId-status';
  final definition = engineNativeTestWorkflowDefinition(
    initialState: 'open',
    states: <String, Object?>{
      'open': <String, Object?>{'label': 'Open'},
      'complete': <String, Object?>{'label': 'Complete', 'isTerminal': true},
    },
    transitions: <Map<String, Object?>>[
      <String, Object?>{
        'id': 'complete',
        'label': 'Complete',
        'from': <String>['open'],
        'to': 'complete',
        'guard': <String, Object?>{
          'allowedRoleIds': <String>[roleId],
        },
      },
    ],
    renderBindings: <Map<String, Object?>>[
      engineNativeTestRenderBinding(
        states: const <String>['open', 'complete'],
        tabId: 'home',
        cardSurfaceFamily: 'statusTimeline',
      ),
    ],
    instanceDataSchema: const <String, Object?>{
      'title': <String, Object?>{'type': 'text', 'storage': 'inline'},
    },
  );
  final package = writeEngineNativeTestPackagePair(
    tempDirectoryPrefix: 'loom_cjm18_${communityId}_',
    extensionId: extensionId,
    communityId: communityId,
    displayName: displayName,
    experience: <String, Object?>{
      'displayName': displayName,
      'roles': <Map<String, Object?>>[
        <String, Object?>{
          'roleId': roleId,
          'label': roleId,
          'roleLabel': 'Member',
          'description': 'CJM.18 cache regression role.',
        },
      ],
      'workflowDefinitions': <String, Object?>{workflowId: definition},
      'workflowInstances': <Map<String, Object?>>[
        engineNativeTestWorkflowInstance(
          instanceId: '$workflowId-instance',
          workflowType: workflowId,
          currentState: 'open',
          createdByFanId: roleId,
          instanceData: const <String, Object?>{'title': 'CJM.18 fixture'},
        ),
      ],
    },
  );
  return _HydratedCommunity(
    package: package,
    extensionId: extensionId,
    communityId: communityId,
  );
}

_UnhydratedCommunity _writeUnhydratedCommunity({
  required String extensionId,
  required String communityId,
  required String displayName,
}) {
  final directory = Directory.systemTemp.createTempSync(
    'loom_cjm18_unhydrated_',
  );
  final extension = File('${directory.path}/$extensionId.loom-extension.zip');
  final initialization = File('${directory.path}/$extensionId.loom-init.zip');
  extension.writeAsStringSync(
    jsonEncode(<String, Object?>{
      'specVersion': currentCommunitySpecVersion,
      'mode': 'local-demo',
      'extensionId': extensionId,
      'displayName': displayName,
      'version': '1.0.0',
      'permissions': <String>['content.publish'],
    }),
  );
  initialization.writeAsStringSync(
    jsonEncode(<String, Object?>{
      'specVersion': currentCommunitySpecVersion,
      'communityId': communityId,
      'communityName': displayName,
      'extensionId': extensionId,
      'seedDataFiles': <String>['seed/community.json'],
    }),
  );
  return _UnhydratedCommunity(
    package: EvidencePackagePair(
      extensionPath: extension.path,
      initializationPath: initialization.path,
    ),
    directory: directory,
  );
}

Future<void> _installCommunity(
  WidgetTester tester,
  EvidencePackagePair package,
) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    package.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    package.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
}

Future<LocalAuthApi> _openCommunity(
  WidgetTester tester, {
  required String extensionId,
  required String communityId,
}) async {
  await tester.tap(find.byKey(ValueKey('community-card-$communityId')));
  await tester.pumpAndSettle();
  final screen = tester.widget<LocalExtensionScreen>(
    find.byWidgetPredicate(
      (widget) =>
          widget is LocalExtensionScreen &&
          widget.community.extensionId == extensionId,
    ),
  );
  expect(screen.authApi, isA<LocalAuthApi>());
  return screen.authApi! as LocalAuthApi;
}

Future<void> _returnToCommunityList(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(LocalExtensionScreen))).pop();
  await tester.pumpAndSettle();
}
