import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';
import 'package:loom_ux_judges/src/validator/community_package_validator.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

import '../tool/generate_tabletop_club_package.dart';

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  test(
    'generated Tabletop package installs with CALR RSVP response rows',
    () async {
      final root = findTabletopClubRepositoryRoot();
      final packageDirectory = await Directory.systemTemp.createTemp(
        'loom-calr2g-',
      );
      try {
        final generated = await generateTabletopClubPackagePair(
          outputDirectory: packageDirectory,
          repositoryRoot: root,
        );
        final extensionPackage =
            jsonDecode(await generated.extensionPackage.readAsString())
                as Map<String, dynamic>;
        final initializationPackage =
            jsonDecode(await generated.initializationPackage.readAsString())
                as Map<String, dynamic>;
        expect(extensionPackage['specVersion'], currentCommunitySpecVersion);
        expect(extensionPackage, isNot(contains('schemaVersion')));
        expect(
          initializationPackage['specVersion'],
          currentCommunitySpecVersion,
        );
        expect(initializationPackage, isNot(contains('schemaVersion')));
        final validation = CommunityPackageValidator().validate(
          initializationPackage,
        );
        expect(
          validation.errors,
          isEmpty,
          reason: validation.errors.join('\n'),
        );
        final backend = LocalInAppBackend();
        final result = backend.installLocalPackagePairFromFiles(
          extensionPackagePath: generated.extensionPackage.path,
          initializationPackagePath: generated.initializationPackage.path,
        );
        final community = result.community;

        expect(community.extensionId, _extensionId);

        experienceForExtensionId(
          community.extensionId,
          displayName: community.displayName,
          specVersion: community.specVersion,
          experienceConfiguration: community.experienceConfiguration,
        );

        final engine =
            (await workflowEngineForExtensionId(community.extensionId))
                as LocalWorkflowEngineApi;
        final accounts = await LocalAuthApi().listAccounts(
          communityExtensionId: _extensionId,
        );
        configureEngineAuthorizationForExtensionId(
          extensionId: community.extensionId,
          appShellConfiguration: community.appShellConfiguration,
          activeMembershipLookup: (fanId) async => accounts.any(
            (account) =>
                account.accountId == fanId &&
                account.status == MembershipStatus.active,
          ),
        );
        for (final account in accounts) {
          engine.setRoleForFan(account.accountId, account.roleId);
        }

        final instances = await engine.queryInstances(
          tabId: 'calendar',
          fanId: 'tabletop-member-14',
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
        expect(
          event.instanceData,
          isNot(
            contains(
              'goingPer'
              'sonaIds',
            ),
          ),
        );
        expect(
          event.instanceData,
          isNot(
            contains(
              'maybePer'
              'sonaIds',
            ),
          ),
        );
        expect(memberResponse.workflowType, 'event-rsvp-response');

        final transitions = await engine.availableTransitionsAsync(
          workflowType: memberResponse.workflowType,
          instanceId: memberResponse.instanceId,
          currentState: memberResponse.currentState,
          instanceData: memberResponse.instanceData,
          fanId: 'tabletop-member-14',
        );
        expect(
          transitions.map((transition) => transition.id),
          contains('respond-going'),
        );
      } finally {
        await packageDirectory.delete(recursive: true);
      }
    },
  );
}
