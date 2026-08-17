import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

final class _FakeWorkflowEngineApi implements WorkflowEngineApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(resetEngineNativeCommunityEngineFactoryForTesting);

  test('non-Local factory engine skips Local-only setup', () async {
    const expectedExtensionId = 'engine-native-factory-non-local-test';
    final fake = _FakeWorkflowEngineApi();
    var factoryCalls = 0;
    overrideEngineNativeCommunityEngineFactoryForTesting(({
      required WorkflowDatabase database,
      required String extensionId,
    }) {
      factoryCalls += 1;
      expect(database, isA<WorkflowDatabase>());
      expect(extensionId, expectedExtensionId);
      return fake;
    });

    experienceForExtensionId(
      expectedExtensionId,
      experienceConfiguration: const <String, Object?>{
        'experienceSchemaVersion': 2,
        'workflowGrammarVersion': 1,
        'workflowDefinitions': <String, Object?>{
          'seam-workflow': <String, Object?>{
            'initialState': 'open',
            'states': <String, Object?>{
              'open': <String, Object?>{'label': 'Open'},
            },
            'transitions': <Object?>[],
          },
        },
        'workflowInstances': <Object?>[
          <String, Object?>{
            'instanceId': 'seam-seed',
            'workflowType': 'seam-workflow',
            'currentState': 'open',
            'instanceData': <String, Object?>{},
            'createdByPersonaId': 'member',
          },
        ],
      },
    );
    configureEngineAuthorizationForExtensionId(
      extensionId: expectedExtensionId,
      appShellConfiguration: const <String, Object?>{},
      activeMembershipLookup: (_) async => true,
    );

    final engine = await workflowEngineForExtensionId(expectedExtensionId);

    expect(engine, same(fake));
    expect(factoryCalls, 1);
  });
}
