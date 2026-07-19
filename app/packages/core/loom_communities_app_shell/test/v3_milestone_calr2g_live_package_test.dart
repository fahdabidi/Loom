import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

const _extensionId = 'ext_verify_tabletop_club';

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(
      '${directory.path}/.codex-logs/'
      '$_extensionId.loom-init.zip',
    ).existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Could not find the generated Tabletop package.');
}

void main() {
  test(
    'generated Tabletop package installs with CALR RSVP response rows',
    () async {
      final root = _repositoryRoot();
      final packageDirectory = '${root.path}/.codex-logs';
      final backend = LocalInAppBackend();
      final result = backend.installLocalPackagePairFromFiles(
        extensionPackagePath:
            '$packageDirectory/$_extensionId.loom-extension.zip',
        initializationPackagePath:
            '$packageDirectory/$_extensionId.loom-init.zip',
      );
      final community = result.community;

      expect(community.extensionId, _extensionId);

      experienceForExtensionId(
        community.extensionId,
        displayName: community.displayName,
        experienceConfiguration: community.experienceConfiguration,
      );

      final engine =
          (await workflowEngineForExtensionId(community.extensionId))
              as LocalWorkflowEngineApi;
      final accounts = await LocalAuthApi().listAccounts(
        communityExtensionId: _extensionId,
      );
      for (final account in accounts) {
        engine.setPersonaType(account.accountId, account.personaTypeId);
      }

      final instances = await engine.queryInstances(
        tabId: 'calendar',
        personaId: 'tabletop-member-14',
        limit: 100,
      );
      final event = instances.items.singleWhere(
        (instance) => instance.instanceId == 'event-friday-game-night',
      );
      final responses = event.instanceData['responses'] as List<dynamic>;
      final responseCounts =
          event.instanceData['responseCounts'] as Map<String, dynamic>;
      final memberResponse = instances.items.singleWhere(
        (instance) => instance.instanceId == 'resp-friday-member-14',
      );

      expect(responses, isNotEmpty);
      expect(responseCounts['going'], 11);
      expect(event.instanceData, isNot(contains('goingPersonaIds')));
      expect(event.instanceData, isNot(contains('maybePersonaIds')));
      expect(memberResponse.workflowType, 'event-rsvp-response');

      final transitions = await engine.availableTransitionsAsync(
        workflowType: memberResponse.workflowType,
        instanceId: memberResponse.instanceId,
        currentState: memberResponse.currentState,
        instanceData: memberResponse.instanceData,
        personaId: 'tabletop-member-14',
      );
      expect(
        transitions.map((transition) => transition.id),
        contains('respond-going'),
      );
    },
  );
}
